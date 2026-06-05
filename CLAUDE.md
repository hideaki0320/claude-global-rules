# グローバル開発ルール（全セッション・全プロジェクト共通）

これらは過去に何度も依頼されたのに守られなかったルールです。**全プロジェクト・全セッションで例外なく適用**してください。

---

## 1. UIアイコン
- 絵文字アイコン（🏠📐✍️📋📱📣📝📅📁🕐⚙️🚪 など）は **絶対に使わない**
- アイコンは必ず **Lucide React**（または Heroicons 等）の SVG を使う

## 2. コミットとプッシュは必ずセット
- ユーザーが「コミットして」「commit して」と言ったら、`git add` → `git commit` → `git push` を**確認なしで一連実行**する
- プッシュ前に「プッシュしますか？」と聞かない
- 例外：main/master への force push など破壊的なケースのみ事前確認
- push が失敗したら（rebase 必要、権限エラー等）報告して指示を仰ぐ

## 3. 詰まった時は即報告（黙らない）
- 作業が詰まったら、解決を試み続ける前にまず **「詰まっています／原因の見立て／次に試す手」** を報告する
- 同じ失敗を 2 回繰り返したら一旦止めてユーザーに状況を共有する
- 長時間応答がない状態を作らない。進捗を細かく伝える

## 4. うまくいっていたものが急にダメになったとき
- **同じ方法を繰り返さない**
- 環境・依存・設定の変化を疑う。直前のコミット、デプロイ、依存更新、外部 API の挙動変化を順に確認する
- ユーザーに「いつから動かなくなったか」を確認する

## 5. ユーザーが提供した観察事実は疑わない
- 「コンソールに何も出ない」「画面が真っ白」などの報告に対し、同じ確認を繰り返し求めない
- 報告された事実を前提に**別の角度から原因を探る**
- 「もう一度コンソールを確認してください」と返すのは、明らかに前回と状況が変わった場合のみ
- **「あなたはこれができるはず」と言われたら、まず広く探す**: `.env` だけ見て無いなら `~/.config/`, `~/.claude/`, `~/.zshrc`, `printenv` まで一気に確認。「自分の見える範囲に無い → 不可能」と結論する前に **`find ~ -name "*<キーワード>*" -maxdepth 5` 等で網羅探索** する。それでも見つからなければ「**どこに設定しましたか？**」と聞く。**「不可能です」と curl の証拠を並べて反論するのは禁止**（2026-05-09 の Supabase Management API 件で実害あり）

## 6. .env / 環境変数の扱い
- ユーザーは **.env ファイルの直接編集が苦手**（テキストエディタで開きにくい）
- 環境変数を追加・変更する場合：
  - **Railway / Vercel 等のホスティング側 UI に直接貼る方法を第一案**として案内する
  - .env 内容を提示するときは**コピペ可能なコードブロック**で全文を出す
  - 「.env を開いて◯◯行目を直して」のような操作は要求しない

## 7. SQL は会話に全文貼る・対象プロジェクトを必ず明示する
- Supabase 等で SQL を実行してもらう場合、**SQL をチャットに全文貼る**
- ファイルに書いて「これを実行してください」では不便。コピペできる形でその場に出す
- 複数 SQL を順に実行する場合も、毎回フルテキストを提示
- **SQL の直前に必ず対象 Supabase プロジェクト名を明記する**（例：「▶ bizchain800 の SQL Editor で実行」「▶ IntraCanvas_pro の SQL Editor で実行」）
- プロジェクトを書き忘れない。どちらか曖昧な場合は確認してから提示する

---

## 8. E-team ブランドアセット（ロゴ・ヘッダー）
- E-team ロゴは **ワードマーク版**（横長：シンボル + "E-TEAM" 文字）を使う。favicon の **シンボル単体版は使わない**（小さく、社名認知が弱いため）
- ヘッダーでのロゴ高さは **最小 56px**。それより小さくしない（過去にプロジェクトで何度も「ロゴ小さい」と指摘された）
- 共通の `<BrandHeader />` コンポーネントを各ページで使う。**ロゴサイズを各ページで個別指定しない**（一元管理）
- 新しいページを作るときは、まず既存の `BrandHeader` を import する。インラインで `<img src="/e-team-logo.png" />` を直接書かない
- ロゴ画像は `public/e-team-logo.png`（ワードマーク版）

