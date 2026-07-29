# Codex Theme Switcher

[English](README.md) | **繁體中文** | [简体中文](README.zh-Hans.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [한국어](README.ko.md)

![Codex Theme Switcher 套用圖片背景、玻璃效果與自訂元件的實際 Codex 畫面](docs/images/codex-theme-showcase.jpg)

原生 macOS menu bar 主題工作室。它不建立一般主視窗、不出現在 Dock，也不修改、
重簽或覆寫 `Codex.app` / `ChatGPT.app`。

Theme Switcher 以 Chromium DevTools Protocol（CDP）連接 Codex renderer，將編譯後
的 CSS 寫進一個 namespaced `<style>`。主題切換會即時同步到所有 Codex 視窗；
Codex reload 或開新視窗後，runtime 也會自動補上主題。

## 截圖

### Menu bar 主題工作室

![Codex Theme Switcher 主題工作室，顯示主題庫、即時預覽與完整編輯分頁](docs/images/theme-studio.png)

### Agent renderer 預覽

| Paper · Light / Home | Midnight · Dark / Chat |
| --- | --- |
| ![Paper 淺色 Home 預覽](docs/images/paper-light-home.png) | ![Midnight 深色 Chat 預覽](docs/images/midnight-dark-chat.png) |

Agent CLI 可在無視窗環境產生 Light／Dark × Home／Chat PNG，供 AI agent 反覆檢查。
這些是結構化的近似預覽；selector rules、raw CSS 與真實 Codex renderer 的最終結果，
仍應在套用後確認。

## 功能

- 純 menu bar app；所有主題庫、編輯、預覽與 runtime 狀態都在 menu bar panel。
- 三個內建模板：Midnight、Paper、High Contrast。
- 一鍵套用、恢復 Codex 原始樣式、重新連接 renderer。
- 自動從已保存位置、執行中的 App、Launch Services 與常見目錄尋找 Codex；
  也可在設定中指定外接磁碟或其他資料夾內的 Codex App。
- 視覺化色彩系統：
  - 基礎 semantic colors。
  - Codex `--color-token-*` 介面、interaction、diff 與 terminal tokens。
- 字型、字級、行高、內容寬度、間距、圓角、陰影、模糊、縮放與動畫。
- 背景與玻璃（Image Skin）：明暗雙背景、Fit / Fill 等七種尺寸模式、焦點裁切、
  可選全視窗或避開左側欄的壁紙畫布、濾鏡、overlay、分區 glass 與中央內容面板。
- 實驗性 ChatGPT Voice 樣式：Light／Dark 可分別調整縮放、透明度、色彩濾鏡、光暈、
  背景色及 Voice 專用進階 CSS；只會送進獨立的 `avatar-overlay` renderer。
- 任意 component declarations。
- 任意 CSS selector rules。
- 完整 raw CSS escape hatch。
- 多 layer 與 light / dark / custom media query。
- PNG、JPEG、WebP、GIF 與字型等素材可嵌入模板；runtime 會分段傳輸並建立
  renderer-local Blob URL，因此大型 4K 圖片不會撞到 CSS declaration 長度限制。
- 單檔 `.codextheme` 導入／導出，方便分享。
- 預設依 macOS 偏好語言自動切換，也可在設定中手動選擇英文、繁體中文、簡體中文、
  法文、西班牙文、日文或韓文；自動模式遇到其他語言時回退英文。
- Sparkle 2 自動更新：可選 Stable／Beta 頻道，依 Apple Silicon／Intel 取得對應
  安裝檔，並顯示相同七語系的版本說明。
- 啟動時檢查更新，之後每 30 分鐘檢查一次；也能從設定或右上角選單手動檢查、
  略過特定版本，或改用手動下載。
- 內附 JSON-first `codex-theme` agent CLI：AI agent 可取得 schema／範例、驗證、
  正規化、編譯、安裝、導出及產生 Light／Dark × Home／Chat PNG 預覽；只有明確
  呼叫 `attach`、`apply` 或 `clear` 才會改變 Codex。

## 背景與玻璃 / Image Skin

Image Skin 可把 Codex 做成完整的圖片主題，而不只是替換色票：

- Light / Dark 可分別選擇背景圖，也能共用同一張圖並套用不同效果。
- 背景支援 Fit（完整顯示）、Fill（等比例填滿裁切）、Stretch、Fit Width、
  Fit Height、Original 與 Tile；每種模式都能搭配焦點／起點、縮放、不透明度，
  以及亮度、對比、飽和度與模糊濾鏡。
- 「壁紙避開左側欄」會把圖片、Fit / Fill、焦點、overlay、scrim 與 vignette
  整組改以主內容區重新排版；側欄保留自己的背景底色與 glass。側欄拖曳改寬或
  收合時，壁紙邊界會跟著實際 Codex layout 自動調整。
- Overlay 可使用純色 scrim、線性漸層或 vignette，讓側欄、標題與輸入區在複雜
  圖片上仍保持清楚。
- Sidebar、main content、composer、card、menu、popover 與 code block 可分區設定
  glass fill、透明度、backdrop blur、邊框、圓角與陰影；調整 panel 透明度不會連帶
  淡化文字。
- 「中央內容面板」獨立包住 Home Hero 或 Chat 對話紀錄，不包含建議 Cards 與
  Composer。Light / Dark 可分別設定底色、邊框、陰影色與透明度；材質可調 blur、
  saturation、邊框寬度、圓角、陰影位移／擴散、最大寬度及水平／垂直內距。
- 預覽可切換 Light / Dark 與 Home / Chat，方便同時檢查背景裁切、文字對比和
  元件表面。
- Image Skin 使用的背景會嵌入 `.codextheme`，導出後不依賴原始檔案路徑，
  收到模板的人可直接導入使用。

視覺控制會產生可攜的 theme variables 與 component overrides。需要更精細的 selector、
多重漸層、blend mode 或動畫時，仍可在 Raw CSS 最後覆寫；Raw CSS 維持 theme
cascade 中的最高自由度。

Image Skin 圖片欄位只接受 raster asset（PNG、JPEG、WebP、GIF、AVIF），每個 asset 上限
16 MB。所有素材合計上限 32 MB，單一 `.codextheme` 上限 48 MB。字型仍可從進階
素材功能內嵌，但不能指定為 Image Skin 背景。

## ChatGPT Voice 樣式

Voice 分頁使用獨立樣式表控制 ChatGPT Voice 中可由 CSS 定位的表面。主視窗的壁紙與
元件規則不會送進 `avatar-overlay`；未啟用 Voice 樣式時也不會連接該 renderer。
關閉已套用的 Voice 樣式會清除樣式並中斷該 session。

內建控制包含縮放、透明度、亮度、對比、飽和度、色相旋轉、模糊、光暈與背景色。
這項功能仍屬實驗性：DOM／Canvas 容器及其合成結果可被 CSS 調整，但若圓球內部由
原生 AppKit／Core Animation 繪製，Theme Switcher 無法改寫其像素或內部動畫。

## 使用流程

1. 開啟 app，從 macOS menu bar 的調色盤圖示進入主題工作室。
2. 按「啟動並連接 Codex」；第一次連接可能會重新啟動 Codex。
   首次連接不會自動套用預選模板；之後重新連接則會恢復 runtime 保存的最後一次
   成功套用快照，不包含之後只儲存或仍在草稿中的變更。
3. 直接套用內建模板，或先「製作可編輯副本」；也可用左下角新增空白主題。
4. 在背景與玻璃、Voice、色彩、字體與版面、元件、規則、進階 CSS、素材及資訊分頁編輯。
   橘色圓點代表該主題仍有未儲存變更；切到其他主題再回來也不會遺失草稿。
5. 按儲存後套用；要分享時按導出，會得到包含所有內嵌素材的單一
   `.codextheme`。收到模板的人可從同一位置導入。
6. 「設定」分頁可開關自動更新、選擇 Stable／Beta、檢查新版本，以及重新顯示
   目前版本的「新功能」。

## 安全模型

- 不 patch `app.asar`，保留 OpenAI app 的簽章、notarization 與 ASAR integrity。
- Theme Switcher bridge 只監聽 `127.0.0.1`，並使用私有的 256-bit bearer token。
- `.codextheme` 不允許 JavaScript。
- 匯入與編譯會拒絕 `@import`、`http:`、`https:`、protocol-relative 與 `file:` URL。
- 素材內嵌在模板中；匯入不會解壓 ZIP，因此沒有 path traversal / zip-slip。
- Image Skin 背景只接受 raster image；每個內嵌 asset 會在導入時驗證格式、base64
  資料與 16 MB 容量上限。
- Runtime 與 style ID 都使用 `codex-theme-switcher` namespace，不會清除其他注入工具。
- Menu bar 永遠提供「恢復 Codex 原始樣式」，即使自訂 CSS 損壞畫面仍可救援。
- Agent CLI 明確禁止以非預設 `--root` 執行 `attach`、`apply` 或 `clear`；custom
  root 只供隔離 repository 與離線工作，不能作為真實 Codex runtime 的 sandbox。
- Chromium 的 CDP debug endpoint 也明確綁在 `127.0.0.1`，但 CDP 本身不提供
  bearer-token 驗證；同一台 Mac 上的其他本機程序仍可能連線。若不再使用主題功能，
  請結束 Codex 並以一般方式重新開啟，讓它不再帶 remote-debugging 參數。

## 建置

需求：

- macOS 13+
- Swift 6 toolchain
- Codex desktop app（目前 unified app 也可能位於 `/Applications/ChatGPT.app`）
- Node.js 22+；程式會優先使用 Codex app 內附的
  `Contents/Resources/cua_node/bin/node`，再尋找 PATH / Homebrew Node

```sh
swift build
swift test
npm test
npm run check
swift run CodexThemeSwitcher
swift run codex-theme capabilities
```

建立可雙擊的 menu bar `.app`：

```sh
scripts/package-app.sh
open dist/CodexThemeSwitcher.app
```

輸出的 `Info.plist` 含 `LSUIElement=true`，因此 app 不會出現在 Dock 或一般 app
switcher。Agent CLI 會封裝在
`CodexThemeSwitcher.app/Contents/Helpers/codex-theme`，JSON Schema 則位於
`Contents/Resources/Schemas/`。完整協定與範例見
[`docs/AGENT_API.md`](docs/AGENT_API.md)。沒有提供 signing identity 時，script
會使用 ad-hoc signing；正式散佈可設定：

```sh
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
SPARKLE_PUBLIC_ED_KEY="<base64 Ed25519 public key>" \
  scripts/package-app.sh
```

正式封裝必須提供 Sparkle EdDSA 公鑰，script 會把它寫入 `SUPublicEDKey`，並拒絕
任何 `SUAllowsInsecureUpdates` 設定。只有本機 ad-hoc 開發包會加入 local-only 的
insecure allowance，不能拿來正式發布。

## App 更新與發布

- Stable feed：
  `appcast-arm64.xml`、`appcast-x86_64.xml`
- Beta feed：
  `appcast-beta-arm64.xml`、`appcast-beta-x86_64.xml`
- 更新 feed 固定放在 GitHub 最新 Stable Release；Beta release 只覆寫其中的
  `appcast-beta-*`，因此固定 URL 不會因 GitHub 忽略 prerelease 而失效。
- 每個 appcast enclosure 都必須有 `sparkle:edSignature`，正式 App 也必須內含
  對應的 `SUPublicEDKey`。
- 七份版本說明放在
  `docs/release-notes/v<version>/release-notes.<language>.md`。

完整 secrets、簽章、notarization 與 release 操作請見
[`docs/UPDATES.md`](docs/UPDATES.md)。

## 第一次連接

一般啟動的 Codex 不會開啟 CDP port。第一次按「啟動並連接 Codex」時，如果沒有可
共用的 Codex debug target，Theme Switcher 會先正常要求 Codex 結束，再用以下參數
重新啟動：

```text
--remote-debugging-address=127.0.0.1
--remote-debugging-port=57340
--remote-allow-origins=http://127.0.0.1:57340
```

如果 `codex-desktop-switcher` 已建立 57330–57341 之間的 Codex target，本程式會優先
共用它，不重啟 Codex。

## `.codextheme` 格式

`.codextheme` 是 versioned、單一 JSON envelope：

```json
{
  "format": "com.codex-theme-switcher.theme",
  "archiveVersion": 1,
  "exportedAt": "2026-07-25T00:00:00Z",
  "theme": {
    "schemaVersion": 1,
    "id": "9d9028d5-f76a-4e99-a5e5-da3533fe646d",
    "metadata": {
      "name": "My Theme",
      "author": "Author",
      "description": "",
      "version": "1.0.0",
      "tags": ["dark", "glass"],
      "createdAt": "2026-07-25T00:00:00Z",
      "updatedAt": "2026-07-25T00:00:00Z"
    },
    "layers": [],
    "assets": []
  }
}
```

可直接匯入的檔案見
[`Examples/minimal.codextheme`](Examples/minimal.codextheme) 與
[`Examples/full.codextheme`](Examples/full.codextheme)。Agent 可使用
[`codextheme.schema.json`](Sources/CodexThemeAgentCLI/Resources/codextheme.schema.json)
產生與檢查
JSON；日期一律輸出 ISO-8601，匯入仍相容舊版 Foundation 的 numeric dates。JSON
Schema 同樣接受兩種日期輸入，並提供結構、enum 與數值範圍的快速檢查；Core
validator 仍是 CSS 安全掃描與總容量限制的最終依據。

Theme cascade 順序固定為：

1. semantic variables 與 Codex stable-token aliases
2. advanced/custom variables
3. component overrides
4. selector rules
5. Image Skin 產生的背景、色票與 glass 規則
6. raw CSS

第 1–4 項會依 layer 順序編譯；Image Skin 接著覆蓋結構化介面設定，最後再依 layer
順序輸出 raw CSS，因此 Raw CSS 是真正的最終 escape hatch。匯入時 ID 衝突預設會
clone 成新 UUID，而且不會自動套用。

內嵌素材在 CSS 中使用：

```css
body {
  background-image: theme-asset("ASSET-UUID");
}
```

編譯時會安全改寫為短的 `codex-theme-asset://` placeholder。Runtime 以 256 KiB
區塊把素材送到每個 renderer，在 renderer 內建立 Blob URL 後才原子切換 style；
相同素材會重用 Blob，切換或清除主題時也會撤銷不再使用的 URL。

## 本機資料

```text
~/Library/Application Support/CodexThemeSwitcher/
  Themes/                 # user theme JSON
  active-theme.json       # repository active pointer
  Runtime/
    active-theme.json     # runtime CSS template、asset manifest 與資料
    bridge-token          # mode 0600
  Logs/runtime.log
```

## 架構

- `CodexThemeSwitcherCore`: theme schema、validator、compiler、repository、archive。
- `CodexThemeRuntime`: async Swift runner 與 authenticated Node/CDP runtime。
- `CodexThemeSwitcher`: AppKit/SwiftUI menu bar studio。
- `codex-theme`: 給 AI agent 與自動化使用的結構化 JSON CLI 與無視窗 PNG renderer。
- `Tests/`：Swift test suites。
- `test/`：Node runtime test suites。

Selector rules 屬於 expert layer，Codex 更新後可能需要調整；基礎與
`--color-token-*` layers 優先使用目前 Codex 自己的 CSS contract，較不依賴 React
class names。
