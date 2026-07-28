# Codex Theme Switcher

[English](README.en.md) | [繁體中文](README.md) | [简体中文](README.zh-Hans.md) | [Français](README.fr.md) | [Español](README.es.md) | **日本語** | [한국어](README.ko.md)

![Codex Theme Switcher で画像背景、ガラス効果、カスタムコンポーネントを適用した実際の Codex 画面](docs/images/codex-theme-showcase.jpg)

ネイティブの macOS menu bar テーマスタジオです。通常のメインウィンドウを作成せず、
Dock にも表示されません。また、`Codex.app` / `ChatGPT.app` の変更、再署名、
上書きも行いません。

Theme Switcher は Chromium DevTools Protocol（CDP）で Codex renderer に接続し、
コンパイル済みの CSS を namespaced `<style>` に書き込みます。テーマの切り替えは
すべての Codex ウィンドウへ即座に同期され、Codex の reload 後や新しいウィンドウを
開いた後も、runtime が自動的にテーマを再適用します。

## スクリーンショット

### Menu bar テーマスタジオ

![テーマライブラリ、ライブプレビュー、すべての編集タブを表示する Codex Theme Switcher テーマスタジオ](docs/images/theme-studio.png)

### Agent renderer プレビュー

| Paper · Light / Home | Midnight · Dark / Chat |
| --- | --- |
| ![Paper の Light Home プレビュー](docs/images/paper-light-home.png) | ![Midnight の Dark Chat プレビュー](docs/images/midnight-dark-chat.png) |

Agent CLI はウィンドウのない環境で Light／Dark × Home／Chat PNG を生成でき、
AI agent が繰り返し確認するために利用できます。これらは構造化された近似プレビューです。
selector rules、raw CSS、および実際の Codex renderer における最終結果は、適用後にも
確認してください。

## 機能

- Menu bar 専用 app。テーマライブラリ、編集、プレビュー、runtime ステータスの
  すべてを menu bar panel に集約。
- 3 つの組み込みテンプレート：Midnight、Paper、High Contrast。
- ワンクリックでの適用、Codex の元のスタイルへの復元、renderer の再接続。
- ビジュアルカラーシステム：
  - 基本 semantic colors。
  - Codex `--color-token-*` インターフェース、interaction、diff、terminal tokens。
- フォント、フォントサイズ、行間、コンテンツ幅、余白、角丸、シャドウ、ぼかし、
  スケール、アニメーション。
- 背景とガラス（Image Skin）：Light／Dark 個別の背景、Fit / Fill など 7 種類の
  サイズモード、焦点クロップ、ウィンドウ全体を対象にするか左サイドバーを除外できる
  wallpaper canvas、フィルター、overlay、領域別 glass、中央コンテンツパネル。
- 任意の component declarations。
- 任意の CSS selector rules。
- 完全な raw CSS escape hatch。
- 複数 layer と light / dark / custom media query。
- PNG、JPEG、WebP、GIF、フォントなどのアセットをテンプレートへ埋め込み可能。
  runtime は分割転送して renderer-local Blob URL を作成するため、大きな 4K 画像でも
  CSS declaration の長さ制限に抵触しません。
- 単一ファイルの `.codextheme` インポート／エクスポートで簡単に共有。
- macOS の優先言語に従って英語、繁体字中国語、簡体字中国語、フランス語、
  スペイン語、日本語、韓国語を自動切り替え。その他の言語では英語へフォールバック。
- Sparkle 2 自動アップデート：Stable／Beta チャンネルを選択でき、Apple Silicon／
  Intel に対応するインストーラーを取得し、同じ 7 言語のリリースノートを表示。
- 起動時にアップデートを確認し、その後は 30 分ごとに確認。設定または右上のメニューから
  手動で確認したり、特定バージョンをスキップしたり、手動ダウンロードへ切り替えたり
  することも可能。
