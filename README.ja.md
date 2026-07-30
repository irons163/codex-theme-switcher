# Codex Theme Switcher

[English](README.md) | [繁體中文](README.zh-Hant.md) | [简体中文](README.zh-Hans.md) | [Français](README.fr.md) | [Español](README.es.md) | **日本語** | [한국어](README.ko.md)

![Codex Theme Switcherで画像背景、ガラス効果、カスタムコンポーネントを適用したCodex](docs/images/codex-theme-showcase.jpg)

Codex / ChatGPTデスクトップAppのテーマを作成、プレビュー、適用、共有できる、macOSネイティブのメニューバーAppです。

Theme SwitcherはCodexの起動時に一時的なスタイルを注入します。元のAppを変更、置換、再署名することはありません。

## ダウンロード

**現在の安定版：0.3.0**

[Apple Silicon DMG](https://github.com/irons163/codex-theme-switcher/releases/download/v0.3.0/CodexThemeSwitcher-0.3.0-apple-silicon.dmg)
·
[Intel DMG](https://github.com/irons163/codex-theme-switcher/releases/download/v0.3.0/CodexThemeSwitcher-0.3.0-intel.dmg)
·
[リリースノートとチェックサム](https://github.com/irons163/codex-theme-switcher/releases/tag/v0.3.0)

macOS 13以降が必要です。どちらのインストーラも署名済みで、Appleの公証を受けています。

## 主な機能

- メニューバー内のテーマライブラリ、エディタ、ライブプレビュー、接続状態。
- 色、フォント、余白、角丸、影、ぼかし、拡大縮小、モーション。
- ライト／ダーク背景画像、Fit／Fill、フォーカルポイント、フィルタ、オーバーレイ、ガラス効果。
- 実験的なChatGPT Voice背景、オーブ、アニメーションポートレート、口形、まばたき、待機モーション。
- 高度なコンポーネント設定、セレクタルール、カスタム変数、Raw CSS。
- 画像やフォントを内包する単一`.codextheme`ファイルの読み込み／書き出し。
- 英語、繁体字中国語、簡体字中国語、フランス語、スペイン語、日本語、韓国語。

## クイックスタート

1. Codex Theme Switcherをインストールして開き、macOSメニューバーのアイコンをクリックします。
2. **Codexを起動して接続**をクリックします。初回接続ではCodexが再起動する場合があります。
3. 組み込みテーマを選ぶか、編集可能なコピーまたは新しいテーマを作成します。
4. デザインを調整し、ライト／ダークとホーム／チャットのプレビューを確認します。
5. テーマを保存し、**適用**をクリックしてCodexへ送信します。
6. **書き出し**で`.codextheme`を共有し、**読み込み**で受け取ったテーマを追加します。

初回接続では、選択中のテーマは自動適用されません。次回以降の接続では、未適用の下書きではなく、最後に正常に適用したテーマが復元されます。

## スクリーンショット

### テーマスタジオ

![テーマライブラリ、ライブプレビュー、編集タブを表示するCodex Theme Switcher](docs/images/theme-studio.png)

### Rendererプレビュー

| Paper · ライト / ホーム | Midnight · ダーク / チャット |
| --- | --- |
| ![Paperライトのホームプレビュー](docs/images/paper-light-home.png) | ![Midnightダークのチャットプレビュー](docs/images/midnight-dark-chat.png) |

Agentが生成するプレビューは実画面に近い近似表示です。テーマを共有する前に、高度なCSSとセレクタルールを実際のCodex Appで確認してください。

## カスタマイズガイド

### 背景とガラス

- ライトとダークで別々の画像を使うか、同じ画像に異なる効果を設定できます。
- Fit、Fill、Stretch、Fit Width、Fit Height、Original、Tileを選び、フォーカルポイントとズームを調整できます。
- 画像の不透明度とフィルタを、サイドバー、コンテンツ、入力欄、カード、メニュー、コードブロックのガラス効果とは別に調整できます。
- 壁紙をウィンドウ全体に表示するか、サイドバーを除外できます。
- 塗り、枠線、影、ぼかし、角丸、幅、余白を個別に設定した中央コンテンツパネルを追加できます。

### ChatGPT Voice（実験的）

- Voice背景と、アニメーションオーブ内の独立した画像を設定できます。
- 口を閉じたポートレートと最大8枚の口形画像を追加するか、2×2／3×3のスプライトシートを読み込めます。
- 感度、無音しきい値、口の開閉速度、まばたき、待機モーション、脈動、元のオーブの表示量を調整できます。
- 口形は音量に追従する方式で、音素単位のリップシンクではありません。

VoiceスタイルはChatGPT内部のrendererに依存するため、Codex / ChatGPTの更新後に調整が必要になる場合があります。

## 読み込みと書き出し

- 書き出しでは、テーマ設定と内蔵アセットを含む単一の`.codextheme`が作成されます。
- 読み込んだテーマは自動適用されません。内容を確認してから**適用**してください。
- Image SkinはPNG、JPEG、WebP、GIF、AVIFに対応しています。
- 上限：1アセット16 MB、全アセット合計32 MB、1つの`.codextheme`は48 MB。

例：[`minimal.codextheme`](Examples/minimal.codextheme)と[`full.codextheme`](Examples/full.codextheme)。

## AI Agentでデザインする

Appをインストールした後、AI agentに次のプロンプトを渡してください。

```text
このAgent CLIを使ってCodexテーマをデザインしてください：
/Applications/CodexThemeSwitcher.app/Contents/Helpers/codex-theme

最初にcapabilitiesとschemaを実行し、validate、compile、4枚のプレビューを完了してください。
私が確認するまでテーマを適用しないでください。
```

CLIはテーマの作成、検証、コンパイル、読み込み、書き出しと、ライト／ダーク × ホーム／チャットのプレビュー生成に対応します。Codexを変更するのは、明示的な`attach`、`apply`、`clear`コマンドだけです。

コマンドの詳細は[`docs/AGENT_API.md`](docs/AGENT_API.md)を参照してください。

## 言語とアップデート

- AppはmacOSの言語に自動的に従い、未対応の言語では英語を使用します。
- **設定 → インターフェース言語**で言語を手動選択できます。
- 設定でStableまたはBetaの更新チャンネルを選択できます。
- Sparkleを使用し、Apple SiliconまたはIntelに合った更新を提供します。

## 安全性と復元

- Theme Switcherは`app.asar`を変更せず、Codex / ChatGPTのファイルを置換しません。
- テーマデータと接続bridgeはローカルMac内に保持されます。
- 読み込んだテーマはJavaScriptを実行できず、リモートURLやローカルファイルURLも読み込めません。
- カスタムCSSでCodexが読めなくなった場合は、メニューバーAppから**Codexの元のスタイルを復元**を選択してください。
- Codexを終了し、通常の方法で開き直すと、一時的に注入されたスタイルは削除されます。

このプロジェクトは独立したもので、OpenAIとの提携や承認関係はありません。

## ソースからビルド

必要環境：macOS 13以降、Swift 6、Node.js 22以降、Codex / ChatGPTデスクトップApp。

```sh
swift build
swift test
npm test
scripts/package-app.sh
open dist/CodexThemeSwitcher.app
```

開発者向け資料：

- [Agent CLI](docs/AGENT_API.md)
- [アップデート、署名、公証、リリース](docs/UPDATES.md)
