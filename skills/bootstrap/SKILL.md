---
name: bootstrap
description: 新規プロジェクトの初期セットアップを自動化する。GitHub + Next.js + Supabase + Railway を一気に構築。「/bootstrap プロジェクト名」で起動。
---

# /bootstrap パイプライン

新規プロジェクトのインフラを一括セットアップする。

## 使い方
```
/bootstrap koso-navi
/bootstrap koso-navi --skip supabase
/bootstrap koso-navi --skip railway
```

## セットアップの流れ

### Step 1: GitHub リポジトリ作成
1. `gh repo create <name> --private --description "..."` で Private リポジトリ作成
2. リポジトリの存在確認

### Step 2: Next.js 初期化
1. ディレクトリ作成（~/アプリ開発/<name>/）
2. `npx create-next-app@latest . --typescript --tailwind --app --no-src-dir --import-alias "@/*"`
3. docs/ ディレクトリが既にあれば保護

### Step 3: .gitignore 整備
1. .env*, .DS_Store, .vscode/, .idea/ を追加
2. `.claude/` は丸ごと除外しない。次の3行にする（全体ルールのフックはリポに入れる必要があるため）
   ```
   .claude/*
   !.claude/settings.json
   !.claude/hooks/
   ```
3. 既に含まれている項目はスキップ

### Step 3.5: 全体ルールのフックを入れる（クラウドでも全体ルールとスキルを読むため）
1. `mkdir -p .claude/hooks && cp ~/.claude/global-rules/hooks/cloud-session-start.sh .claude/hooks/global-rules.sh`
2. `.claude/settings.json` に SessionStart のフックを書く（既にあれば hooks.SessionStart に追記する）
   ```json
   {
     "hooks": {
       "SessionStart": [
         {
           "hooks": [
             { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/global-rules.sh\" 1", "timeout": 30 },
             { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/global-rules.sh\" 2", "timeout": 30 }
           ]
         }
       ]
     }
   }
   ```
3. `"disableAllHooks": true` は入れない（入れるとこのフックも動かない）
4. Step 6 の初期コミットにこの2ファイルを含める

### Step 4: Supabase プロジェクト作成（--skip supabase で省略可）
1. Supabase Management API でプロジェクト作成
   ```bash
   TOKEN=$(cat ~/.config/supabase_token)
   ORG_ID=$(curl -s "https://api.supabase.com/v1/organizations" -H "Authorization: Bearer $TOKEN" | python3 -c "import sys,json; print(json.loads(sys.stdin.read())[0]['id'])")
   curl -s "https://api.supabase.com/v1/projects" \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"name":"<name>","organization_id":"'"$ORG_ID"'","plan":"free","region":"ap-northeast-1","db_pass":"'"$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)"'"}'
   ```
2. プロジェクト起動待ち（ACTIVE_HEALTHY まで）
3. API キー取得
4. lib/supabase.ts 作成（PUBLISHABLE_KEY 使用）
5. lib/types.ts 作成（空の型定義テンプレート）
6. **最初に** `supabase-security-guard/sql/ensure_rls.sql` を実行する（新規テーブルを自動で RLS 有効にする。スキル `supabase-ops`）
6. .env.local 作成（ローカル開発用）
7. .env.example 作成（テンプレート）
8. db/migrations/ ディレクトリ作成

### Step 5: Railway プロジェクト作成（--skip railway で省略可）
1. `railway init` でプロジェクト作成
2. GitHub リポジトリと連携
3. 環境変数を Railway に設定:
   - NEXT_PUBLIC_SUPABASE_URL
   - NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY
4. 初回デプロイ確認

### Step 6: git 初期コミット + push
1. git add .
2. git commit -m "Initial commit: project setup"
3. git remote add origin
4. git push -u origin main

### Step 7: 確認レポート
セットアップ完了後、以下を報告:

```
## /bootstrap 完了

| 項目 | 状態 | 詳細 |
|---|---|---|
| GitHub | ✓ | https://github.com/hideaki0320/<name> (Private) |
| Next.js | ✓ | v16.x, App Router, TypeScript, Tailwind |
| Supabase | ✓ | <name> (ap-northeast-1), ref: xxxx |
| Railway | ✓ | https://<name>.up.railway.app |
| .env.local | ✓ | ローカル環境変数設定済み |
| db/migrations/ | ✓ | ディレクトリ作成済み |

### 次のアクション
1. Supabase でテーブルを作成（db/migrations/ に SQL を書く）
2. 実装開始（/ship で自動パイプライン利用可能）
```

## 守るべきルール
- GitHub リポジトリは必ず Private
- .env ファイルをコミットしない
- Supabase の環境変数名は NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY
- Railway の環境変数設定は UI でやる方法も案内する
- 各ステップで失敗したら即報告（後続を続行しない）