- JSON-first の `codex-theme` agent CLI を同梱。AI agent は schema／サンプルの取得、
  検証、正規化、コンパイル、インストール、エクスポート、および
  Light／Dark × Home／Chat PNG プレビューの生成が可能。Codex を変更するのは、
  明示的に `attach`、`apply`、`clear` を呼び出した場合のみ。

## 背景とガラス / Image Skin

Image Skin を使用すると、単にカラーパレットを置き換えるだけでなく、Codex を完全な
画像テーマにできます。

- Light / Dark で別々の背景画像を選択でき、同じ画像を共有して異なる効果を
  適用することも可能。
- 背景は Fit（全体表示）、Fill（アスペクト比を維持し、領域を埋めるようにクロップ）、
  Stretch、
  Fit Width、Fit Height、Original、Tile に対応。各モードで焦点／起点、ズーム、
  不透明度、明るさ、コントラスト、彩度、ぼかしフィルターを組み合わせ可能。
- 「Wallpaper をサイドバーから除外」は、画像、Fit / Fill、焦点、overlay、scrim、
  vignette の一式をメインコンテンツ領域に合わせて再レイアウトします。サイドバーは
  独自の背景色と glass を維持します。サイドバーの幅をドラッグして変更した場合や
  折りたたんだ場合も、wallpaper の境界が実際の Codex layout に自動追従します。
- Overlay には単色 scrim、線形グラデーション、vignette を使用でき、複雑な画像上でも
  サイドバー、タイトル、入力領域を明瞭に保てます。
- Sidebar、main content、composer、card、menu、popover、code block ごとに、
  glass fill、不透明度、backdrop blur、境界線、角丸、シャドウを設定可能。
  panel の不透明度を変更してもテキストまで薄くなりません。
- 「中央コンテンツパネル」は Home Hero または Chat の会話履歴だけを独立して囲み、
  提案 Cards と Composer は含みません。Light / Dark ごとに背景色、境界線、
  シャドウ色、不透明度を設定でき、マテリアルでは blur、saturation、境界線の幅、角丸、
  シャドウのオフセット／拡散、最大幅、水平／垂直 padding を設定できます。
- プレビューは Light / Dark と Home / Chat を切り替えられ、背景のクロップ、
  テキストのコントラスト、コンポーネント表面を同時に確認可能。
- Image Skin の背景は `.codextheme` に埋め込まれます。エクスポート後は元ファイルの
  パスに依存せず、テンプレートを受け取った人がそのままインポートして使用できます。

ビジュアルコントロールは、持ち運び可能な theme variables と component overrides を
生成します。さらに細かな selector、複数グラデーション、blend mode、アニメーションが
必要な場合は、最後に Raw CSS で上書きできます。Raw CSS は theme cascade における
最高の自由度を維持します。

Image Skin の画像フィールドは raster asset（PNG、JPEG、WebP、GIF、AVIF）のみを
受け付け、asset ごとの上限は 16 MB です。全アセットの合計上限は 32 MB、単一の
`.codextheme` の上限は 48 MB です。フォントは引き続き高度なアセット機能で
埋め込めますが、Image Skin の背景には指定できません。

## 使用手順

1. app を開き、macOS menu bar のパレットアイコンからテーマスタジオに入ります。
2. 「Codex を起動して接続」を押します。初回接続時は Codex が再起動されることが
   あります。初回接続では事前選択されたテンプレートを自動適用しません。それ以降の
   再接続では、runtime が保存した最後の適用成功スナップショットを復元します。
   その後に保存しただけの変更や、まだ下書きの変更は含まれません。
3. 組み込みテンプレートを直接適用するか、先に「編集可能なコピーを作成」を選択します。
   左下から空のテーマを新規作成することもできます。
4. 背景とガラス、カラー、フォントとレイアウト、コンポーネント、ルール、高度な CSS、
   アセット、情報の各タブで編集します。オレンジ色の点は、そのテーマに未保存の変更が
   あることを示します。別のテーマへ切り替えて戻っても下書きは失われません。
