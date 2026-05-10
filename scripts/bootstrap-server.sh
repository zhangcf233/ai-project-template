#!/usr/bin/env bash
set -euo pipefail

# 兼容任务要求的脚本路径，实际逻辑统一在 deploy/ 下维护。
exec bash deploy/bootstrap_server.sh "$@"
