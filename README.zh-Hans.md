# Codex Theme Switcher

[English](README.en.md) | [繁體中文](README.md) | **简体中文** | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [한국어](README.ko.md)

原生 macOS 菜单栏主题工作室。它不创建常规主窗口、不出现在 Dock，也不修改、
重新签名或覆盖 `Codex.app` / `ChatGPT.app`。

Theme Switcher 通过 Chromium DevTools Protocol（CDP）连接 Codex renderer，将编译后
的 CSS 写入一个 namespaced `<style>`。主题切换会实时同步到所有 Codex 窗口；
Codex reload 或打开新窗口后，runtime 也会自动补上主题。

## 截图

### 菜单栏主题工作室

![Codex Theme Switcher 主题工作室，显示主题库、实时预览与完整编辑标签页](docs/images/theme-studio.png)

### Agent renderer 预览

| Paper · Light / Home | Midnight · Dark / Chat |
| --- | --- |
| ![Paper 浅色 Home 预览](docs/images/paper-light-home.png) | ![Midnight 深色 Chat 预览](docs/images/midnight-dark-chat.png) |

Agent CLI 可在无窗口环境中生成 Light／Dark × Home／Chat PNG，供 AI agent 反复检查。
这些是结构化的近似预览；selector rules、raw CSS 与真实 Codex renderer 的最终结果，
仍应在应用后确认。

## 功能

- 纯菜单栏 app；所有主题库、编辑、预览与 runtime 状态都在菜单栏面板中。
- 三个内置模板：Midnight、Paper、High Contrast。
- 一键应用、恢复 Codex 原始样式、重新连接 renderer。
- 可视化色彩系统：
  - 基础 semantic colors。
  - Codex `--color-token-*` 界面、interaction、diff 与 terminal tokens。
- 字体、字号、行高、内容宽度、间距、圆角、阴影、模糊、缩放与动画。
- 背景与玻璃（Image Skin）：明暗双背景、Fit / Fill 等七种尺寸模式、焦点裁切、
  可选全窗口或避开左侧栏的壁纸画布、滤镜、overlay、分区 glass 与中央内容面板。
- 任意 component declarations。
- 任意 CSS selector rules。
- 完整 raw CSS escape hatch。
- 多 layer 与 light / dark / custom media query。
- PNG、JPEG、WebP、GIF 与字体等素材可嵌入模板；runtime 会分段传输并创建
  renderer-local Blob URL，因此大型 4K 图片不会遇到 CSS declaration 长度限制。
- 单文件 `.codextheme` 导入／导出，便于分享。
- 根据 macOS 首选语言自动切换英文、繁体中文、简体中文、法文、西班牙文、日文或韩文；
  其他语言回退到英文。
- Sparkle 2 自动更新：可选 Stable／Beta 频道，根据 Apple Silicon／Intel 获取对应
  安装文件，并提供同样七种语言的版本说明。
- 启动时检查更新，之后每 30 分钟检查一次；也可从设置或右上角菜单手动检查、
  跳过特定版本，或改用手动下载。
- 内置 JSON-first `codex-theme` agent CLI：AI agent 可获取 schema／示例、验证、
  规范化、编译、安装、导出及生成 Light／Dark × Home／Chat PNG 预览；只有明确
  调用 `attach`、`apply` 或 `clear` 才会更改 Codex。

## 背景与玻璃 / Image Skin

Image Skin 可将 Codex 变成完整的图片主题，而不只是替换色板：

- Light / Dark 可分别选择背景图，也可共用同一张图片并应用不同效果。
- 背景支持 Fit（完整显示）、Fill（等比例填满裁切）、Stretch、Fit Width、
  Fit Height、Original 与 Tile；每种模式都可配合焦点／起点、缩放、不透明度，
  以及亮度、对比度、饱和度与模糊滤镜。
- “壁纸避开左侧栏”会将图片、Fit / Fill、焦点、overlay、scrim 与 vignette
  整组改为按主内容区重新布局；侧栏保留自己的背景底色与 glass。拖动改变侧栏宽度或
  收起侧栏时，壁纸边界会跟随实际 Codex layout 自动调整。
- Overlay 可使用纯色 scrim、线性渐变或 vignette，使侧栏、标题与输入区在复杂
  图片上仍保持清晰。
- Sidebar、main content、composer、card、menu、popover 与 code block 可分区设置
  glass fill、透明度、backdrop blur、边框、圆角与阴影；调整 panel 透明度不会连带
  淡化文字。