---

## 9. Supabase の環境変数名（新形式）
- 最近の Supabase プロジェクトは **anon key が廃止され publishable key に変わっている**
- 環境変数名は `NEXT_PUBLIC_SUPABASE_ANON_KEY` **ではなく** `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` を使う
- コードを書くときも、既存コードを修正するときも、必ずこの新しい名前を使うこと
- `SUPABASE_SERVICE_ROLE_KEY` はそのまま変わらない

---

## 10. 本番DBへの書き込みは最大限慎重に（2026-05-09 重大インシデントから）

**背景**: 蒲原水産ECサイトで、WordPress画像URLをSupabase URLに修正するスクリプトを実行した際、`images`列（クライアントが手動で複数画像を登録していたjsonb配列）を`[1枚だけ]`に上書きしてしまった。クライアントの作業データが消失し、DBバックアップからの復元が必要になった。

### なぜ起きたか
1. **既存データの確認を怠った** — `images`列に複数画像が入っている可能性を考慮せず、全レコードを一律上書き
2. **更新カラムが過剰** — `image`列だけで済むのに`images`列まで含めた
3. **バックアップなしに一括更新** — 100件近いPATCH前にSELECT結果を保存しなかった
4. **テスト実行なし** — 1件で試してから全件、という手順を踏まなかった

### 防止ルール（全プロジェクト共通・例外なし）
1. **本番DBへのUPDATE/DELETEは、実行前に対象レコードのSELECT結果をローカルにJSON保存する**
2. **更新カラムは必要最小限。目的外のカラムを含めない**
3. **一括更新は「1件テスト → 確認 → 全件実行」の3ステップ必須**
4. **クライアントが手動入力したデータは絶対に上書きしない。必要な場合は事前確認**
5. **スクリプト実行前に「何を変更し、何を変更しないか」を宣言する**

---

## 11. Supabase Management API アクセストークン（2026-05-09 設定）

**中森さんは Supabase Management API のアクセストークンを `~/.config/supabase_token` に保存済み**（chmod 600）。これを使えば全Supabaseプロジェクト（task-triage / bizchain800 / intracanvas など）に対して **Claude が直接 SQL 実行・設定確認・テンプレ確認できる**。

### 使い方（必須コマンド）

```bash
# プロジェクト一覧
TOKEN=$(cat ~/.config/supabase_token); curl -s "https://api.supabase.com/v1/projects" -H "Authorization: Bearer $TOKEN"

# SQL 実行（auth schema 含む全スキーマOK）
TOKEN=$(cat ~/.config/supabase_token); curl -s "https://api.supabase.com/v1/projects/<PROJECT_REF>/database/query" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"query":"select ..."}'

# Auth 設定（Email Templates / SMTP / Hooks）の確認
TOKEN=$(cat ~/.config/supabase_token); curl -s "https://api.supabase.com/v1/projects/<PROJECT_REF>/config/auth" -H "Authorization: Bearer $TOKEN"
```

### 何ができるか

- **auth スキーマ** に直接アクセス（auth.users / auth.audit_log_entries / auth.flow_state など）
- **Email Templates の中身** を直接確認・更新（保存値が画面表示と乖離していないか検証可能）
- **Auth Hooks の有効/無効** 確認
- **SMTP 設定** の確認
- 全スキーマでの SELECT/INSERT/UPDATE/DELETE/DDL

### いつ使うか

- **読み取り系（SELECT、設定確認）**: 即実行してOK。git に何も残さない（透明性は git history 上の commit と Supabase ダッシュボードに任せる）
- **DDL / 本番データ変更**: **必ず git に記録を残す**（次項参照）
- **破壊的操作（DELETE / DROP）**: 必ず事前に SELECT で対象を確認 → ローカルJSONバックアップ → 1件テスト → 全件、というルール10のフローを守る

### 【最重要】API経由で DB を変えたら必ず git に migration を残す

