# Codex Theme Switcher 0.2.9-beta.2

## 더욱 안정적인 Codex 연결

- 기본 bridge port가 사용 중이면 다음으로 사용 가능한 loopback port를 자동 선택하여 Theme Switcher와 Codex의 통신이 끊기는 문제를 방지합니다.
- Theme Switcher 데이터 디렉터리별로 선택한 bridge port를 저장하여 이후 명령도 일관되게 다시 연결할 수 있습니다.
- 명시적으로 설정한 port는 계속 엄격하게 처리하며, 충돌 시 다른 port로 조용히 이동하지 않고 오류를 보고합니다.
- Bridge port 회귀 테스트를 추가하고 7개 언어의 README 모두에 새로운 테마 홍보 이미지를 넣었습니다.