- “中央内容面板”独立包住 Home Hero 或 Chat 对话记录，不包含建议 Cards 与
  Composer。Light / Dark 可分别设置底色、边框、阴影色与透明度；材质可调整 blur、
  saturation、边框宽度、圆角、阴影位移／扩散、最大宽度及水平／垂直内边距。
- 预览可切换 Light / Dark 与 Home / Chat，便于同时检查背景裁切、文字对比度和
  组件表面。
- Image Skin 使用的背景会嵌入 `.codextheme`，导出后不依赖原始文件路径，
  收到模板的人可直接导入使用。

视觉控制会生成可移植的 theme variables 与 component overrides。需要更精细的 selector、
多重渐变、blend mode 或动画时，仍可在 Raw CSS 中最后覆盖；Raw CSS 保持 theme
cascade 中的最高自由度。

Image Skin 图片字段只接受 raster asset（PNG、JPEG、WebP、GIF、AVIF），每个 asset 上限
16 MB。所有素材合计上限 32 MB，单个 `.codextheme` 上限 48 MB。字体仍可从高级
素材功能中嵌入，但不能指定为 Image Skin 背景。

## 使用流程

1. 打开 app，从 macOS 菜单栏的调色板图标进入主题工作室。
2. 点击“启动并连接 Codex”；第一次连接可能会重新启动 Codex。
   首次连接不会自动应用预选模板；之后重新连接则会恢复 runtime 保存的最近一次
   成功应用快照。之后仅保存到 repository 或仍留在草稿中的更改不会包含在内。
3. 直接应用内置模板，或先“制作可编辑副本”；也可从左下角新建空白主题。
4. 在背景与玻璃、色彩、字体与布局、组件、规则、高级 CSS、素材及信息标签页中编辑。
   橙色圆点表示该主题仍有未保存更改；切换到其他主题后再返回也不会丢失草稿。
5. 保存后点击应用；需要分享时点击导出，会得到包含所有嵌入素材的单个
   `.codextheme`。收到模板的人可从同一位置导入。
6. “设置”标签页可开关自动更新、选择 Stable／Beta、检查新版本，以及重新显示
   当前版本的“新功能”。

## 安全模型

- 不 patch `app.asar`，保留 OpenAI app 的签名、notarization 与 ASAR integrity。
- Theme Switcher bridge 仅监听 `127.0.0.1`，并使用私有的 256-bit bearer token。
- `.codextheme` 不允许 JavaScript。
- 导入与编译会拒绝 `@import`、`http:`、`https:`、protocol-relative 与 `file:` URL。
- 素材嵌入在模板中；导入时不会解压 ZIP，因此不存在 path traversal / zip-slip。
- Image Skin 背景只接受 raster image；每个嵌入 asset 都会在导入时验证格式、base64
  数据与 16 MB 容量上限。
- Runtime 与 style ID 都使用 `codex-theme-switcher` namespace，不会清除其他注入工具。
- 菜单栏始终提供“恢复 Codex 原始样式”，即使自定义 CSS 损坏界面仍可恢复。
- Agent CLI 明确禁止使用非默认 `--root` 执行 `attach`、`apply` 或 `clear`；custom
  root 仅用于隔离 repository 与离线工作，不能作为真实 Codex runtime 的 sandbox。
- Chromium 的 CDP debug endpoint 也明确绑定在 `127.0.0.1`，但 CDP 本身不提供
  bearer-token 验证；同一台 Mac 上的其他本地进程仍可能连接。如果不再使用主题功能，
  请退出 Codex 并以常规方式重新打开，使其不再带有 remote-debugging 参数。

## 构建

要求：

- macOS 13+
- Swift 6 toolchain
- Codex desktop app（当前 unified app 也可能位于 `/Applications/ChatGPT.app`）
- Node.js 22+；程序会优先使用 Codex app 内置的
  `Contents/Resources/cua_node/bin/node`，再查找 PATH / Homebrew Node

```sh
swift build
swift test
npm test
npm run check
swift run CodexThemeSwitcher
swift run codex-theme capabilities
```

创建可双击的菜单栏 `.app`：

```sh
scripts/package-app.sh
open dist/CodexThemeSwitcher.app
```

输出的 `Info.plist` 包含 `LSUIElement=true`，因此 app 不会出现在 Dock 或常规 app
switcher 中。Agent CLI 会打包在
`CodexThemeSwitcher.app/Contents/Helpers/codex-theme`，JSON Schema 则位于
`Contents/Resources/Schemas/`。完整协议与示例见
[`docs/AGENT_API.md`](docs/AGENT_API.md)。未提供 signing identity 时，script
会使用 ad-hoc signing；正式分发可设置：

