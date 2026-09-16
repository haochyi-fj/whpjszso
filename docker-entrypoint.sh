#!/usr/bin/env bash
# ============================================================
# 小白搜盘 Docker 启动脚本
#
# 流程:
#   1. 归一化环境变量（默认值与 cmd/main 保持一致）
#   2. 启动 Go 后端 seekbox（127.0.0.1:18888）
#   3. 等待后端健康检查通过（最多 30 秒）
#   4. 启动 Python 网关 gateway.py（0.0.0.0:${APP_PORT}）
#   5. 前台驻留，任一进程退出或收到信号时收尾另一个
# ============================================================
set -euo pipefail

# ---------- 1. 环境变量归一化 ----------
APP_PORT="${APP_PORT:-12668}"
BACKEND_HOST="${BACKEND_HOST:-127.0.0.1}"
BACKEND_PORT="${BACKEND_PORT:-18888}"
DEFAULT_PLUGINS="dyyjpro,duoduo,feikuai,gaoqing888,gying,hunhepan,ikantv,jutoushe,kkv,lingjisp,lou1,melost,ouge,panlian,qqpd,quark4k,quarksoo,quarktv,sousou,thepiratebay,wanou,weibo,xb6v,xiaozhang,yunso,zxzj"

export ENABLED_PLUGINS="${ENABLED_PLUGINS:-$DEFAULT_PLUGINS}"
export PORT="${BACKEND_PORT}"
export BACKEND_HOST BACKEND_PORT APP_PORT
export PANSOU_HOST="${BACKEND_HOST}" PANSOU_PORT="${BACKEND_PORT}"
export CACHE_PATH="${CACHE_PATH:-/app/data/cache}"
export LOG_PATH="${LOG_PATH:-/app/data/logs}"
export CACHE_ENABLED="${CACHE_ENABLED:-true}"
export CACHE_TTL="${CACHE_TTL:-60}"
export MAX_CONCURRENCY="${MAX_CONCURRENCY:-200}"
export MAX_PAGES="${MAX_PAGES:-30}"
export ASYNC_PLUGIN_ENABLED="${ASYNC_PLUGIN_ENABLED:-true}"
export AUTH_ENABLED="${AUTH_ENABLED:-false}"
export AUTH_USERS="${AUTH_USERS:-}"
export AUTH_TOKEN_EXPIRY="${AUTH_TOKEN_EXPIRY:-24}"
export AUTH_JWT_SECRET="${AUTH_JWT_SECRET:-}"
export PROXY="${PROXY:-}"
export TZ="${TZ:-Asia/Shanghai}"
export WEBROOT=/app/web
export GATEWAY_HOST=0.0.0.0
# 后端空 CHANNELS 会回落到内置 TG 频道；占位即可，搜索由网关强制 src=plugin
export CHANNELS="${CHANNELS:--}"

mkdir -p "${CACHE_PATH}" "${LOG_PATH}/backend"

echo "[entrypoint] ENABLED_PLUGINS=${ENABLED_PLUGINS}"
echo "[entrypoint] PROXY=${PROXY:-<未设置>}"
echo "[entrypoint] AUTH_ENABLED=${AUTH_ENABLED}"

# ---------- 2. 启动后端 ----------
echo "[entrypoint] starting seekbox backend on ${BACKEND_HOST}:${BACKEND_PORT}"
cd /app/data
/app/bin/seekbox >> "${LOG_PATH}/backend/seekbox.log" 2>&1 &
BACKEND_PID=$!

# ---------- 3. 等待后端就绪 ----------
backend_ready=0
for i in $(seq 1 30); do
    if curl -sf --max-time 2 "http://${BACKEND_HOST}:${BACKEND_PORT}/api/health" >/dev/null 2>&1; then
        backend_ready=1
        break
    fi
    sleep 1
done

if [ "${backend_ready}" != "1" ]; then
    echo "[entrypoint] ERROR: seekbox backend 30s 内未就绪，最近日志:" >&2
    tail -50 "${LOG_PATH}/backend/seekbox.log" >&2 || true
    kill -TERM "${BACKEND_PID}" 2>/dev/null || true
    exit 1
fi
echo "[entrypoint] seekbox backend healthy"

# ---------- 4. 启动网关 ----------
echo "[entrypoint] starting gateway on 0.0.0.0:${APP_PORT}"
/app/bin/gateway.py >> "${LOG_PATH}/gateway.log" 2>&1 &
GATEWAY_PID=$!

sleep 1
if ! kill -0 "${GATEWAY_PID}" 2>/dev/null; then
    echo "[entrypoint] ERROR: gateway 启动失败，最近日志:" >&2
    tail -50 "${LOG_PATH}/gateway.log" >&2 || true
    kill -TERM "${BACKEND_PID}" 2>/dev/null || true
    exit 1
fi
echo "[entrypoint] fn-seekbox ready on http://0.0.0.0:${APP_PORT}"

# ---------- 5. 前台驻留 + 信号/进程收尾 ----------
cleanup() {
    echo "[entrypoint] stopping..."
    kill -TERM "${BACKEND_PID}" "${GATEWAY_PID}" 2>/dev/null || true
    wait "${BACKEND_PID}" 2>/dev/null || true
    wait "${GATEWAY_PID}" 2>/dev/null || true
    echo "[entrypoint] stopped"
    exit 0
}
trap cleanup TERM INT

# 任一进程退出则收尾另一个，并以退出码结束容器
set +e
wait -n "${BACKEND_PID}" "${GATEWAY_PID}"
EXIT_CODE=$?
set -e
echo "[entrypoint] 子进程退出 (code=${EXIT_CODE})，正在停止另一个..."
kill -TERM "${BACKEND_PID}" "${GATEWAY_PID}" 2>/dev/null || true
wait "${BACKEND_PID}" 2>/dev/null || true
wait "${GATEWAY_PID}" 2>/dev/null || true
exit "${EXIT_CODE}"
