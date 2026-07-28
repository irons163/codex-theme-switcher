# Codex Theme Switcher 0.2.9-beta.2

## 更可靠的 Codex 连接

- 默认 bridge port 被占用时，自动选择下一个可用的 loopback port，避免 Theme Switcher 因此无法与 Codex 通信。
- 按各 Theme Switcher 数据目录保存选定的 bridge port，让后续命令能够稳定地重新连接。
- 明确指定的 port 仍采用严格模式：发生冲突时会报告错误，不会静默改用其他 port。
- 增加 bridge port 回归测试，并在七种语言的 README 中加入新的主题宣传图。