```sh
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
SPARKLE_PUBLIC_ED_KEY="<base64 Ed25519 public key>" \
  scripts/package-app.sh
```

正式打包必须提供 Sparkle EdDSA 公钥，script 会将其写入 `SUPublicEDKey`，并拒绝
任何 `SUAllowsInsecureUpdates` 设置。只有本地 ad-hoc 开发包会加入 local-only 的
insecure allowance，不能用于正式发布。

## App 更新与发布

- Stable feed：
  `appcast-arm64.xml`、`appcast-x86_64.xml`
- Beta feed：
  `appcast-beta-arm64.xml`、`appcast-beta-x86_64.xml`
- 更新 feed 固定放在 GitHub 最新 Stable Release；Beta release 只覆盖其中的
  `appcast-beta-*`，因此固定 URL 不会因 GitHub 忽略 prerelease 而失效。
- 每个 appcast enclosure 都必须带有 `sparkle:edSignature`，正式 App 也必须内置
  对应的 `SUPublicEDKey`。
- 七份版本说明放在
  `docs/release-notes/v<version>/release-notes.<language>.md`。

完整 secrets、签名、notarization 与 release 操作请参阅
[`docs/UPDATES.md`](docs/UPDATES.md)。

## 第一次连接

常规启动的 Codex 不会开放 CDP port。第一次点击“启动并连接 Codex”时，如果没有可
共用的 Codex debug target，Theme Switcher 会先正常请求 Codex 退出，再使用以下参数
重新启动：

```text
--remote-debugging-address=127.0.0.1
--remote-debugging-port=57340
--remote-allow-origins=http://127.0.0.1:57340
```

如果 `codex-desktop-switcher` 已在 57330–57341 之间创建 Codex target，本程序会优先
共用它，而不重新启动 Codex。

## `.codextheme` 格式

`.codextheme` 是 versioned、单一 JSON envelope：

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

可直接导入的文件见
[`Examples/minimal.codextheme`](Examples/minimal.codextheme) 与
[`Examples/full.codextheme`](Examples/full.codextheme)。Agent 可使用
[`codextheme.schema.json`](Sources/CodexThemeAgentCLI/Resources/codextheme.schema.json)
生成与检查
JSON；日期统一输出 ISO-8601，导入时仍兼容旧版 Foundation 的 numeric dates。JSON
Schema 同样接受两种日期输入，并提供结构、enum 与数值范围的快速检查；Core
validator 仍是 CSS 安全扫描与总容量限制的最终依据。

Theme cascade 顺序固定为：

1. semantic variables 与 Codex stable-token aliases
2. advanced/custom variables
3. component overrides
4. selector rules
5. Image Skin 生成的背景、色板与 glass 规则
6. raw CSS

第 1–4 项会按 layer 顺序编译；Image Skin 随后覆盖结构化界面设置，最后再按 layer
顺序输出 raw CSS，因此 Raw CSS 是真正的最终 escape hatch。导入时 ID 冲突默认会
clone 为新 UUID，并且不会自动应用。

嵌入素材在 CSS 中使用：

```css
body {
  background-image: theme-asset("ASSET-UUID");
}
```

编译时会安全改写为较短的 `codex-theme-asset://` placeholder。Runtime 以 256 KiB
区块将素材发送到每个 renderer，在 renderer 内创建 Blob URL 后才原子切换 style；
相同素材会复用 Blob，切换或清除主题时也会撤销不再使用的 URL。

## 本地数据

```text
~/Library/Application Support/CodexThemeSwitcher/
  Themes/                 # user theme JSON
  active-theme.json       # repository active pointer
  Runtime/
    active-theme.json     # runtime CSS template、asset manifest 與資料
    bridge-token          # mode 0600
  Logs/runtime.log
```

## 架构

- `CodexThemeSwitcherCore`: theme schema、validator、compiler、repository、archive。
- `CodexThemeRuntime`: async Swift runner 与 authenticated Node/CDP runtime。
- `CodexThemeSwitcher`: AppKit/SwiftUI 菜单栏工作室。
- `codex-theme`: 面向 AI agent 与自动化的结构化 JSON CLI 和无窗口 PNG renderer。
- `Tests/`：Swift test suites。
- `test/`：Node runtime test suites。

Selector rules 属于 expert layer，Codex 更新后可能需要调整；基础与
`--color-token-*` layers 优先使用当前 Codex 自己的 CSS contract，较少依赖 React
class names。