5. 保存してから適用します。共有する場合はエクスポートを押すと、すべての埋め込み
   アセットを含む単一の `.codextheme` が生成されます。受け取った人は同じ場所から
   テンプレートをインポートできます。
6. 「設定」タブでは、自動アップデートの有効／無効、Stable／Beta の選択、新しい
   バージョンの確認、現在のバージョンの「新機能」の再表示ができます。

## セキュリティモデル

- `app.asar` を patch せず、OpenAI app の署名、notarization、ASAR integrity を維持。
- Theme Switcher bridge は `127.0.0.1` のみでリッスンし、非公開の
  256-bit bearer token を使用。
- `.codextheme` は JavaScript を許可しません。
- インポートとコンパイルでは `@import`、`http:`、`https:`、protocol-relative、
  `file:` URL を拒否。
- アセットはテンプレート内に埋め込まれます。インポート時に ZIP を展開しないため、
  path traversal / zip-slip はありません。
- Image Skin の背景は raster image のみを受け付けます。埋め込み asset ごとに、
  インポート時に形式、base64 データ、16 MB の容量上限を検証。
- Runtime と style ID はどちらも `codex-theme-switcher` namespace を使用し、
  他のインジェクションツールを消去しません。
- Menu bar には常に「Codex の元のスタイルに戻す」があり、カスタム CSS で画面が
  壊れた場合も復旧可能。
- Agent CLI はデフォルト以外の `--root` での `attach`、`apply`、`clear` 実行を
  明示的に禁止。custom root は隔離 repository とオフライン作業専用で、実際の
  Codex runtime の sandbox としては使用できません。
- Chromium の CDP debug endpoint も明示的に `127.0.0.1` へバインドされますが、
  CDP 自体には bearer-token 認証がありません。同じ Mac 上の別のローカルプロセスも
  接続できる可能性があります。テーマ機能を使用しなくなった場合は、Codex を終了して
  通常の方法で再度開き、remote-debugging 引数が付かない状態にしてください。

## ビルド

要件：

- macOS 13+
- Swift 6 toolchain
- Codex desktop app（現在の unified app は `/Applications/ChatGPT.app` に
  置かれている場合もあります）
- Node.js 22+。プログラムは Codex app 内蔵の
  `Contents/Resources/cua_node/bin/node` を優先し、その後 PATH / Homebrew Node を検索

```sh
swift build
swift test
npm test
npm run check
swift run CodexThemeSwitcher
swift run codex-theme capabilities
```

ダブルクリック可能な menu bar `.app` を作成：

```sh
scripts/package-app.sh
open dist/CodexThemeSwitcher.app
```

出力される `Info.plist` には `LSUIElement=true` が含まれるため、app は Dock や通常の
app switcher に表示されません。Agent CLI は
`CodexThemeSwitcher.app/Contents/Helpers/codex-theme` に、JSON Schema は
`Contents/Resources/Schemas/` にパッケージされます。完全なプロトコルとサンプルは
[`docs/AGENT_API.md`](docs/AGENT_API.md) を参照してください。signing identity が
指定されていない場合、script は ad-hoc signing を使用します。正式配布では次のように
設定できます。

```sh
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
SPARKLE_PUBLIC_ED_KEY="<base64 Ed25519 public key>" \
  scripts/package-app.sh
```

正式なパッケージには Sparkle EdDSA 公開鍵が必須です。script はそれを
`SUPublicEDKey` に書き込み、`SUAllowsInsecureUpdates` の設定をすべて拒否します。
local-only の insecure allowance が追加されるのはローカルの ad-hoc 開発ビルドだけで、
正式リリースには使用できません。

## App のアップデートとリリース

- Stable feed：
  `appcast-arm64.xml`、`appcast-x86_64.xml`
- Beta feed：
  `appcast-beta-arm64.xml`、`appcast-beta-x86_64.xml`
- 更新 feed は GitHub の最新 Stable Release に固定。Beta release はその中の
  `appcast-beta-*` だけを上書きするため、GitHub が prerelease を無視しても固定 URL は
  無効になりません。
