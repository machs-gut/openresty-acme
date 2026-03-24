FROM alpine:3.21 AS builder

# ===== 构建阶段：编译 OpenResty 并集成 nginx-acme 模块 =====

ARG OPENRESTY_VERSION=1.27.1.2
ARG NGINX_ACME_REF=main
ARG ALPINE_MIRROR=https://dl-cdn.alpinelinux.org/alpine
ARG ALPINE_REPO_VERSION=v3.21

# 配置 Alpine 软件源并安装编译依赖
RUN printf '%s/%s/main\n%s/%s/community\n' \
    "${ALPINE_MIRROR}" "${ALPINE_REPO_VERSION}" \
    "${ALPINE_MIRROR}" "${ALPINE_REPO_VERSION}" \
    > /etc/apk/repositories \
    && apk add --no-cache \
    build-base \
    ca-certificates \
    cargo \
    clang \
    clang-dev \
    curl \
    git \
    linux-headers \
    llvm-dev \
    openssl-dev \
    pcre2-dev \
    perl \
    pkgconf \
    rust \
    zlib-dev

WORKDIR /tmp

# 下载 OpenResty 源码，并拉取 nginx-acme 模块源码
RUN curl -fSL --connect-timeout 20 --retry 3 --retry-delay 2 "https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz" -o openresty.tar.gz \
    && tar -xzf openresty.tar.gz \
    && git clone --depth 1 --branch "${NGINX_ACME_REF}" https://github.com/nginx/nginx-acme.git

WORKDIR /tmp/openresty-${OPENRESTY_VERSION}

# 编译 OpenResty：启用常用模块并静态集成 nginx-acme
RUN ./configure \
    --prefix=/usr/local/openresty \
    --with-cc-opt='-O2 -DNGX_LUA_ABORT_AT_PANIC' \
    --with-ld-opt='-Wl,-rpath,/usr/local/openresty/luajit/lib' \
    --with-pcre-jit \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --without-mail_smtp_module \
    --with-http_stub_status_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_secure_link_module \
    --with-http_random_index_module \
    --with-http_gzip_static_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_slice_module \
    --with-http_gunzip_module \
    --with-threads \
    --with-compat \
    --with-http_ssl_module \
    --add-module=/tmp/nginx-acme \
    && make -j"$(nproc)" \
    && make install

FROM alpine:3.21

# ===== 运行阶段：仅保留运行所需组件，减小镜像体积 =====

ARG ALPINE_MIRROR=https://dl-cdn.alpinelinux.org/alpine
ARG ALPINE_REPO_VERSION=v3.21

# 设置容器时区为上海（与宿主/业务日志时间保持一致）
ENV TZ=Asia/Shanghai
ENV PATH=/usr/local/openresty/bin:/usr/local/openresty/nginx/sbin:${PATH}
# ACME 证书状态目录前缀
ENV NGX_ACME_STATE_PREFIX=/usr/local/openresty/ssl

# 安装运行时依赖并写入时区配置
RUN printf '%s/%s/main\n%s/%s/community\n' \
    "${ALPINE_MIRROR}" "${ALPINE_REPO_VERSION}" \
    "${ALPINE_MIRROR}" "${ALPINE_REPO_VERSION}" \
    > /etc/apk/repositories \
    && apk add --no-cache \
    bash \
    ca-certificates \
    openssl \
    pcre2 \
    zlib \
    libstdc++ \
    tzdata \
    && ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo Asia/Shanghai > /etc/timezone

# 从构建阶段拷贝 OpenResty 安装产物
COPY --from=builder /usr/local/openresty /usr/local/openresty

# 初始化运行目录与证书目录
RUN mkdir -p \
    /usr/local/openresty/nginx/conf \
    /usr/local/openresty/nginx/conf.d \
    /usr/local/openresty/nginx/html \
    /usr/local/openresty/nginx/logs \
    /usr/local/openresty/site/lualib \
    /usr/local/openresty/ssl/acme-letsencrypt

WORKDIR /usr/local/openresty/nginx

# 前台运行，便于容器进程管理
CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]