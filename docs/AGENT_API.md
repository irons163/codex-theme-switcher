# AI Agent API

`codex-theme` 是 Codex Theme Switcher 給 AI agent、script 與未來 MCP wrapper 使用的
JSON-first 介面。它直接重用 app 的 `ThemeDocument`、validator、compiler、repository
與 runtime，不另造一套格式。

開發環境：

```sh
swift run codex-theme capabilities
```

封裝後：

```sh
"/Applications/CodexThemeSwitcher.app/Contents/Helpers/codex-theme" capabilities
```

每個命令成功時在 stdout 輸出一個 JSON envelope；失敗時在 stderr 輸出相同結構並以
非零狀態結束：

```json
{
  "protocolVersion": 1,
  "command": "validate",
  "ok": true,
  "data": {}
}
```

失敗 envelope 的 `ok` 為 `false`，`error.code` 是穩定、供程式判斷的識別碼；
`message` 僅供人閱讀，`details` 與 `data` 依錯誤提供額外狀態：

```json
{
  "protocolVersion": 1,
  "command": "validate",
  "ok": false,
  "error": {
    "code": "validation_failed",
    "message": "Theme validation failed with 1 error(s).",
    "details": {}
  },
  "data": {
    "valid": false,
    "validation": {
      "issues": [
        {
          "severity": "error",
          "code": "emptyThemeName",
          "path": "metadata.name",
          "message": "A theme name is required."
        }
      ]
    }
  }
}
```

退出碼：

| 狀態 | 意義 |
| --- | --- |
| `0` | 成功；JSON 位於 stdout |
| `1` | 未分類的內部／作業失敗 |
| `2` | 命令、選項、必要參數或操作授權錯誤 |
| `3` | 輸入、檔案、archive、查詢或 preview 錯誤 |
| `4` | Theme validation 或 compilation 失敗 |
| `5` | Runtime、Codex/CDP、helper 或 Node 失敗 |
| `6` | Repository 衝突、禁止的變更或 active pointer 同步失敗 |

Agent 應先判斷 process exit code，再解析對應 stream 的 JSON，並以
`error.code` 分支，不應比對英文 `message`。`apply`／`clear` 的部分成功錯誤可能在
`error.details` 提供 `installed`、`runtimeApplied` 或 `runtimeCleared`；收到 exit 5
或 6 時不可假設所有狀態都未改變。

## 建議的 agent 設計迴圈

```sh
CLI="/Applications/CodexThemeSwitcher.app/Contents/Helpers/codex-theme"

"$CLI" schema
"$CLI" sample --archive --output /tmp/my-theme.codextheme

# Agent 修改 /tmp/my-theme.codextheme
"$CLI" validate --input /tmp/my-theme.codextheme
"$CLI" compile --input /tmp/my-theme.codextheme
"$CLI" preview \
  --input /tmp/my-theme.codextheme \
  --appearance all \
  --surface all \
  --output /tmp/my-theme-previews

"$CLI" install \
  --input /tmp/my-theme.codextheme \
  --collision fail
"$CLI" apply --id THEME_UUID --launch
```

建議 agent 先檢查四張預覽，再向使用者確認是否套用。`preview` 是 deterministic
native renderer，不會啟動 Codex，也不會執行任意 CSS。若 theme 含 raw CSS、自訂
selector、custom media 或只能近似呈現的 component declaration，回應中的
`warnings` 會明確列出；最終仍應在真實 Codex 驗證。

## 命令

| 命令 | 功能 | 改變狀態 |
| --- | --- | --- |
| `capabilities` | 協定版本、命令、限制與安全能力 | 否 |
| `schema` | 回傳完整 `.codextheme` JSON Schema | 只在指定 `--output` 時寫檔 |
| `sample` | 建立空白或內建主題的可編輯副本 | 只在指定 `--output` 時寫檔 |
| `list` | 列出內建／使用者主題與 active pointer | 可能建立 repository directory |
| `get` | 依 UUID 讀取 ThemeDocument | 只在指定 `--output` 時寫檔 |
| `validate` | Core 結構、容量與 CSS 安全驗證 | 否 |
| `normalize` | 以 canonical ISO-8601 JSON 重新編碼 | 只在指定 `--output` 時寫檔 |
| `compile` | 產生實際 runtime CSS 與 asset manifest | 只在指定 `--output` 時寫 CSS |
| `preview` | 產生 Light／Dark × Home／Chat PNG | 寫入指定輸出 |
| `install` | 儲存到本機 theme repository | 是 |
| `export` | 導出單檔 `.codextheme` | 寫入指定輸出 |
| `status` | 讀取 Codex/runtime 狀態 | 否 |
| `attach` | 啟動或重新連接帶 CDP 的 Codex | 是 |
| `apply` | validate → compile → runtime apply | 是 |
| `clear` | 清除注入樣式與 active pointer | 是 |

常用選項：

- `--input <path|->`：讀 ThemeDocument 或 `.codextheme`；`-` 表示 stdin。
- `--id <uuid>`：直接使用 repository 內的主題。
- `--root <directory>`：改用另一個 Theme Switcher 資料目錄。它只隔離 theme、
  runtime snapshot／token 等檔案，**不會**隔離真實 Codex process、CDP port 或
  bridge port；請勿把它當成 `attach`／`apply`／`clear` 的 sandbox。
- 搭配非預設 `--root` 執行 `attach`／`apply`／`clear` 是明確禁止的。CLI 會在任何
  repository 或 runtime mutation 前，以 exit 2 和
  `error.code = "custom_root_runtime_unsupported"` 拒絕。要操作真實 Codex 必須
  省略 `--root`。
- `--archive`：讓 `sample`、`get` 或 `normalize` 的輸出使用可分享 envelope。
- `--collision fail|replace|clone`：`install` 的 ID 衝突策略，預設 `fail`。
- `--appearance light|dark|all`、`--surface home|chat|all`：預覽矩陣。
- `--width`、`--height`：預覽像素尺寸；每邊 240–8192，最多四千萬像素。
- `apply --launch`：必要時先啟動並連接 Codex。
- `apply --input ... --install`：先安裝輸入檔再套用；沒有 `--install` 時只套用
  runtime snapshot，不會偷偷寫入 theme repository。

## 安全界線

- `apply` 不接受預先編譯的任意 CSS payload，只接受 ThemeDocument／archive 或已安裝
  UUID，並強制經過 Core validator 與 compiler。
- Canonical JSON 使用 ISO-8601 日期；輸入與 JSON Schema 也接受舊版 Foundation
  numeric dates，其數值是自 2001-01-01 00:00:00 UTC 起算的秒數。
- `@import`、外部網路 URL、`file:` URL、JavaScript、超量 CSS／asset 會被拒絕。
- CLI 不回傳或接受 runtime bearer token。
- `status`、`validate`、`compile` 與 `preview` 不啟動 Codex。
- 只有 agent 明確選擇 `attach`、`apply`、`clear` 才會改變 Codex runtime。
- `attach`、`apply`、`clear` 不接受非預設 `--root`，也不提供 custom-root runtime
  mutation 的 override 或 sandbox mode。
- JSON Schema 適合生成與快速檢查；Core validator 才是安全與總量限制的最終依據。

CLI 是穩定的 process/JSON 邊界，因此 MCP server 可以把每個命令薄包成 tool，而不需
直接存取 app 的私有檔案或 CDP token。