Management API は強力すぎて **「コードと DB が乖離する」事故** を生みやすい。これを防ぐため、API経由で DDL や本番データ変更を実行する時は、**必ず以下の順序を守る**：

1. **migration SQL を書く**: 該当プロジェクトの `db/migrations/<YYYYMMDD_HHMM>_<短い説明>.sql` に冪等な SQL（`if not exists` / `on conflict do nothing` 等）を作成
2. **git に commit + push**: コード変更と同じセッションで一緒にプッシュ。**「あとで commit する」は禁物**（忘れる）
3. **API 経由で実行**: `curl ... /v1/projects/<ref>/database/query`

逆順（先に実行→後で commit）はバグの元。**git → API** を厳守。

これは「中森さんが SQL Editor で実行する」既存フローと同じだが、Claude が API で代行する時は **ルール7（SQL を会話に貼る）に加えて migration ファイルも作る** のがセット。

read-only な診断 SELECT は git 不要だが、それ以外は必ず git。

### セキュリティ運用

- **トークン本体をチャットや commit message に絶対貼らない**
- ファイルパス（`~/.config/supabase_token`）は記載してOK
- トークン漏洩疑いがあれば Supabase ダッシュボード → Account → Access Tokens で即 Revoke
- 業務上不要になったら Revoke する

### 「全セッション共通の認識にしてくれ」と頼まれたら

このルールのように **必ず `~/.claude/CLAUDE.md` に書き込む**。memory/ には書かない（読まれる保証が弱い）。書き込み完了をユーザーに「✅追記しました」と明示報告する。

---

## 12. スクリプトの実行ルール（2026-05-14 sync-global-rules 事故から）

**累積する副作用**（git commit / git push / INSERT / カウンタ +=1 等の **非冪等な書き込み**）を含むスクリプトについては以下を守る。冪等な操作のみのスクリプトはこの章の対象外。

### 12-① background 実行禁止
累積する副作用を含むスクリプトは `run_in_background: true` で実行しない（必ず foreground）。

`npm run dev` / `npm run build` / 冪等な UPDATE / ファイル上書き等は background で OK。

### 12-② 複数リポへの書き込みは原則 1 ステップずつ
複数リポジトリへの書き込み操作は、原則 Bash ツールを 1 ステップずつ呼ぶ。理由は「ロジックバグを 1 リポ目で気付いて止められる」観測可能性のため。

以下を**全部満たす**スクリプトなら一括処理 OK：
- 12-③（PID lock）あり
- 12-④（冪等性チェック）あり
- 事前に dry-run（書き込みなし出力のみ）で結果を検証済み

「複数リポへの書き込み」は普段ほぼ発生しないので、判断に迷ったら 1 ステップずつ。

### 12-③ 多重起動されうるスクリプトに PID lock 必須
以下のいずれかに該当するスクリプトは冒頭に PID lock を必須：

- background 実行するもの
- cron / launchd / 何らかのスケジューラに登録するもの
- 多重起動される可能性があるもの

```bash
mkdir /tmp/my-script.lock 2>/dev/null || exit 0
trap 'rmdir /tmp/my-script.lock' EXIT
```

foreground で 1 回呼んで終わりの短命スクリプトには lock 不要。

### 12-④ 累積する書き込み操作は冪等に
`git commit` 等の累積する操作は、実行前に「すでに同じ状態か」確認して、同じなら skip する。

```bash
# 非冪等（呼ぶたび新 commit）
git commit -m "..."

# 冪等版
if git diff --cached --quiet; then
  echo "変更なし、skip"
else
  git commit -m "..."
fi
```

### 事故詳細
2026-05-14、`~/.claude/sync-global-rules.sh` を作成し `run_in_background: true` で実行。何らかの理由で同じスクリプトが大量に並行起動され、各々が `git commit` を発行した結果、intracanvas に 183 commit、E-team AI公式サイト に 182 commit の重複が発生。Railway が各 commit をビルドしようとして失敗通知が大量送信された。スクリプト本体に PID lock も冪等性チェックも無く、`run_in_background: true` だったため気付くのも遅れた。

---

## 13. Railway / デプロイサービスの破壊的操作ルール（2026-05-14 IntraCanvas 停止事故から）

以下は service 停止に直結する破壊的操作。慎重に：

