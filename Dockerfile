# ============================================================
# 小白搜盘 (fn-seekbox) Docker 镜像
#
# 架构: linux/amd64（x86-64）
#   后端 app/bin/seekbox 为 amd64 静态链接二进制，暂不支持 ARM。
#   在 ARM 主机上构建/运行请使用 --platform linux/amd64（仍需模拟器，且性能受限）。
#
# 运行时组成:
#   - app/bin/seekbox     Go 搜索后端（静态链接，监听 127.0.0.1:18888）
#   - app/bin/gateway.py  Python 网关（纯标准库，对外端口 + 静态页 + API 反代）
#   - app/web/            前端构建产物（Vue 3）
# ============================================================

FROM python:3.12-alpine

# 运行时依赖:
#   ca-certificates  HTTPS 出站请求
#   tzdata           时区数据
#   curl             健康检查
#   bash             启动脚本（wait -n 信号收尾）
RUN apk add --no-cache ca-certificates tzdata curl bash

# 默认时区（东八区）
ENV TZ=Asia/Shanghai

WORKDIR /app

# ---- 复制运行文件 ----
COPY app/bin/seekbox /app/bin/seekbox
COPY app/bin/gateway.py /app/bin/gateway.py
COPY app/web /app/web

RUN chmod +x /app/bin/seekbox /app/bin/gateway.py

# ---- 数据目录（缓存 + 日志，挂载卷 /app/data 持久化）----
ENV CACHE_PATH=/app/data/cache
ENV LOG_PATH=/app/data/logs
RUN mkdir -p /app/data/cache /app/data/logs/backend

# ---- 环境变量默认值（与 cmd/main 保持一致）----
ENV APP_PORT=12668 \
    BACKEND_HOST=127.0.0.1 \
    BACKEND_PORT=18888 \
    ENABLED_PLUGINS=dyyjpro,duoduo,feikuai,gaoqing888,gying,hunhepan,ikantv,jutoushe,kkv,lingjisp,lou1,melost,ouge,panlian,qqpd,quark4k,quarksoo,quarktv,sousou,thepiratebay,wanou,weibo,xb6v,xiaozhang,yunso,zxzj \
    CACHE_ENABLED=true \
    CACHE_TTL=60 \
    MAX_CONCURRENCY=200 \
    MAX_PAGES=30 \
    ASYNC_PLUGIN_ENABLED=true \
    AUTH_ENABLED=false \
    AUTH_USERS= \
    AUTH_TOKEN_EXPIRY=24 \
    AUTH_JWT_SECRET= \
    PROXY= \
    CHANNELS=-

# ---- 启动与健康检查脚本 ----
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
COPY docker-healthcheck.sh /app/docker-healthcheck.sh
RUN chmod +x /app/docker-entrypoint.sh /app/docker-healthcheck.sh

# 健康检查：经网关访问后端 /api/health，验证整条链路
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD /app/docker-healthcheck.sh

# 对外端口（Web 访问）
EXPOSE 12668

# 数据卷（缓存 + 日志）
VOLUME ["/app/data"]

ENTRYPOINT ["/app/docker-entrypoint.sh"]
