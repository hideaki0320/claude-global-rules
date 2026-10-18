# claude-global-rules

中森のグローバル開発ルール（全プロジェクト共通）の唯一の正（Single Source of Truth）。

## 構成（2026-10-18 整理）

| パス | 中身 | 読まれ方 |
|---|---|---|
| `CLAUDE.md` | 毎回守るルール（200行以内） | デスクトップ：`~/.claude/CLAUDE.md` から symlink で自動 |
| `skills/<名前>/SKILL.md` | 場面ごとの手順 | デスクトップ：`~/.claude/skills` から symlink。必要な場面で本文を読む |
| `hooks/session-start-pull.sh` | セッション開始時に GitHub から pull | `~/.claude/settings.json` の SessionStart フック |
| `notes/` | 期限つきの状況メモ（ルールではない） | 必要なときに読む |
| `agents/` | サブエージェントの定義 | `~/.claude/agents/` |
| `MIGRATION_MAP.md` | 整理前のルール番号（旧0〜47）との対応表 | 参照用 |
| `hooks/cloud-session-start.sh` | クラウドで GitHub の最新ルール・スキルを読み込む | 各リポの `.claude/hooks/global-rules.sh` に同じものを置き、リポの `.claude/settings.json` の SessionStart から呼ぶ（2026-10-18 に26リポ中25リポへ導入。intracanvas はフック無効の設定のため未導入） |
| `global.md` ＋ `.github/workflows/sync-claude-md.yml` ＋ `sync-targets.txt` | 旧方式の配布（要約版を各リポの `.claude/rules/global.md` に配る） | **2026-10-18 に停止**（Actions を無効化）。各リポの `.claude/rules/global.md` も削除済み |

## 編集

- 編集 → commit → push。次に始まるデスクトップのセッションから反映（開始時に自動 pull）
- 走っているセッションには届かない。必要なら内容を伝える
- クラウド（Claude Code on the web）は `~/.claude/` を読まない。各リポのフックが、開始時に GitHub の最新を読み込む（このリポに push すれば、次のクラウドのセッションから反映）