- auto-deploy の無効化
- 大量の deployment 一括キャンセル
- service の Source 切断

### 13-① 操作前に SERVING deployment ID を記録
上記の destructive operation の直前に、**現在 SERVING している deployment ID** を必ず記録する。

```bash
railway deployment list | head -5
# → SUCCESS 状態の最新 deployment ID をメモ
```

復旧が必要になった時に「あの状態に戻したい」を辿るための情報。

### 13-② メール / ビルド停止が目的なら、service 稼働を止める手段は選ばない
「メール通知を止めたい」「ビルドを止めたい」がゴールの場合、service 稼働を止める操作は選ばない。代わりに：

- Railway の Notification Rules で Email を In-App のみに変更
- Gmail 側フィルタで受信側ブロック
- 個別の deployment cancel のみ（auto-deploy は触らない）

### 13-③ auto-deploy 無効化は「戻し」とセット
auto-deploy を無効化したら、**戻すための再有効化 + 手動 deploy がセットで必要**。忘れると serving 中の deployment が他の理由で消えた時に補えず、service が完全停止する。

### 事故詳細
メール通知を止めるために auto-deploy OFF + 全 Queue cancel を実行 → SUCCESS deployment が 0 個になり intracanvas が完全停止 → SSL 証明書も発行できずユーザーがログイン不能になった。復旧は auto-deploy 再有効化 + 手動 deploy で実施した。

---

## 14. 外部依存ありの機能を実装したら、その外部設定を必ず先に提示する（2026-05-20 Resend追跡欠落事故から）

**背景**：BIZCHAIN800の名刺メール一括送信を実装。UIに「開封」「クリック」列を出し、Resend webhookハンドラまでコードを書いたのに、**「Resend Domain側で Open/Click Tracking のCNAME設定が必要」をユーザーに一度も伝えなかった**。ユーザー視点では機能完成として運用に乗ってしまい、800通近く送信して開封・クリック計測ゼロという事態に。過去送信分は遡って追跡不可。

これはテスト漏れではなく、**機能の前提条件をユーザーに共有しなかった**という、より根本的なミス。

### 14-① 外部サービス・SaaS設定が必要な機能を実装する時は、最初に「外部依存リスト」を必ず提示する

実装に着手する前に、以下を明示的にユーザーに渡す：

```
この機能を動かすために必要な外部設定:
- [SaaS名] の [設定項目1]：[具体的に何をする必要があるか]
- [SaaS名] の [設定項目2]：[具体的に何をする必要があるか]
- [DNS] の [レコード]：[追加が必要な値]
- [環境変数] [名前]：[Railway / Vercel 等で設定が必要]
```

リストを出さずに実装に進むのは禁止。コードだけ書いて「完成」と判定しない。

### 14-② メール送信機能の外部依存（参考例）

メール（Resend）機能を実装するときに必ず確認・提示すべき設定：

1. **Resend Domain の DKIM/SPF 認証**（Verified 表示）
2. **Resend Domain の Open Tracking の Configure**（CNAME 追加が必要）
3. **Resend Domain の Click Tracking の Configure**（CNAME 追加が必要）
4. **Resend Webhook の登録**（本番URL を Subscribe）
5. **Webhook の Subscribed Events**：delivered / bounced / opened / clicked / complained すべて
6. **Resend プラン**（Free 100/日, 2req/sec / Pro 50,000/月, 10req/sec）と想定送信量の照合
7. **環境変数**：RESEND_API_KEY、RESEND_WEBHOOK_SECRET
8. **From アドレスの権限**：ドメイン認証済みのアドレス or サブドメインを使うか

### 14-③ 外部依存の状態を実データで end-to-end 検証する

14-① で提示した外部設定が「全部完了している」ことを実データで確認する。コードだけ書いて「動くだろう」と判定しない：

- 自分宛に1通テスト送信 → 実際に受信トレイで開く → DBの opened_at に時刻が入るか確認
- 本文のリンクをクリック → DBの clicked_at に時刻が入るか確認
- 不正なメアド・空配列・rate limit越え時のハンドリングが UI でユーザーに見える形で表示されるか
- 失敗ログが DB に残るか

