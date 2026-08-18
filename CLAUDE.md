# グローバル開発ルール（全セッション・全プロジェクト共通）

全プロジェクト・全セッションで例外なく適用。

---

## 1. UIアイコン
- 絵文字アイコンは**絶対に使わない**。必ず **Lucide React**（または Heroicons 等）の SVG を使う

## 2. コミットとプッシュは必ずセット
- 「コミットして」と言われたら `git add` → `git commit` → `git push` を**確認なしで一連実行**
- **push先は現在のブランチ（通常はmain）**。勝手にfeatureブランチを作ってそこにpushしない。ブランチを分けるのはユーザーが指示した時だけ
- 例外：main/master への force push のみ事前確認
- ルール16（サブエージェントチェック）との両立：commit → チェック → push。**push を忘れるのは禁止**

## 3. 詰まった時は即報告
- まず「詰まっています／原因の見立て／次に試す手」を報告。同じ失敗を2回繰り返したら止めて共有

## 4. 急に動かなくなったら同じ方法を繰り返さない
- 環境・依存・設定の変化を疑う。「いつから動かなくなったか」を確認

## 5. ユーザーの観察事実は疑わない
- 報告された事実を前提に別の角度から探る。同じ確認を繰り返し求めない
- 「できるはず」と言われたら `.env` / `~/.config/` / `printenv` / `find ~` まで網羅探索してから判断

## 6. .env / 環境変数
- Railway / Vercel 等のUI で設定する方法を第一案にする。.env 手動編集は求めない
- .env を提示する時はコピペ可能なコードブロックで全文出す

## 7. SQL は会話に全文貼る + 対象プロジェクト名を明記
- 「▶ bizchain800 の SQL Editor で実行」のように必ずプロジェクト名を書く

## 8. E-team ブランドアセット
- ロゴはワードマーク版（横長）、ヘッダー高さ最小 56px
- 共通 `<BrandHeader />` を使う。インラインで `<img>` を直接書かない

