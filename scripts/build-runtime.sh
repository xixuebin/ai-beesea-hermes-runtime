#!/usr/bin/env bash
# 构建可解压运行的 macOS ARM64 Hermes Runtime；不依赖目标机器上的 Python、Node 或 uv。
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
source_dir="${root}/upstream/hermes-agent"
output_dir="${root}/dist/runtime"
python_version="3.11"
hermes_ref="${HERMES_REF:-v2026.8.27}"

test -f "${source_dir}/pyproject.toml"
test "$(uname -m)" = "arm64"
if test -e "${output_dir}"; then
  echo "构建目录已存在：${output_dir}；请使用干净的工作目录重新构建" >&2
  exit 1
fi
mkdir -p "${output_dir}/python/site-packages" "${output_dir}/python/venv/bin" "${output_dir}/node"

# 使用 uv 的受管 CPython，并复制其完整前缀。该发行版可由 PythonHOME 相对定位，避免 venv 中
# 绝对路径的解释器链接在用户安装目录变化后失效。
uv python install "${python_version}"
python_bin="$(uv python find "${python_version}")"
python_root="$(cd "$(dirname "${python_bin}")/.." && pwd)"
cp -R "${python_root}/." "${output_dir}/python/cpython/"

# 由上游 uv.lock 锁定依赖；项目自身使用 --no-deps 安装，确保没有在构建时重新解析版本。
uv export --directory "${source_dir}" --frozen --no-dev --no-emit-project --format requirements-txt -o "${root}/dist/requirements.txt"
uv pip install --python "${python_bin}" --target "${output_dir}/python/site-packages" -r "${root}/dist/requirements.txt"
uv pip install --python "${python_bin}" --target "${output_dir}/python/site-packages" --no-deps "${source_dir}"
rm "${root}/dist/requirements.txt"

# Hermes 的部分工具需要 Node。复制 Actions 安装的完整 Node 前缀，不使用宿主机 PATH。
node_bin="$(command -v node)"
node_root="$(cd "$(dirname "${node_bin}")/.." && pwd)"
cp -R "${node_root}/." "${output_dir}/node/"

cat > "${output_dir}/python/venv/bin/hermes" <<'EOF'
#!/usr/bin/env bash
# 入口位置与 BeeSea Desktop 的 Runtime 约定一致。所有路径由本脚本位置推导，支持移动安装。
set -euo pipefail
runtime_root="$(cd "$(dirname "$0")/../../.." && pwd)"
export PYTHONHOME="${runtime_root}/python/cpython"
export PYTHONPATH="${runtime_root}/python/site-packages${PYTHONPATH:+:${PYTHONPATH}}"
export PATH="${runtime_root}/node/bin:${PATH}"
exec "${runtime_root}/python/cpython/bin/python3" -m hermes_cli.main "$@"
EOF
chmod 0755 "${output_dir}/python/venv/bin/hermes"

hermes_version="$(sed -nE 's/^version = "([^"]+)"/\1/p' "${source_dir}/pyproject.toml" | head -1)"
test -n "${hermes_version}"
source_commit="$(git -C "${source_dir}" rev-parse HEAD)"
node_version="$("${output_dir}/node/bin/node" --version)"

cat > "${output_dir}/runtime-manifest.json" <<EOF
{
  "schema": 1,
  "platform": "mac-arm64",
  "arch": "arm64",
  "hermesAgentVersion": "${hermes_version}",
  "hermesSource": {
    "repository": "https://github.com/NousResearch/hermes-agent",
    "ref": "${hermes_ref}",
    "commit": "${source_commit}"
  },
  "pythonVersion": "${python_version}",
  "nodeVersion": "${node_version}"
}
EOF