### 14-④ バウンス・苦情の自動抑制が無いと配信評価が下がる

- `bounced` / `complained` 履歴のあるメアドは次回送信対象から自動除外するロジックを実装する
- していなければユーザーに「未実装」と明示し、運用上の判断を求める

### 14-⑤ メール送信は取り返しがつかない

- 誤送信は撤回不能
- 開封・クリック計測の漏れは過去分回復不可（追跡ピクセルが既に欠落）
- 配信停止リクエストの不履行は法的問題
- なのでメール送信機能は **「動くだろう」ではなく「動くと確認できた」状態**になってからリリース

---

## 15. Supabase RLS の銀の弾はない（2026-05-24 task-triage 編集機能事故から）

**背景**: 業務整理アプリ (task-triage) で `session_submissions` テーブルに INSERT/SELECT/DELETE のポリシーは追加していたが UPDATE を漏らした。受講生の編集機能を実装後、Supabase の RLS が "silent fail"（error 無し・updated_rows = 0）で返すため、フロント側では「保存ボタンを押したけど何も起きない」幽霊バグになった。同じ日に INSERT ポリシー漏れ事故 (sanji-ui-checker が検出) も起こしており、**「同じパターン 2 回」** という構造ミス。

### 15-① 新規テーブル作成時は CRUD 4 ポリシーを必ず同時定義

Supabase は新規テーブルに対し `relrowsecurity=true` を自動付与する。ポリシー無しは **anon/authenticated からの全件ブロック**。最初から CRUD 4 つ書き、不要なものは明示的にコメントで「ここは禁止」と書く：

```sql
-- migration ファイルのテンプレ
create policy "table_name_select" on table_name for select to anon, authenticated using (true);
create policy "table_name_insert" on table_name for insert to anon, authenticated with check (true);
-- UPDATE は禁止（このテーブルは insert-only ログとして使う）
-- create policy "table_name_update" on table_name for update ...
-- DELETE は admin だけ。anon には許可しない
-- create policy "table_name_delete" on table_name for delete ...
```

3 つだけ書いて「4 つ目は将来必要になったら」と思うのは **禁止**。今回の事故はそのパターンで起きた。

### 15-② update/delete を新規実装する時の防御パターン

Supabase の RLS 違反は **エラー無しで 0 行更新を返す**（攻撃者にレコード存在情報を漏らさないため）。`error` だけチェックすると silent fail を見逃す。**必ず .select() chain で更新行数を確認**：

```js
// 悪い例（silent fail を検知できない）
const { error } = await supabase.from(t).update(p).eq("id", id);
if (error) throw error;

// 良い例
const { data, error } = await supabase.from(t).update(p).eq("id", id).select();
if (error) throw error;
if (!data || data.length === 0) {
  throw new Error("更新できませんでした（RLS違反 or レコード不存在）");
}
```

delete も同様。`supabase.from(t).delete().eq("id", id).select()` で削除行を返してもらう。

### 15-③ ポリシー追加・スキーマ変更で既存機能を破壊しないチェック

新機能追加で `.update()` / `.delete()` / `.insert()` を呼ぶコードを書いたら、コミット前に `pg_policies` で対応ポリシーがあるか必ず確認：

```bash
TOKEN=$(cat ~/.config/supabase_token)
curl -s "https://api.supabase.com/v1/projects/<REF>/database/query" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"query":"select policyname, cmd, roles from pg_policies where schemaname='\''public'\'' and tablename='\''<TABLE>'\''"}'
```

または robin-schema-guard（拡張済み）を呼んで「RLS と CRUD 呼び出しの対応」を機械的に検査させる。

### 15-④ 同じパターン 2 回目を防ぐ反省

事故が起きた時の教訓は **個別事象ではなく一般化** して理解する。今回：
- 1 回目（5/24 朝）: 「INSERT ポリシー忘れた」→ 教訓「INSERT に注意」（× 個別化しすぎ）
- 同日 2 回目: 「UPDATE ポリシー忘れた」→ 同じ穴に落ちた
- 一般化すべきだった教訓: **「Supabase テーブルに対する全 CRUD 操作にはそれぞれ対応する RLS ポリシーが必要」**

