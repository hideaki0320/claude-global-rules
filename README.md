# claude-global-rules

中森のグローバル開発ルール（全プロジェクト共通）の Single Source of Truth。

## 使い方

各プロジェクトの CLAUDE.md に以下を含めると、Claude が作業前にこのリポの最新ルールを読み込みます：

```
## グローバル開発ルール（必読）

中森のグローバル開発ルール（全プロジェクト共通）は以下を参照：
https://raw.githubusercontent.com/hideaki0320/claude-global-rules/main/CLAUDE.md

作業開始前に必ず WebFetch で全文取得して、内容を全部適用してください。
取得失敗時はその旨を中森に報告すること。
```

## 編集

- Mac の `~/.claude/CLAUDE.md` は `~/.claude/global-rules/CLAUDE.md` への symlink
- 編集 → commit → push すれば全 Claude セッションに反映
