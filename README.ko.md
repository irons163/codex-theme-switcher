# Codex Theme Switcher

[English](README.md) | [繁體中文](README.zh-Hant.md) | [简体中文](README.zh-Hans.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | **한국어**

![Codex Theme Switcher로 이미지 배경, 유리 효과, 사용자 지정 컴포넌트를 적용한 Codex](docs/images/codex-theme-showcase.jpg)

Codex / ChatGPT 데스크톱 App의 테마를 디자인하고 미리 보고 적용하고 공유할 수 있는 macOS 네이티브 메뉴 막대 App입니다.

Theme Switcher는 Codex를 실행할 때 임시 스타일을 주입합니다. 원본 App을 수정하거나 교체하거나 다시 서명하지 않습니다.

## 다운로드

**현재 안정 버전: 0.3.0**

[Apple Silicon DMG](https://github.com/irons163/codex-theme-switcher/releases/download/v0.3.0/CodexThemeSwitcher-0.3.0-apple-silicon.dmg)
·
[Intel DMG](https://github.com/irons163/codex-theme-switcher/releases/download/v0.3.0/CodexThemeSwitcher-0.3.0-intel.dmg)
·
[릴리스 노트 및 체크섬](https://github.com/irons163/codex-theme-switcher/releases/tag/v0.3.0)

macOS 13 이상이 필요합니다. 두 설치 파일 모두 서명되었으며 Apple 공증을 완료했습니다.

## 주요 기능

- 메뉴 막대의 테마 라이브러리, 편집기, 실시간 미리보기 및 연결 상태.
- 색상, 글꼴, 간격, 모서리 반경, 그림자, 흐림, 배율 및 모션.
- Light／Dark 배경 이미지, Fit／Fill, 초점, 필터, 오버레이 및 유리 효과.
- 실험적인 ChatGPT Voice 배경, 오브 스타일, 애니메이션 인물, 입 모양, 눈 깜박임 및 대기 모션.
- 고급 컴포넌트 설정, selector 규칙, 사용자 지정 변수 및 raw CSS.
- 이미지와 글꼴을 포함하는 단일 `.codextheme` 파일 가져오기／내보내기.
- 영어, 번체 중국어, 간체 중국어, 프랑스어, 스페인어, 일본어 및 한국어.

## 빠른 시작

1. Codex Theme Switcher를 설치하고 연 다음 macOS 메뉴 막대의 아이콘을 클릭합니다.
2. **Codex 실행 및 연결**을 클릭합니다. 처음 연결할 때 Codex가 다시 실행될 수 있습니다.
3. 기본 제공 테마를 선택하거나, 편집 가능한 복사본 또는 새 테마를 만듭니다.
4. 디자인을 조정하고 Light／Dark 및 Home／Chat 미리보기를 확인합니다.
5. 테마를 저장한 다음 **적용**을 클릭하여 Codex에 전송합니다.
6. **내보내기**로 `.codextheme`을 공유하고 **가져오기**로 받은 테마를 설치합니다.

처음 연결할 때 선택한 테마가 자동으로 적용되지는 않습니다. 이후 연결에서는 적용하지 않은 초안이 아니라 마지막으로 적용에 성공한 테마를 복원합니다.

## 스크린샷

### 테마 스튜디오

![테마 라이브러리, 실시간 미리보기 및 편집 탭을 보여 주는 Codex Theme Switcher](docs/images/theme-studio.png)

### Renderer 미리보기

| Paper · Light / Home | Midnight · Dark / Chat |
| --- | --- |
| ![Paper Light Home 미리보기](docs/images/paper-light-home.png) | ![Midnight Dark Chat 미리보기](docs/images/midnight-dark-chat.png) |

Agent가 생성한 미리보기는 실제 화면에 가까운 근사치입니다. 테마를 공유하기 전에 실제 Codex App에서 고급 CSS와 selector 규칙을 확인하세요.

## 사용자 지정 가이드

### 배경과 유리

- Light와 Dark에 서로 다른 이미지를 사용하거나, 같은 이미지에 다른 효과를 적용할 수 있습니다.
- Fit, Fill, Stretch, Fit Width, Fit Height, Original 또는 Tile을 선택한 뒤 초점과 확대/축소를 조정할 수 있습니다.
- 이미지 불투명도와 필터를 사이드바, 콘텐츠, 입력창, 카드, 메뉴 및 코드 블록의 유리 효과와 별도로 조정할 수 있습니다.
- 배경화면을 전체 창에 표시하거나 사이드바를 제외할 수 있습니다.
- 채우기, 테두리, 그림자, 흐림, 모서리 반경, 너비 및 안쪽 여백을 따로 설정한 중앙 콘텐츠 패널을 추가할 수 있습니다.

### ChatGPT Voice(실험적)

- Voice 배경과 애니메이션 오브 안의 별도 이미지를 설정할 수 있습니다.
- 입을 다문 인물 이미지와 최대 8개의 입 모양을 추가하거나 2×2／3×3 스프라이트 시트를 가져올 수 있습니다.
- 민감도, 무음 임계값, 입 열기／닫기 속도, 눈 깜박임, 대기 모션, 펄스 및 원본 오브 표시 정도를 조정할 수 있습니다.
- 입 모양은 오디오 강도를 따르며 음소 단위 립싱크는 아닙니다.

Voice 스타일은 ChatGPT 내부 renderer에 의존하므로 Codex / ChatGPT 업데이트 후 조정이 필요할 수 있습니다.

## 가져오기 및 내보내기

- 내보내기는 테마 설정과 포함된 에셋을 하나의 `.codextheme`으로 만듭니다.
- 가져온 테마는 자동으로 적용되지 않습니다. 먼저 확인한 뒤 **적용**을 클릭하세요.
- Image Skin은 PNG, JPEG, WebP, GIF 및 AVIF를 지원합니다.
- 제한: 에셋당 16MB, 전체 에셋 32MB, `.codextheme`당 48MB.

예제: [`minimal.codextheme`](Examples/minimal.codextheme) 및 [`full.codextheme`](Examples/full.codextheme).

## AI Agent로 디자인

App을 설치한 후 AI agent에게 다음 프롬프트를 전달하세요.

```text
다음 Agent CLI를 사용해 Codex 테마를 디자인해 주세요:
/Applications/CodexThemeSwitcher.app/Contents/Helpers/codex-theme

먼저 capabilities와 schema를 실행하고 validate, compile 및 네 장의 미리보기를 완료해 주세요.
제가 확인하기 전에는 테마를 적용하지 마세요.
```

CLI는 테마 생성, 검증, 컴파일, 가져오기, 내보내기와 Light／Dark × Home／Chat 미리보기 생성을 지원합니다. 명시적인 `attach`, `apply` 또는 `clear` 명령만 Codex를 변경합니다.

명령어 전체 내용은 [`docs/AGENT_API.md`](docs/AGENT_API.md)를 참조하세요.

## 언어 및 업데이트

- App은 macOS 언어를 자동으로 따르며, 지원하지 않는 언어는 영어를 사용합니다.
- **설정 → 인터페이스 언어**에서 언어를 직접 선택할 수 있습니다.
- 설정에서 Stable 또는 Beta 업데이트 채널을 선택할 수 있습니다.
- Sparkle 업데이트를 사용하며 Apple Silicon 또는 Intel에 맞는 버전을 제공합니다.

## 안전 및 복원

- Theme Switcher는 `app.asar`를 수정하지 않으며 Codex / ChatGPT 파일을 교체하지 않습니다.
- 테마 데이터와 연결 bridge는 로컬 Mac에만 유지됩니다.
- 가져온 테마는 JavaScript를 실행하거나 원격 URL 및 로컬 파일 URL을 불러올 수 없습니다.
- 사용자 지정 CSS로 Codex를 읽을 수 없게 되면 메뉴 막대 App에서 **원본 Codex 스타일 복원**을 선택하세요.
- Codex를 종료하고 일반적인 방식으로 다시 열면 임시로 주입된 스타일이 제거됩니다.

이 프로젝트는 독립 프로젝트이며 OpenAI와 제휴하거나 OpenAI의 보증을 받지 않았습니다.

## 소스에서 빌드

요구 사항: macOS 13 이상, Swift 6, Node.js 22 이상 및 Codex / ChatGPT 데스크톱 App.

```sh
swift build
swift test
npm test
scripts/package-app.sh
open dist/CodexThemeSwitcher.app
```

개발자 문서:

- [Agent CLI](docs/AGENT_API.md)
- [업데이트, 서명, 공증 및 릴리스](docs/UPDATES.md)
