# サブエージェント定義（Mac で作成、Web 版 Claude から参照可能）

中森さんが Mac の Claude Code で作ったサブエージェント定義を、Web 版
Claude が参照できるよう公開している。

## 使い方（Web 版 Claude）

Web 版 Claude では `Task` ツールでサブエージェントを起動できない。
代わりに：

1. 状況に応じて適切なエージェント定義を WebFetch で読み込む
   （例: UI 確認なら sanji-ui-checker.md、スキーマ確認なら robin-schema-guard.md）
2. その定義に書かれている **役割・確認観点・出力フォーマット** を
   自分のセッションで適用する
3. つまり「私がそのエージェントとして振る舞う」モード

## エージェント一覧

| ファイル | 用途 |
|---|---|
| brook-performance.md | パフォーマンス計測（Lighthouse 相当） |
| chopper-security.md | セキュリティドクター（コミット前チェック） |
| jinbe-output-reviewer.md | AI 生成アウトプット品質審査 |
| nami-subsidy-validator.md | 助成金ロジック検証（koso-navi 専用） |
| robin-schema-guard.md | DB スキーマとコードの整合性検証 |
| sanji-ui-checker.md | UI 崩れ・主要動線・レスポンシブチェック |

## 注意

- これらは Mac の `~/.claude/agents/` と同期されている
- 編集する場合は `~/.claude/agents/<name>.md` を編集し、その後
  このリポに反映する（手動コピー or 統合スクリプト）
- Mac の Claude Code は `~/.claude/agents/` を自動で読み込む
