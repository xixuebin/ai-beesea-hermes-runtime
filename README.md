# BeeSea Hermes Runtime

此仓库构建供 BeeSea Desktop 使用的 Hermes Runtime 发布包，目前目标为 **macOS Apple Silicon (`darwin-arm64`)**。

## 固定上游版本

- Hermes Agent 标签：`v2026.8.27`
- Hermes Agent commit：`5fc308a70719a83cccdbba4c0e39c23f5a8239d5`
- Hermes 包版本：`0.20.6`

流水线会同时校验标签解析的提交；任何漂移都会失败，不能误发布未审查的上游代码。

## 发布内容

压缩包根目录为 `runtime/`，其中包含：

- `runtime-manifest.json`：BeeSea Desktop 校验的 Runtime 元数据。
- `python/venv/bin/hermes`：Desktop 调用的 Hermes 入口。
- `python/cpython` 与 `python/site-packages`：内置 Python 与锁定的 Hermes 依赖。
- `node`：Hermes 浏览器等工具所需的内置 Node 26。
- `agent-client-protocol`：BeeSea Desktop 发起 Agent 会话所需的 Hermes ACP 依赖。

每个 zip 都会发布同名 `.sha256` 文件。构建验证会同时导入 ACP 适配器，防止发布缺少 ACP optional extra、只能检测到 Runtime 而无法执行会话的包。当前未做代码签名或公证，下载端应先校验 SHA-256。

## 构建与发布

工作流只支持手动触发或推送 `runtime-v*` 标签：

1. 在 GitHub Actions 页面选择 **Build Hermes Runtime**。
2. 默认 `publish=false`，仅构建、离线验证并上传 Actions Artifact。
3. 人工确认 Artifact 可用后，再以 `publish=true` 手动触发，或推送 `runtime-v*` 标签，才会创建 GitHub Release。

这让构建验证和对外发布分离，避免未验证产物自动暴露给应用用户。
