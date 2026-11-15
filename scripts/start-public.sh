#!/bin/bash
# God's Eye View —— 对外公开站点启动脚本（本机 4190，经 cloudflared 暴露为 gev.one1.kdns.fr）
# 只跑 keyless：任何 Provider 密钥都不要写进 .env / 本脚本，公网访客共享这个进程。
set -euo pipefail
export PATH=/opt/homebrew/opt/node@24/bin:$PATH
export NODE_ENV=development
export HOST=127.0.0.1
export PORT=4190
export GEV_ALLOWED_HOSTS=gev.one1.kdns.fr
export PUPPETEER_SKIP_DOWNLOAD=1
cd /Users/leo/Desktop/leohermes/gods-eye-view
exec npm run dev
