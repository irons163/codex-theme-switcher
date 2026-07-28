# Codex Theme Switcher 0.2.9-beta.2

## 更可靠的 Codex 連線

- 預設 bridge port 被占用時，自動選擇下一個可用的 loopback port，避免 Theme Switcher 因此無法與 Codex 通訊。
- 依各 Theme Switcher 資料目錄保存選定的 bridge port，讓後續命令能穩定重新連線。
- 明確指定的 port 仍採嚴格模式：發生衝突時會回報錯誤，不會靜默改用其他 port。
- 增加 bridge port 回歸測試，並在七語 README 加入新的主題宣傳圖。