## 9. Supabase 環境変数名
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` ではなく `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` を使う

## 10. 本番DBへの書き込みは最大限慎重に
1. UPDATE/DELETE 前に対象レコードの SELECT 結果をローカル JSON 保存
2. 更新カラムは必要最小限
3. 一括更新は「1件テスト → 確認 → 全件」の3ステップ必須
4. クライアントが手動入力したデータは絶対に上書きしない
5. 実行前に「何を変更し、何を変更しないか」を宣言

## 11. Supabase Management API
- トークンは `~/.config/supabase_token`（chmod 600）
- 読み取り系は即実行OK。DDL/本番データ変更は必ず git に migration を残す
- 順序：migration SQL 作成 → git commit + push → API 実行（逆順禁止）
- トークン本体をチャットや commit message に貼らない

```bash
TOKEN=$(cat ~/.config/supabase_token)
# プロジェクト一覧
curl -s "https://api.supabase.com/v1/projects" -H "Authorization: Bearer $TOKEN"
# SQL 実行
curl -s "https://api.supabase.com/v1/projects/<REF>/database/query" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"query":"select ..."}'
```

## 12. スクリプト実行ルール
- 累積する副作用（git commit/push, INSERT 等）を含むスクリプトは `run_in_background: true` 禁止
- 複数リポへの書き込みは原則1ステップずつ
- 多重起動されうるスクリプトには PID lock 必須、累積する書き込みは冪等に

## 13. Railway 破壊的操作
- auto-deploy 無効化 / 全 Queue cancel 等の前に SERVING deployment ID を記録
- 「ビルドを止めたい」が目的なら service 稼働を止める操作は選ばない
- auto-deploy 無効化は「再有効化 + 手動 deploy」とセット

## 14. 外部依存ありの機能は外部設定を先に提示
- 実装前に「外部依存リスト」（SaaS 設定 / DNS / 環境変数）を提示。コードだけ書いて完成と判定しない
- メール送信は DKIM/SPF / Open/Click Tracking CNAME / Webhook / 環境変数を全部確認
- 実データで end-to-end 検証（1通テスト送信 → DB に opened_at 記録確認）
- bounced/complained メアドの自動除外ロジック未実装なら明示

## 15. Supabase RLS
- 新規テーブルは CRUD 4ポリシーを同時定義。不要なものはコメントで「禁止」と明記
- update/delete は `.select()` chain で更新行数を確認（RLS 違反は silent fail）
- コミット前に `pg_policies` で対応ポリシーがあるか確認

## 16. git push 前のサブエージェントチェック

| 変更内容 | サブエージェント |
|---|---|
| **決済・課金・認証** | **chopper-security（省略不可）** |
| HTML / CSS / JS / 表示系 | sanji-ui-checker |
| 認証 / API / 秘密情報 | chopper-security |
| TypeScript / Next.js ビルド | franky-build-checker |

## 17. 認証方式は OTP コード入力を必ず併設
- マジックリンクだけ / OAuth だけを提唱しない（iOS PWA で詰む）
- リンク + コードを1通のメールに入れる Slack/Notion 型
- Supabase: `signInWithOtp` + テンプレに `{{ .Token }}` + `verifyOtp`

## 18. 重い処理は事前にトークン消費目安を伝える
- Agent 4個以上: 事前告知。Workflow / deep-research: 呼ばない（事前確認+許可が必要）
- まず自分の知識 → WebSearch 2-3回 → Explore agent 1個、の順で軽い手段を優先

## 19. 外部サービス連携コードの変更は仮説で本番に入れない
- 外部 API パラメータ変更は実際のレスポンスで動作確認してから push
- 決済・カート・注文フローは「動くと確認できた」状態で push

## 20. AskUserQuestion ツール禁止
- モーダルが文脈を隠すため使用禁止。テキストで列挙して実装に進む
- 例外：本番 DB DROP 等の取り返しがつかない破壊的操作のみ

## 21. 新機能・修正は横展開チェック
- 1箇所に導入したら commit 前に grep で類似箇所を確認。全部適用 or 不要理由を列挙

## 22. 新規 Web プロジェクトは Next.js App Router
- 外部公開ページがある場合は Next.js。SPA は「完全にログイン後だけのツール」のみ

## 23. push 前に grep で横展開チェック
- 変更したパターンで `grep -rn "キーワード" src/ app/` を1回実行。省略する理由がない

## 24. 外部サービスのプロジェクト名は分かる名前にする
- ランダム生成名を放置しない。CLI が2回失敗したらダッシュボード経由に切り替え

## 25. AI モデル名は最新を確認してから書く

| プロバイダ | 高速 | 高性能 |
|---|---|---|
| Google Gemini | `gemini-2.5-flash` | `gemini-2.5-pro` |
| Anthropic Claude | `claude-haiku-4-5-20251001` | `claude-sonnet-4-6` / `claude-opus-4-6` |
| OpenAI | `gpt-4.1-mini` | `gpt-4.1` |

## 26. 確認できていない事実でアウトプットを作らない
- 情報取得に失敗したら即報告。「前回の記憶」は確認済みにカウントしない
- クライアント向け成果物は特に厳格。何も出さないほうが嘘を出すより100倍マシ

## 27. 外部スケジューラの設定は全項目チェックリストで提示
- URL / method / headers / タイムゾーン / 間隔 / レスポンス保存を全部提示
- 設定後に1回手動実行し実データで確認（200 OK だけでは不十分）
- SPA の POST 専用エンドポイントには GET に 405 を返すガードを入れる

## 28. ローカル開発時のログイン（dev-login）
- ログイン必須のアプリには `/api/dev-login` ルートを必ず作る
- `NODE_ENV === "development"` でのみ動作、本番では 404 を返す
- 仕組み: `generateLink({ type: "magiclink" })` → `hashed_token` 取得 → `verifyOtp({ token_hash, type: "magiclink" })` で SSR Cookie にセッション書き込み → リダイレクト
- 認証バイパス（`NODE_ENV` チェックで認証スキップ）は**絶対禁止**（CVE-2022-39382 の教訓）
- dev-login ルートは `.gitignore` に入れるか、本番ガード付きでコミットする
- 新規プロジェクト作成時、ログイン機能を実装したら同時に dev-login も作る

## 29. 「考えて」と言われたら壁打ちが先
- 「考えてください」「改善方法を考えて」「検討して」等の指示は、すぐ実装に入らず先に 2-3 案をメリデメ付きで提示し、ユーザーの選択を待つ
- 勝手に実装すると手戻りが発生する。方向性の確認が目的

## 30. メール送信機能の安全策
- ボタン1つで即送信は**絶対禁止**
- 必須: (1) 送信前の確認画面（プレビュー → 最終確認の2段階） (2) 送信先の選択機能 (3) メール文面の編集機能 (4) 送信後の取り消し（遅延送信等）
- cron 用エンドポイントと管理画面用 UI は分離する
- 教訓: 2026-08-14 に確認画面なしで215名に誤送信、全員に謝罪メール送付の事故が発生

## 31. ユーザーに意味のない情報を表示しない
- 「残り99999パック」等の内部管理値をユーザーに見せない
- UI 要素を追加する際は「この情報はユーザーが何の判断に使うか？」を自問。答えがないなら表示しない

## 33. 新規アプリの Railway セットアップ（初期自動設定）
- 新しいアプリを Railway にデプロイする時は、以下を自動実行する:
  1. `preview` ブランチを `main` から作成して push
  2. Railway に `preview` 環境を `production` から複製して作成
  3. `preview` 環境のソースブランチを `preview` に設定
  4. プレビュー用の Railway サービスドメインを生成
  5. **環境変数に `TZ=Asia/Tokyo` を設定**（production / preview 両方）
- セットアップスクリプト: `~/.claude/scripts/setup-railway-preview.sh` をプロジェクトディレクトリで実行
- 運用フロー: `preview` ブランチに push → プレビュー URL で確認 → `main` に push して本番デプロイ
- 注意: preview 環境の Stripe キーをテストキーに差し替えること（本番キーのままだと実課金される）

## 37. Railway のタイムゾーン設定
- Railway は UTC で動く。日本時間を扱うアプリは環境変数 `TZ=Asia/Tokyo` を必ず設定する
- `TZ` は libc の `tzset()` を使うため ICU データに依存しない。設定するだけで `new Date().getHours()` が JST を返す
- 表示用フォーマットは `Intl.DateTimeFormat('ja-JP', { timeZone: 'Asia/Tokyo' })` を使う
- 手動オフセット（`getTime() + 9*60*60*1000`）は Date 内部のタイムスタンプが壊れるため新規では使わない
- 教訓: yscc-ticket で試合時間が何度もずれた事故の原因（UTC + ICU なし環境で toLocaleString が無視された）

## 35. 不確かなことは調べてから答える（断言も撤回もしない）
- 確信がないことを聞かれたら、知識で断言するのも、ユーザーに押されて調べずに撤回するのも**両方禁止**
- どちらも同じ問題: **実際に調べていない**
- 調べる手段がない場合は「確証がないので画面で試してみてください」と正直に言う
- **クライアントワーク・個人情報・金銭が関わる場面では回答速度より正確性を絶対優先**
- 外部サービスのUI・仕様は頻繁に変わる。訓練データだけで判断しない

## 36. 各論に入る前に全体を見る
- 技術的な壁にぶつかった時、目の前の方式を修正することに固執せず「そもそも別のやり方がないか」を先に考える
- 実装に入る前に「一番シンプルな方法は何か」を含む選択肢を2-3個並べる
- 技術的に正しいかではなく、運用として最もシンプルかで判断する

## 34. この CLAUDE.md の編集後は必ず git push

```
GitHub: hideaki0320/claude-global-rules/CLAUDE.md  ← 正（唯一の正）
  ↕ git clone
ローカル: ~/.claude/global-rules/CLAUDE.md          ← clone
  ↕ symlink
~/.claude/CLAUDE.md                                  ← ローカル CLI が自動読み込み
```

編集したら `~/.claude/global-rules/` で `git add CLAUDE.md && git commit && git push` を同じターンで実行。

---

## メモリ運用について

ユーザーが「メモリして」「覚えて」「全セッション共通」と言ったルールは、この CLAUDE.md に追記する。memory/ は保証が弱い。