事故報告書には必ず「もっと一般化された教訓は何か」を 1 行書く運用にする。

---

## 16. git push 前のサブエージェントチェック（2026-05-25 蒲原水産CSP3連続事故から）

**背景**: 蒲原水産ECサイトでQuillエディタ導入時、CSPヘッダーの設定ミスを3回連続でプッシュした。サブエージェント（sanji-ui-checker等）のツール説明文に「プロアクティブに使え」と書かれていたが、判断の余地がある書き方だったため3回とも飛ばした。結果、ユーザーが毎回エラーを報告→修正→再プッシュの往復が発生。

### ルール: git push の前に、変更内容に応じたサブエージェントを1つ起動する

| 変更内容 | 使うサブエージェント |
|---|---|
| HTML / CSS / JS / CSP / 表示系 | sanji-ui-checker |
| 認証 / API / 秘密情報 / 依存パッケージ | chopper-security |
| TypeScript / Next.js ビルド関連 | franky-build-checker |

- チェック結果を待ってからプッシュする
- コミット準備とサブエージェント起動は並行してOK（遅延ほぼゼロ）
- 複数カテゴリにまたがる変更は、最も影響の大きい1つを選ぶ
- チェックで問題が見つかったら、修正してから再チェック→プッシュ

---

## 17. 認証方式は「マジックリンク/OAuth だけ」を提唱しない（2026-05-25 task-triage iPhone PWA 事故から）

**背景**: task-triage で認証をマジックリンク一本にしていたところ、中森が iPhone でホーム画面に PWA を追加 → メアド入力 → 届いたメールのリンクをタップ → **Safari で開く** → PWA 側は永遠にログイン画面のまま、という詰みパターンを発見。

### なぜ起きるか（構造的限界）

iOS の PWA（standalone モード）は、**スコープ外 URL への遷移を standalone から落として Safari で開く**。さらに Safari と PWA はストレージ・Cookie を共有しない。結果：

- **マジックリンク**: メール内リンクをタップ → Safari でセッション確立 → PWA に戻らない ❌
- **Google / Apple OAuth**: 認証後 Safari の元 URL にリダイレクト → 同じく PWA に戻らない ❌（OAuth も外部遷移するため同じ穴）
- **OTP コード入力**: 外部遷移ゼロ、PWA 内でコード入力 → PWA 内でセッション確立 ✅（唯一の完全解）

### ルール

**認証 UX を設計・提案する時は、必ず「iOS PWA（ホーム画面追加）でも動くか」を確認する。**

1. **マジックリンクだけ / OAuth だけを提唱しない**。PWA 利用者が詰む
2. **OTP コード入力方式を必ず併設する**（リンク + コードを 1 通のメールに入れる Slack / Notion 型）
   - PC・通常ブラウザ → リンクをクリック（楽）
   - iPhone PWA・別コンテキスト → コードを手入力（確実）
3. Supabase なら `signInWithOtp` が既にコードを生成している（`mailer_otp_length`）。メールテンプレに `{{ .Token }}` を併記し、フロントで `verifyOtp({ email, token, type: "email" })` で検証する
4. 「OAuth にすれば解決」は **誤り**。OAuth も iOS PWA standalone では Safari に飛んで戻らない

### 一般教訓

「パスワードレス = マジックリンク」と短絡しない。**パスワードレスには「リンク方式」と「コード方式」があり、PWA/モバイルでは後者が必須**。新規プロジェクトで認証を実装する時は、最初からコード入力方式を組み込む。

---

## 18. 重い処理は事前にトークン消費目安を伝える（2026-06-03 策定・事故から）

**重い処理を呼ぶ前は、必ず事前にトークン消費目安と概算費用を伝えてから実行する。**

### 規模別の運用ルール

| 規模 | ルール |
|---|---|
| 並列 Agent 1〜3 個 / 普段の subagent | 事前告知不要、自由に呼ぶ |
| 並列 Agent 4 個以上 | 事前に「合計 ~XXX 万トークン、$X 規模」と告知してから呼ぶ |
| Workflow / deep-research / Skill 経由の大規模 fan-out | **呼ばない**。呼ぶなら必ず事前確認 + ユーザー許可 |

