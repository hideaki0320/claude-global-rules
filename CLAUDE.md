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

## メモリ運用について

ユーザーが「メモリして」「覚えて」「全セッション共通」「今後も必ず」と言ったルールは、**メモリではなく、この CLAUDE.md に追記する**こと。メモリは関連時にしか読まれず、保証が弱い。CLAUDE.md は必ず読まれる。
