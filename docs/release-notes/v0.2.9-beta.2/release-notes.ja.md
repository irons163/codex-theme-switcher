# Codex Theme Switcher 0.2.9-beta.2

## Codex 接続の信頼性を向上

- 既定の bridge port が使用中の場合、次に利用可能な loopback port を自動選択し、Theme Switcher が Codex と通信できなくなる問題を防ぎます。
- Theme Switcher のデータディレクトリごとに選択した bridge port を保存し、後続のコマンドが一貫して再接続できるようにします。
- 明示的に指定した port は引き続き厳格に扱い、競合時は別の port へ暗黙に移動せずエラーを報告します。
- Bridge port の回帰テストを追加し、7 言語すべての README に新しいテーマ紹介画像を掲載しました。
