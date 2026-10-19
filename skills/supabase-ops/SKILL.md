---
name: supabase-ops
description: Supabase を操作するときの手順。Management API で SQL を実行する、migration を作る・適用する、RLS ポリシーを作る、本番 DB に UPDATE/DELETE する、新しい Supabase プロジェクトを作る、auth config を変える、などの場面で使う。
---

# Supabase の操作

## Management API

- トークンは `~/.config/supabase_token`（chmod 600）。本体をチャットや commit message に貼らない
- 読み取り系は即実行してよい
- **DDL・本番データの変更は必ず git に migration を残す。順序：migration SQL 作成 → git commit + push → API 実行（逆順禁止）**

```bash
TOKEN=$(cat ~/.config/supabase_token)
# プロジェクト一覧
curl -s "https://api.supabase.com/v1/projects" -H "Authorization: Bearer $TOKEN"
# SQL 実行
curl -s "https://api.supabase.com/v1/projects/<REF>/database/query" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"query":"select ..."}'
```

- **auth config（セッション・OTP 有効期限・レート制限・匿名ログインなど）を変えるとき**：画面でも API でもよい（使えるなら画面を優先）。どちらでも次の4つを守る
  1. 変える前の設定を保存する（API なら `GET https://api.supabase.com/v1/projects/<REF>/config/auth` の結果をローカルに JSON で保存）
  2. 1回に変えるのは1項目だけ（API なら PATCH の本文にその項目だけを入れる）。承認を得てから。利用の少ない時間に
  3. 変えた直後に `https://<REF>.supabase.co/auth/v1/health` が 200 を返すか（`apikey` ヘッダーに publishable key を付ける。付けないと 401）、実際にログインできるかを確かめる。あわせて変更後の設定を取り直し、保存した値と全項目を比べる（プランで決まる上限値が一緒に変わることがある。2026-10-19 neo-relay で `custom_oauth_max_providers` が 3 → 32767 に。Pro プランの「無制限」に合わせて計算し直されたと見られ、問題なし）
  4. だめなら、保存した値にすぐ戻す
  - 教訓：2026-08-20 yscc-ticket で `sessions_inactivity_timeout` / `mailer_otp_exp` を API で変えたら GoTrue が起動せず、認証 API が全部 503。ログインもチケット購入も約1時間50分停止。変更後に本番を確認しなかったため気づくのが遅れた

## 本番 DB への書き込み

1. UPDATE / DELETE の前に、対象レコードの SELECT 結果をローカルに JSON で保存する
2. 更新するカラムは必要最小限
3. 一括更新は「1件テスト → 確認 → 全件」の3ステップ
4. クライアントが手で入力したデータは絶対に上書きしない
5. 実行前に「何を変更し、何を変更しないか」を宣言する

- 教訓：2026-05-09 蒲原水産の本番データの事故から

## RLS

- 新規テーブルは CRUD 4ポリシーを同時に定義する。不要なものはコメントで「禁止」と明記
- update / delete は `.select()` をつないで更新行数を確認する（RLS 違反は何も言わずに失敗する）
- コミット前に `pg_policies` で対応するポリシーがあるか確認する
- **仕組みで担保済み**（2026-10-07〜）：全 Supabase プロジェクトに event trigger `ensure_rls` を導入済み＝新規テーブルは作成時に自動で RLS 有効。
  GitHub `hideaki0320/supabase-security-guard` が毎日 08:00 JST に全プロジェクトを点検し、ERROR / ensure_rls 未導入を Issue で通知する
- **新しい Supabase プロジェクトを作ったら最初に** `supabase-security-guard/sql/ensure_rls.sql` を実行する
- 教訓：2026-10-03 bingoya-gogyou の申込テーブル（氏名・電話・住所）が RLS 無効で公開状態だった。CREATE TABLE に RLS を書き忘れた

## その他

- 環境変数名は `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`（ANON_KEY ではない）
- SQL を中森さんに実行してもらうときは全文を貼り、「▶ <プロジェクト名> の SQL Editor で実行」と書く
- プロジェクトの URL はプロジェクト名から推測しない（ランダムな文字列）。ダッシュボードか API で確かめる
