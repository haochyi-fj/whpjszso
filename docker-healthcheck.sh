#!/bin/sh
# 小白搜盘容器健康检查：经网关访问后端 /api/health，验证整条链路
set -eu

APP_PORT="${APP_PORT:-12668}"

curl -sf --max-time 8 "http://127.0.0.1:${APP_PORT}/api/health" >/dev/null 2>&1 || exit 1
exit 0
