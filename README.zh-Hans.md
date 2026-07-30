# Codex Theme Switcher

[English](README.md) | [繁體中文](README.zh-Hant.md) | **简体中文** | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [한국어](README.ko.md)

[![Codex Theme Switcher 演示视频](docs/media/codex-theme-switcher-demo.gif)](https://github.com/irons163/codex-theme-switcher/raw/refs/heads/main/docs/media/codex-theme-switcher-demo.mp4)

原生 macOS 菜单栏 App，可为 Codex／ChatGPT 桌面版设计、预览、应用和分享主题。

Theme Switcher 会在启动 Codex 时临时注入样式，不会修改、替换或重新签名原始 App。

## 下载

**当前稳定版：0.3.0**

[Apple Silicon DMG](https://github.com/irons163/codex-theme-switcher/releases/download/v0.3.0/CodexThemeSwitcher-0.3.0-apple-silicon.dmg)
·
[Intel DMG](https://github.com/irons163/codex-theme-switcher/releases/download/v0.3.0/CodexThemeSwitcher-0.3.0-intel.dmg)
·
[版本说明与校验和](https://github.com/irons163/codex-theme-switcher/releases/tag/v0.3.0)

需要 macOS 13 或更高版本。两种安装包均已签名并通过 Apple 公证。

## 主要功能

- 菜单栏主题库、编辑器、实时预览和连接状态。
- 颜色、字体、间距、圆角、阴影、模糊、缩放和动画。
- Light／Dark 背景图片、Fit／Fill、焦点、滤镜、遮罩和玻璃效果。
- 实验性 ChatGPT Voice 背景、圆球样式、动态人物、嘴型、眨眼和待机动作。
- 高级组件设置、selector 规则、自定义变量和 raw CSS。
- 单个 `.codextheme` 文件导入／导出，并嵌入图片和字体。
- 英文、繁体中文、简体中文、法文、西班牙文、日文和韩文。

## 快速开始

1. 安装并打开 Codex Theme Switcher，然后点击 macOS 菜单栏中的图标。
2. 点击 **启动并连接 Codex**。第一次连接可能会重新启动 Codex。
3. 选择内置主题、创建可编辑副本，或新建主题。
4. 调整设计，并使用 Light／Dark 与 Home／Chat 预览检查效果。
5. 保存主题，然后点击 **应用** 发送到 Codex。
6. 使用 **导出** 分享 `.codextheme`；使用 **导入** 安装他人分享的主题。

第一次连接不会自动应用当前选中的主题。之后重新连接会恢复上次成功应用的主题，不包括尚未应用的草稿更改。

## 截图

### 主题工作室

![Codex Theme Switcher 主题工作室，显示主题库、实时预览与编辑分页](docs/images/theme-studio.png)

### Renderer 预览

| Paper · Light / Home | Midnight · Dark / Chat |
| --- | --- |
| ![Paper 浅色 Home 预览](docs/images/paper-light-home.png) | ![Midnight 深色 Chat 预览](docs/images/midnight-dark-chat.png) |

Agent 生成的预览是接近真实画面的近似结果。分享主题前，请在实际 Codex App 中确认高级 CSS 和 selector 规则。

## 自定义指南

### 背景与玻璃

- Light 和 Dark 可使用不同图片，也可共用图片并设置不同效果。
- 支持 Fit、Fill、Stretch、Fit Width、Fit Height、Original 和 Tile，并可搭配焦点与缩放。
- 图片透明度和滤镜可与侧栏、内容区、输入框、卡片、菜单及代码块的玻璃效果分开控制。
- 壁纸可铺满整个窗口，或排除左侧栏。
- 可加入独立的中央内容面板，调整底色、边框、阴影、模糊、圆角、宽度和内边距。

### ChatGPT Voice（实验性）

- 设置 Voice 背景，以及动画圆球内部的独立图片。
- 添加闭嘴人物和最多八张嘴型图，或直接导入 2×2／3×3 嘴型图。
- 调整灵敏度、静音阈值、张嘴／闭嘴速度、眨眼、待机动作、脉动和原生圆球显示程度。
- 嘴型会跟随音量强度，并非音素级口型同步。

Voice 样式依赖 ChatGPT 内部 renderer，Codex／ChatGPT 更新后可能需要相应调整。

## 导入与导出

- 导出会创建一个包含主题设置和嵌入素材的 `.codextheme`。
- 导入主题后不会自动应用；请先检查，再点击 **应用**。
- Image Skin 支持 PNG、JPEG、WebP、GIF 和 AVIF。
- 限制：每个素材 16 MB、全部素材合计 32 MB、每个 `.codextheme` 48 MB。

示例：[`minimal.codextheme`](Examples/minimal.codextheme) 和 [`full.codextheme`](Examples/full.codextheme)。

## 使用 AI Agent 设计

安装 App 后，将以下提示发送给 AI agent：

```text
请使用以下 Agent CLI 帮我设计 Codex theme：
/Applications/CodexThemeSwitcher.app/Contents/Helpers/codex-theme

先运行 capabilities 和 schema，完成 validate、compile 以及四张预览。
未经我确认不要应用。
```

CLI 可创建、验证、编译、导入、导出，并生成 Light／Dark × Home／Chat 预览。只有明确执行 `attach`、`apply` 或 `clear` 才会更改 Codex。

完整命令请参阅 [`docs/AGENT_API.md`](docs/AGENT_API.md)。

## 语言与更新

- App 默认跟随 macOS 语言；不支持的语言会回退到英文。
- 可在 **设置 → 界面语言** 手动选择语言。
- 可在设置中选择 Stable 或 Beta 更新频道。
- 更新使用 Sparkle，会自动提供 Apple Silicon 或 Intel 对应版本。

## 安全与恢复

- Theme Switcher 不会修改 `app.asar`，也不会替换 Codex／ChatGPT 文件。
- 主题数据和连接 bridge 都保留在本机 Mac。
- 导入的主题不能运行 JavaScript，也不能加载远程或本地文件 URL。
- 如果自定义 CSS 导致 Codex 无法阅读，请从菜单栏 App 选择 **恢复 Codex 原始样式**。
- 退出 Codex 并以正常方式重新打开，即可移除临时注入的样式。

这是一个独立项目，与 OpenAI 没有合作或背书关系。

## 从源代码构建

要求：macOS 13+、Swift 6、Node.js 22+，以及 Codex／ChatGPT 桌面版。

```sh
swift build
swift test
npm test
scripts/package-app.sh
open dist/CodexThemeSwitcher.app
```

开发文档：

- [Agent CLI](docs/AGENT_API.md)
- [更新、签名、公证和发布](docs/UPDATES.md)