### 消費目安（参考、Sonnet 4 のレート）

- 軽い Agent 1個（探索・grep系）：5,000〜30,000 トークン（$0.02〜$0.10）
- 中規模 Agent 1個（UI / ビルド検査）：30,000〜100,000（$0.10〜$0.40）
- 重い Agent 1個（コード実装まで）：200,000〜500,000（$0.70〜$2）
- Workflow（deep-research 等）：3,000,000〜5,000,000（**$10〜$50**）

### 事故事例（2026-06-03）

CRESKILL の「タイムライン機能設計のために世の流行りアプリ調査」で deep-research Workflow を呼んだら 108 agents × 3.8M トークン消費して失敗。Claude Pro / Max の 5h ウィンドウ枠を即座に枯渇させ、追加購入した API クレジット $20 が瞬殺された。

→ Workflow / 100+ Agent の fan-out は事前確認なしに呼ばない。「調査して」と言われても、まず私自身の知識で答え、足りなければ単発 WebSearch / WebFetch 2-3 回で済ませる（無料枠）。

### 軽い代替手段（優先順）

1. **私自身の知識ベース**（ゼロコスト）
2. **WebSearch / WebFetch を 2-3 回**（無料枠、安価）
3. **Explore agent を 1 個**（数千〜数万トークン）

これらで足りない時だけ、事前確認の上で重い処理を検討する。

---

## 19. 外部サービス連携コードの変更は仮説で本番に入れない（2026-06-03 easy-myshopカート停止事故から）

**背景**: 蒲原水産ECサイトで、easy-myshopカートの商品重複バグを修正しようとして、cartin URLの `order_made_flg=1` パラメータを削除した。「このフラグが重複原因」は推測に過ぎなかったが、easy-myshopの実APIで検証せずに本番プッシュ。実際にはこのフラグは番号付きバッチパラメータ（item_code1, item_count1）の必須フラグであり、削除によりカートが完全に機能停止した。

### 防止ルール

1. **外部サービス（easy-myshop, Stripe, Resend 等）のAPI呼び出しパラメータを変更する場合、実際のAPIレスポンスで動作確認してからプッシュする**
2. **「このパラメータが原因だろう」は仮説。仮説を本番に入れない。** 検証方法：
   - ブラウザで実際にカート遷移してエラーが出ないか確認
   - curlやfetchで実際のエンドポイントを叩いてレスポンスを見る
   - テスト用の商品コードで1件だけ試す
3. **決済・カート・注文フロー（お金が絡む導線）のコード変更は特別扱い**。「動くだろう」は禁止、「動くと確認できた」状態でプッシュ
4. **UIチェック（sanji-ui-checker）のスキップは、決済導線の変更がない場合のみ許可**

### 一般化された教訓

**推測に基づく修正は、修正対象が重要であるほど危険。** バグ報告 → 原因推測 → 即修正、ではなく、バグ報告 → 原因推測 → **推測の検証** → 修正、の順序を守る。

---

## 20. AskUserQuestion ツール禁止（2026-06-05 中森指示）

**`AskUserQuestion` ツールは原則使用禁止。**

### 理由

モーダルが画面を覆い、**その前のテキスト（質問の文脈）が見えなくなる**。結果として「質問の意味がわからない」が多発、UI として破綻している。

### 運用

- 複数案を提示する場合も、**テキストで列挙してそのまま実装に進む**
- 中森が「確認モーダル」「質問モーダル」「選択肢モーダル」と口頭で言う場合、**すべて `AskUserQuestion` ツールを指す**
- 迷ったらまず実装し、後で報告 + 修正余地を残す形がベスト

### 例外（極めて稀）

本当に取り返しがつかない破壊的操作（本番DB DROP / 大量データ消去等）で、かつ事前情報が不足している時のみ。それ以外は使用しない。

---

## メモリ運用について

ユーザーが「メモリして」「覚えて」「全セッション共通」「今後も必ず」と言ったルールは、**メモリではなく、この CLAUDE.md に追記する**こと。メモリは関連時にしか読まれず、保証が弱い。CLAUDE.md は必ず読まれる。
