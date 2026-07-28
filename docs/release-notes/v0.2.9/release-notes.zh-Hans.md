# Codex Theme Switcher 0.2.9

## 更可靠的 Codex 连接

- 默认 bridge port 被占用时，会自动选择并记住可用的本地 port。
- 会从正在运行的 App、macOS Launch Services 与常见安装位置自动查找 Codex。
- 新增 Codex App 位置设置，可选择已改名、移动或存放在外接磁盘的 Codex，也可恢复自动检测。
- Agent CLI 新增 `--codex-app <path>`，让 AI agent 与自动化流程能够指定 Codex 安装位置。
- 提供 Apple Silicon 与 Intel Mac 安装包，均已完成签名与 Apple 公证。
