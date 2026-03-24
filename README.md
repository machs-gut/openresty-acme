# openresty-acme

基于 `OpenResty + nginx-acme`，内置默认 `nginx` 配置。

## 项目说明

- 集成 `nginx-acme` 模块，支持自动申请、续期证书，配置示例见 `conf.d/demo.com.conf.example`。
- 镜像内默认包含 `nginx.conf` 与 `conf.d/` 配置，可直接运行。
- 默认生成占位自签证书，避免首次启动因证书文件缺失失败。
- 支持 SNI 分流域名转发，实现 443 端口转发到特定服务，配置示例见 conf.d/443-preread.stream
- 配置兜底站点返回444，拦截通过 IP 或未知域名直连的请求，避免默认路由误命中到其他业务站点

## 目录结构

- `Dockerfile`：镜像构建定义。
- `docker-compose.yml`：本地/单机部署示例。
- `nginx.conf`：主配置。
- `conf.d/http.stream`：`stream` 透传配置（443 -> 8443）。
- `conf.d/99-default.conf`：默认兜底站点配置。

## 本地构建与运行

### 1) 构建镜像

```bash
docker build -t machsgut/openresty-acme:latest .
```

### 2) 直接运行

```bash
docker run -d --name openresty-acme \
  -p 80:80 -p 443:443 -p 127.0.0.1:8443:8443 \
  machsgut/openresty-acme:latest
```


## 使用 Docker Compose

```bash
# 拉取代码
cd /opt && git clone https://github.com/machsgut/openresty-acme.git && cd openresty-acme

# 创建持久化目录
mkdir -p /opt/openresty-acme/{ssl,logs,conf.d}

# 生成自签证书
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout ssl/selfsigned.key \
  -out ssl/selfsigned.crt \
  -subj "/CN=localhost"

# 构建并启动
docker compose up -d --build
```

## 日志查看

- 容器日志：`docker logs -f openresty-acme`
- 文件日志（宿主机）：`./logs/access.log`、`./logs/error.log`
