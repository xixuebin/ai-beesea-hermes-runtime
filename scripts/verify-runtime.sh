#!/usr/bin/env bash
# 对已组装目录做离线启动验证，防止把仅在 CI 路径可执行的 Runtime 发布出去。
set -euo pipefail

runtime_dir="${1:?请提供 Runtime 目录}"
test -f "${runtime_dir}/runtime-manifest.json"
test -x "${runtime_dir}/python/venv/bin/hermes"
test -x "${runtime_dir}/node/bin/node"

"${runtime_dir}/python/venv/bin/hermes" --help >/dev/null
"${runtime_dir}/node/bin/node" --version >/dev/null
# ACP 是 Desktop 唯一的 Hermes 执行通道。单独验证该 optional extra，避免把
# “CLI 可启动、ACP 首次会话即退出”的不完整 Runtime 发布给用户。
PYTHONHOME="${runtime_dir}/python/cpython" PYTHONPATH="${runtime_dir}/app:${runtime_dir}/python/site-packages" \
  "${runtime_dir}/python/cpython/bin/python3" -c 'import acp; from acp_adapter.server import HermesACPAgent'

python3 - "${runtime_dir}/runtime-manifest.json" <<'PY'
import json
import sys

manifest = json.load(open(sys.argv[1], encoding="utf-8"))
assert manifest["platform"] == "mac-arm64"
assert manifest["arch"] == "arm64"
assert manifest["hermesAgentVersion"]
assert manifest["hermesSource"]["commit"] == "5fc308a70719a83cccdbba4c0e39c23f5a8239d5"
PY

echo "Hermes Runtime 验证通过"
