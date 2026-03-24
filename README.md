# openresty-acme

基于 `OpenResty + nginx-acme` 的容器化NGINX镜像，内置默认 `nginx` 配置，默认时区为 `Asia/Shanghai`。

## 项目说明

- 集成 `nginx-acme` 模块。
- 镜像内默认包含 `nginx.conf` 与 `conf.d/` 配置，可直接运行。
- 默认生成占位自签证书，避免首次启动因证书文件缺失失败。
- 日志同时写入文件和容器标准输出，既可持久化也可 `docker logs` 查看。

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
  -p 80:80 -p 443:443 -p 8443:8443 \
  machsgut/openresty-acme:latest
```


## 使用 Docker Compose

```bash
docker compose up -d --build
docker compose logs -f
```

当前 `docker-compose.yml` 默认：

- 端口：`80`、`443`、`127.0.0.1:8443`
- 时区：`TZ=Asia/Shanghai`
- 挂载：
  - `./ssl/` -> `/usr/local/openresty/ssl/`
  - `./logs/` -> `/usr/local/openresty/nginx/logs`
  - `./nginx.conf` -> `/usr/local/openresty/nginx/conf/nginx.conf:ro`
  - `./conf.d/` -> `/usr/local/openresty/nginx/conf.d/:ro`

## 日志查看

- 容器日志：`docker logs -f openresty-acme`
- 文件日志（宿主机）：`./logs/access.log`、`./logs/error.log`
