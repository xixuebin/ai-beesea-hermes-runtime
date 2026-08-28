#!/usr/bin/env bash
# 对已组装目录做离线启动验证，防止把仅在 CI 路径可执行的 Runtime 发布出去。
set -euo pipefail

runtime_dir="${1:?请提供 Runtime 目录}"
test -f "${runtime_dir}/runtime-manifest.json"
test -x "${runtime_dir}/python/venv/bin/hermes"
test -x "${runtime_dir}/node/bin/node"

"${runtime_dir}/python/venv/bin/hermes" --help >/dev/null
"${runtime_dir}/node/bin/node" --version >/dev/null

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