- 各 appcast enclosure には `sparkle:edSignature` が必須で、正式 App にも対応する
  `SUPublicEDKey` を含める必要があります。
- 7 言語のリリースノートは
  `docs/release-notes/v<version>/release-notes.<language>.md` に配置。

完全な secrets、署名、notarization、release 手順については
[`docs/UPDATES.md`](docs/UPDATES.md) を参照してください。

## 初回接続

通常起動された Codex は CDP port を開きません。初めて「Codex を起動して接続」を
押したとき、共有可能な Codex debug target がなければ、Theme Switcher はまず通常の
方法で Codex の終了を要求し、次の引数で再起動します。

```text
--remote-debugging-address=127.0.0.1
--remote-debugging-port=57340
--remote-allow-origins=http://127.0.0.1:57340
```

`codex-desktop-switcher` が 57330–57341 の間に Codex target を作成済みの場合、
このプログラムはそれを優先して共有し、Codex を再起動しません。

## `.codextheme` 形式

`.codextheme` はバージョン管理された単一の JSON envelope です。

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

直接インポートできるファイルは
[`Examples/minimal.codextheme`](Examples/minimal.codextheme) と
[`Examples/full.codextheme`](Examples/full.codextheme) です。Agent は
[`codextheme.schema.json`](Sources/CodexThemeAgentCLI/Resources/codextheme.schema.json)
を使用して JSON を生成、検証できます。日付は常に ISO-8601 で出力され、インポートは
旧版 Foundation の numeric dates とも互換性があります。JSON Schema も両方の
日付入力を受け付け、構造、enum、数値範囲をすばやく検証します。Core validator は、
引き続き CSS セキュリティスキャンと総容量制限の最終的な基準です。

Theme cascade の順序は固定されています。

1. semantic variables と Codex stable-token aliases
2. advanced/custom variables
3. component overrides
4. selector rules
5. Image Skin が生成する背景、カラーパレット、glass rules
6. raw CSS

第 1～4 項は layer の順序に従ってコンパイルされます。続いて Image Skin が構造化
インターフェースの設定を上書きし、最後に layer の順序で raw CSS を出力するため、
Raw CSS が真の最終 escape hatch です。インポート時に ID が競合した場合、デフォルトで
新しい UUID に clone され、自動適用はされません。

CSS 内で埋め込みアセットを使用する方法：

```css
body {
  background-image: theme-asset("ASSET-UUID");
}
```

コンパイル時に、安全な短い `codex-theme-asset://` placeholder へ書き換えられます。
Runtime はアセットを 256 KiB のチャンクで各 renderer へ送り、renderer 内で Blob URL
を作成してから style を原子的に切り替えます。同じアセットでは Blob を再利用し、
テーマの切り替えまたはクリア時には、使用されなくなった URL も破棄します。

## ローカルデータ

```text
~/Library/Application Support/CodexThemeSwitcher/
  Themes/                 # user theme JSON
  active-theme.json       # repository active pointer
  Runtime/
    active-theme.json     # runtime CSS template、asset manifest 與資料
    bridge-token          # mode 0600
  Logs/runtime.log
```

## アーキテクチャ

- `CodexThemeSwitcherCore`: theme schema、validator、compiler、repository、archive。
- `CodexThemeRuntime`: async Swift runner と authenticated Node/CDP runtime。
- `CodexThemeSwitcher`: AppKit/SwiftUI menu bar studio。
- `codex-theme`: AI agent と自動化向けの構造化 JSON CLI、およびウィンドウなしの
  PNG renderer。
- `Tests/`：Swift test suites。
- `test/`：Node runtime test suites。

Selector rules は上級者向け layer であり、Codex の更新後に調整が必要になる場合があります。
基本 layer と `--color-token-*` layers は現在の Codex 自身の CSS contract を優先して
使用するため、React class names への依存が比較的少なくなっています。
