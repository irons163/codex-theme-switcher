# Codex Theme Switcher

[English](README.en.md) | [繁體中文](README.md) | [简体中文](README.zh-Hans.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | **한국어**

네이티브 macOS menu bar 테마 스튜디오입니다. 일반 메인 창을 만들지 않고 Dock에도
표시되지 않습니다. 또한 `Codex.app` / `ChatGPT.app`을 수정하거나 다시 서명하거나
덮어쓰지 않습니다.

Theme Switcher는 Chromium DevTools Protocol(CDP)로 Codex renderer에 연결하고,
컴파일된 CSS를 namespaced `<style>`에 기록합니다. 테마 전환은 모든 Codex 창에
즉시 동기화되며, Codex를 reload하거나 새 창을 연 뒤에도 runtime이 테마를 자동으로
다시 적용합니다.

## 스크린샷

### Menu bar 테마 스튜디오

![테마 라이브러리, 실시간 미리보기, 전체 편집 탭을 보여 주는 Codex Theme Switcher 테마 스튜디오](docs/images/theme-studio.png)

### Agent renderer 미리보기

| Paper · Light / Home | Midnight · Dark / Chat |
| --- | --- |
| ![Paper Light Home 미리보기](docs/images/paper-light-home.png) | ![Midnight Dark Chat 미리보기](docs/images/midnight-dark-chat.png) |

Agent CLI는 창이 없는 환경에서 Light／Dark × Home／Chat PNG를 생성하여 AI agent가
반복해서 확인할 수 있게 합니다. 이는 구조화된 근사 미리보기입니다. selector rules,
raw CSS, 실제 Codex renderer의 최종 결과는 적용 후에도 확인해야 합니다.

## 기능

- Menu bar 전용 app. 테마 라이브러리, 편집, 미리보기, runtime 상태를 모두
  menu bar panel에서 제공합니다.
- 세 가지 내장 템플릿: Midnight, Paper, High Contrast.
- 원클릭 적용, Codex 원래 스타일 복원, renderer 다시 연결.
- 시각적 색상 시스템:
  - 기본 semantic colors.
  - Codex `--color-token-*` 인터페이스, interaction, diff, terminal tokens.
- 글꼴, 글꼴 크기, 줄 높이, 콘텐츠 너비, 간격, 모서리 반경, 그림자, 흐림,
  크기 조절, 애니메이션.
- 배경과 유리(Image Skin): Light／Dark 개별 배경, Fit / Fill 등 일곱 가지 크기 모드,
  초점 크롭, 전체 창을 대상으로 하거나 왼쪽 사이드바를 제외할 수 있는 wallpaper canvas,
  필터, overlay, 영역별 glass, 중앙 콘텐츠 패널.
- 임의의 component declarations.
- 임의의 CSS selector rules.
- 완전한 raw CSS escape hatch.
- 여러 layer와 light / dark / custom media query.
- PNG, JPEG, WebP, GIF, 글꼴 등의 asset을 템플릿에 포함할 수 있습니다. runtime은
  이를 분할 전송하고 renderer-local Blob URL을 생성하므로 큰 4K 이미지도
  CSS declaration 길이 제한에 걸리지 않습니다.
- 단일 `.codextheme` 파일 가져오기／내보내기로 간편하게 공유.
- macOS 기본 언어에 따라 영어, 번체 중국어, 간체 중국어, 프랑스어, 스페인어,
  일본어, 한국어를 자동 전환하며, 그 밖의 언어는 영어로 대체.
- Sparkle 2 자동 업데이트: Stable／Beta 채널을 선택하고 Apple Silicon／Intel에
  맞는 설치 파일을 받으며, 동일한 7개 언어의 릴리스 노트를 표시.
- 시작할 때 업데이트를 확인하고 이후 30분마다 다시 확인. 설정이나 오른쪽 위 메뉴에서
  수동으로 확인하거나, 특정 버전을 건너뛰거나, 수동 다운로드로 전환할 수도 있습니다.
- JSON-first `codex-theme` agent CLI 내장. AI agent가 schema／예제를 가져오고,
  검증, 정규화, 컴파일, 설치, 내보내기를 수행하며 Light／Dark × Home／Chat PNG
  미리보기를 생성할 수 있습니다. Codex를 변경하는 것은 `attach`, `apply`, `clear`를
  명시적으로 호출했을 때뿐입니다.

## 배경과 유리 / Image Skin

Image Skin을 사용하면 색상표만 바꾸는 데 그치지 않고 Codex를 완전한 이미지 테마로
만들 수 있습니다.

- Light / Dark에 서로 다른 배경 이미지를 선택하거나, 같은 이미지를 공유하면서
  서로 다른 효과를 적용할 수 있습니다.
- 배경은 Fit(전체 표시), Fill(비율을 유지해 채우고 크롭), Stretch, Fit Width,
  Fit Height, Original, Tile을 지원합니다. 모든 모드에 초점／시작점, 확대／축소,
  불투명도, 밝기, 대비, 채도, 흐림 필터를 조합할 수 있습니다.
- “Wallpaper를 사이드바에서 제외”하면 이미지, Fit / Fill, 초점, overlay, scrim,
  vignette 전체를 메인 콘텐츠 영역에 맞춰 다시 배치합니다. 사이드바는 자체 배경색과
  glass를 유지합니다. 사이드바 너비를 드래그하여 바꾸거나 접으면 wallpaper 경계도
  실제 Codex layout에 맞춰 자동으로 조정됩니다.
- Overlay에 단색 scrim, 선형 그라데이션, vignette를 사용하여 복잡한 이미지 위에서도
  사이드바, 제목, 입력 영역을 선명하게 유지할 수 있습니다.
- Sidebar, main content, composer, card, menu, popover, code block별로 glass fill,
  불투명도, backdrop blur, 테두리, 모서리 반경, 그림자를 설정할 수 있습니다.
  panel 불투명도를 조절해도 텍스트까지 흐려지지 않습니다.
- “중앙 콘텐츠 패널”은 Home Hero 또는 Chat 대화 기록만 별도로 감싸며 추천 Cards와
  Composer는 포함하지 않습니다. Light / Dark별로 배경색, 테두리, 그림자 색,
  불투명도를 설정할 수 있고, 재질에는 blur, saturation, 테두리 너비, 모서리 반경,
  그림자 오프셋／확산, 최대 너비, 가로／세로 padding을 설정할 수 있습니다.
- 미리보기에서 Light / Dark와 Home / Chat을 전환하여 배경 크롭, 텍스트 대비,
  컴포넌트 표면을 함께 확인할 수 있습니다.
- Image Skin 배경은 `.codextheme`에 포함됩니다. 내보낸 뒤에는 원본 파일 경로에
  의존하지 않으므로 템플릿을 받은 사람이 바로 가져와 사용할 수 있습니다.

시각적 컨트롤은 이식 가능한 theme variables와 component overrides를 생성합니다.
더 세밀한 selector, 여러 그라데이션, blend mode, 애니메이션이 필요하면 마지막에
Raw CSS로 덮어쓸 수 있습니다. Raw CSS는 theme cascade에서 가장 높은 자유도를
유지합니다.

Image Skin 이미지 필드는 raster asset(PNG, JPEG, WebP, GIF, AVIF)만 허용하며
asset 하나당 최대 16 MB입니다. 모든 asset의 합계는 최대 32 MB, 단일 `.codextheme`은
최대 48 MB입니다. 글꼴은 고급 asset 기능으로 계속 포함할 수 있지만 Image Skin
배경으로 지정할 수는 없습니다.

## 사용 흐름

1. app을 열고 macOS menu bar의 팔레트 아이콘에서 테마 스튜디오로 들어갑니다.
2. “Codex 시작 및 연결”을 누릅니다. 처음 연결할 때 Codex가 다시 시작될 수 있습니다.
   첫 연결에서는 미리 선택된 템플릿을 자동 적용하지 않습니다. 이후 다시 연결할 때는
   runtime에 저장된 마지막 적용 성공 스냅샷을 복원하며, 그 뒤 저장만 했거나 아직
   초안 상태인 변경은 포함하지 않습니다.
3. 내장 템플릿을 바로 적용하거나 먼저 “편집 가능한 사본 만들기”를 선택합니다.
   왼쪽 아래에서 빈 테마를 새로 만들 수도 있습니다.
4. 배경과 유리, 색상, 글꼴과 레이아웃, 컴포넌트, 규칙, 고급 CSS, asset, 정보 탭에서
   편집합니다. 주황색 점은 해당 테마에 저장하지 않은 변경이 있음을 나타냅니다.
   다른 테마로 전환했다 돌아와도 초안은 사라지지 않습니다.
5. 저장한 뒤 적용합니다. 공유하려면 내보내기를 눌러 모든 내장 asset을 포함한 단일
   `.codextheme` 파일을 만듭니다. 템플릿을 받은 사람은 같은 위치에서 가져올 수 있습니다.
6. “설정” 탭에서 자동 업데이트를 켜거나 끄고, Stable／Beta를 선택하고, 새 버전을
   확인하고, 현재 버전의 “새로운 기능”을 다시 표시할 수 있습니다.

## 보안 모델

- `app.asar`를 patch하지 않아 OpenAI app의 서명, notarization, ASAR integrity를 유지.
- Theme Switcher bridge는 `127.0.0.1`에서만 수신 대기하며 비공개
  256-bit bearer token을 사용합니다.
- `.codextheme`은 JavaScript를 허용하지 않습니다.
- 가져오기와 컴파일은 `@import`, `http:`, `https:`, protocol-relative,
  `file:` URL을 거부.
- Asset은 템플릿 안에 포함됩니다. 가져올 때 ZIP을 풀지 않으므로
  path traversal / zip-slip이 없습니다.
- Image Skin 배경은 raster image만 허용합니다. 각 내장 asset의 형식, base64 데이터,
  16 MB 용량 제한을 가져올 때 검증합니다.
- Runtime과 style ID 모두 `codex-theme-switcher` namespace를 사용하며 다른
  주입 도구를 지우지 않습니다.
- Menu bar에는 항상 “Codex 원래 스타일 복원”이 있어 사용자 지정 CSS로 화면이
  깨져도 복구할 수 있습니다.
- Agent CLI는 기본값이 아닌 `--root`에서 `attach`, `apply`, `clear`를 실행하는 것을
  명시적으로 금지합니다. custom root는 격리 repository와 오프라인 작업 전용이며
  실제 Codex runtime의 sandbox로 사용할 수 없습니다.
- Chromium의 CDP debug endpoint도 명시적으로 `127.0.0.1`에 바인딩되지만 CDP 자체에는
  bearer-token 인증이 없습니다. 같은 Mac의 다른 로컬 프로세스도 연결할 수 있습니다.
  테마 기능을 더 이상 사용하지 않는다면 Codex를 종료하고 일반 방식으로 다시 열어
  remote-debugging 인자가 붙지 않게 하십시오.

## 빌드

요구 사항:

- macOS 13+
- Swift 6 toolchain
- Codex desktop app(현재 unified app은 `/Applications/ChatGPT.app`에 있을 수도 있음)
- Node.js 22+. 프로그램은 Codex app에 내장된
  `Contents/Resources/cua_node/bin/node`를 우선 사용한 뒤 PATH / Homebrew Node를
  검색합니다.

```sh
swift build
swift test
npm test
npm run check
swift run CodexThemeSwitcher
swift run codex-theme capabilities
```

더블클릭 가능한 menu bar `.app` 만들기:

```sh
scripts/package-app.sh
open dist/CodexThemeSwitcher.app
```

출력되는 `Info.plist`에는 `LSUIElement=true`가 포함되어 app이 Dock이나 일반
app switcher에 나타나지 않습니다. Agent CLI는
`CodexThemeSwitcher.app/Contents/Helpers/codex-theme`에, JSON Schema는
`Contents/Resources/Schemas/`에 패키징됩니다. 전체 프로토콜과 예제는
[`docs/AGENT_API.md`](docs/AGENT_API.md)를 참조하십시오. signing identity를
제공하지 않으면 script가 ad-hoc signing을 사용합니다. 정식 배포에서는 다음과 같이
설정할 수 있습니다.

```sh
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
SPARKLE_PUBLIC_ED_KEY="<base64 Ed25519 public key>" \
  scripts/package-app.sh
```

정식 패키징에는 Sparkle EdDSA 공개 키가 반드시 필요합니다. script는 이를
`SUPublicEDKey`에 기록하고 모든 `SUAllowsInsecureUpdates` 설정을 거부합니다.
local-only insecure allowance는 로컬 ad-hoc 개발 빌드에만 추가되며 정식 배포에는
사용할 수 없습니다.

## App 업데이트 및 배포

- Stable feed:
  `appcast-arm64.xml`, `appcast-x86_64.xml`
- Beta feed:
  `appcast-beta-arm64.xml`, `appcast-beta-x86_64.xml`
- 업데이트 feed는 GitHub의 최신 Stable Release에 고정됩니다. Beta release는 그 안의
  `appcast-beta-*`만 덮어쓰므로 GitHub가 prerelease를 무시해도 고정 URL이
  무효화되지 않습니다.
- 각 appcast enclosure에는 `sparkle:edSignature`가 반드시 있어야 하며, 정식 App에도
  해당 `SUPublicEDKey`가 포함되어야 합니다.
- 7개 언어의 릴리스 노트는
  `docs/release-notes/v<version>/release-notes.<language>.md`에 둡니다.

전체 secrets, 서명, notarization, release 절차는
[`docs/UPDATES.md`](docs/UPDATES.md)를 참조하십시오.

## 첫 연결

일반적으로 실행한 Codex는 CDP port를 열지 않습니다. 처음 “Codex 시작 및 연결”을
눌렀을 때 공유할 수 있는 Codex debug target이 없다면 Theme Switcher가 먼저 정상적으로
Codex 종료를 요청한 뒤 다음 인자로 다시 실행합니다.

```text
--remote-debugging-address=127.0.0.1
--remote-debugging-port=57340
--remote-allow-origins=http://127.0.0.1:57340
```

`codex-desktop-switcher`가 57330–57341 사이에 Codex target을 만들어 둔 경우,
이 프로그램은 이를 우선 공유하며 Codex를 다시 시작하지 않습니다.

## `.codextheme` 형식

`.codextheme`은 버전이 지정된 단일 JSON envelope입니다.

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

바로 가져올 수 있는 파일은
[`Examples/minimal.codextheme`](Examples/minimal.codextheme)와
[`Examples/full.codextheme`](Examples/full.codextheme)입니다. Agent는
[`codextheme.schema.json`](Sources/CodexThemeAgentCLI/Resources/codextheme.schema.json)을
사용해 JSON을 생성하고 검사할 수 있습니다. 날짜는 항상 ISO-8601로 출력되며 가져오기는
이전 Foundation의 numeric dates와도 호환됩니다. JSON Schema 역시 두 날짜 입력 형식을
모두 허용하고 구조, enum, 숫자 범위를 빠르게 검사합니다. Core validator는 계속해서
CSS 보안 검사와 전체 용량 제한의 최종 기준입니다.

Theme cascade 순서는 다음과 같이 고정됩니다.

1. semantic variables 및 Codex stable-token aliases
2. advanced/custom variables
3. component overrides
4. selector rules
5. Image Skin이 생성하는 배경, 색상표, glass rules
6. raw CSS

1–4번 항목은 layer 순서에 따라 컴파일됩니다. 그다음 Image Skin이 구조화된 인터페이스
설정을 덮어쓰고, 마지막으로 layer 순서에 따라 raw CSS가 출력되므로 Raw CSS가 실제
최종 escape hatch입니다. 가져올 때 ID가 충돌하면 기본적으로 새 UUID로 clone하며
자동으로 적용하지 않습니다.

CSS에서 내장 asset 사용:

```css
body {
  background-image: theme-asset("ASSET-UUID");
}
```

컴파일할 때 안전한 짧은 `codex-theme-asset://` placeholder로 다시 작성됩니다.
Runtime은 asset을 256 KiB 블록으로 각 renderer에 보내고, renderer 안에서 Blob URL을
생성한 후에만 style을 원자적으로 전환합니다. 같은 asset은 Blob을 재사용하며 테마를
전환하거나 지울 때 더 이상 사용하지 않는 URL도 폐기합니다.

## 로컬 데이터

```text
~/Library/Application Support/CodexThemeSwitcher/
  Themes/                 # user theme JSON
  active-theme.json       # repository active pointer
  Runtime/
    active-theme.json     # runtime CSS template、asset manifest 與資料
    bridge-token          # mode 0600
  Logs/runtime.log
```

## 아키텍처

- `CodexThemeSwitcherCore`: theme schema, validator, compiler, repository, archive.
- `CodexThemeRuntime`: async Swift runner 및 authenticated Node/CDP runtime.
- `CodexThemeSwitcher`: AppKit/SwiftUI menu bar studio.
- `codex-theme`: AI agent와 자동화를 위한 구조화된 JSON CLI 및 창 없는 PNG renderer.
- `Tests/`: Swift test suites.
- `test/`: Node runtime test suites.

Selector rules는 전문가용 layer이므로 Codex 업데이트 후 조정이 필요할 수 있습니다.
기본 layer와 `--color-token-*` layers는 현재 Codex 자체의 CSS contract를 우선
사용하므로 React class names에 대한 의존도가 더 낮습니다.
