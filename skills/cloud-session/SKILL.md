---
name: cloud-session
description: クラウド環境（Claude Code on the web。~/.claude/CLAUDE.md が無い環境）で作業するときの決まり。CLI・トークン・サブエージェントが無い前提での動き方、ルールの取得、ブランチの扱い。
---

# クラウド環境での作業

`ls ~/.claude/CLAUDE.md` が無ければクラウド。デスクトップとの違い：

| | デスクトップ | クラウド |
|---|---|---|
| グローバルルールの読み込み | symlink で自動 | **自動では読まれない** |
| gh / railway / supabase CLI | ある | **無い** |
| `.env` / `~/.config` のトークン | ある | **無い** |
| サブエージェント | `~/.claude/agents/` にある | **登録されていない** |
| 本番サイト・api.supabase.com への到達 | 可 | **遮断されている** |

## やること

1. 各リポの SessionStart フック（`.claude/hooks/global-rules.sh`）が、開始時にグローバルルール（前半・後半）とスキルを読み込む。**読み込めていない（「取得できませんでした」と出た、またはフックが無いリポ）ときだけ、WebFetch で全文取得する**：
   `https://raw.githubusercontent.com/hideaki0320/claude-global-rules/main/CLAUDE.md`
   取得できなければ作業前に中森へ報告する（SessionStart フックが整備済みのリポでは自動で文脈に載る）。
   スキルが要る場面では `.../main/skills/<名前>/SKILL.md` も同様に取得する
2. CLI やトークンが無くても **MCP（Supabase / GitHub / Gmail 等）は使える**。まず MCP で代替できないか確認してから「できない」と言う
3. **Railway の操作・本番サイトの表示確認・メールの実送信は経路が無い。** できないと明言し、中森が実行できる手順を渡す。確認したフリをしない
4. サブエージェントは repo の `agents/*.md` を読んで、その役割として自分が振る舞う

## ブランチ

- クライアントの確認が必要なもの → セッション指定のブランチ（確認後にマージ）
- 自社開発 → `main` に直接
- クラウドのセッション設定が指定ブランチを強制し、「main に push」のルールとぶつかったら、**勝手にどちらかを選ばず、衝突している旨を伝えて判断を仰ぐ**
