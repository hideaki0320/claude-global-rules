# settings.json の変更案（文章ではなく仕組みで止める）

対象：`~/.claude/settings.json`（今は `permissions.allow` に Bash(*) などが入っているだけ）。
**この案は未適用。** 中森さんの OK ごとに1つずつ入れて、動作を確かめる。

出典：Claude Code 公式「Configure permissions」（ルールは deny → ask → allow の順に評価され、最初に当たったものが勝つ）
https://code.claude.com/docs/en/permissions

## 案1：AskUserQuestion を使えなくする（旧ルール20）

```json
"permissions": { "deny": ["AskUserQuestion"] }
```

- 効果：文章のルールではなく、ツール自体が呼べなくなる
- 未検証：公式に「AskUserQuestion を deny に書く」例そのものは無い（deny が最優先という一般則からの推論）。入れたら1回試す
- 戻し方：この行を消す
- 「次の一手」ボックス（wrap_up の ask / actions）はアプリの機能なので、ここでは止められない。文章のルールのまま

## 案2：force push を毎回確認にする（旧ルール2の例外）

```json
"permissions": { "ask": ["Bash(git push --force:*)", "Bash(git push -f:*)", "Bash(git push --force-with-lease:*)"] }
```

- 効果：今は Bash(*) が全部許可なので、force push も確認なしで通る。ask が allow より先に評価されるので、これだけ確認が出るようになる
- 戻し方：この行を消す

## 案3：Markifact の書き込みの自動許可を外す（びんごやの残タスク「Markifact の書き込み許可の設定を消す」）

今の `permissions.allow` に `mcp__d943db9d-8cf9-48b4-9ab1-893852d043f4__run_write_operation` が入っている。これがあると、Markifact 経由の広告などへの書き込みが確認なしで通る。

- 変更：この1行を `allow` から消す
- 戻し方：1行を戻す

## 案4：途中でルールが変わったら、走っているセッションに知らせる（今回の原因への対策）

- 仕組み：フック（UserPromptSubmit）で、セッション開始時の `~/.claude/global-rules` のコミットと今のコミットを比べ、違えば「CLAUDE.md が更新されています（差分）」を会話に差し込む
- 作るのは小さなシェルスクリプト1つと、settings.json の hooks の設定
- 未検証：作ってから、2つのセッションで実際に試す必要がある
- 簡単な代わり：CLAUDE.md の「このファイルの運用」に「変えたら作業中のセッションにも伝える」を書いた（下書きに入れ済み）。まずはこれで様子を見て、また起きたらフックを作る、でもよい
