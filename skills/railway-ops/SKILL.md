---
name: railway-ops
description: Railway を操作するときの手順。新しいアプリを Railway にデプロイする（preview 環境の初期設定）、タイムゾーン（TZ）を設定する、auto-deploy の無効化・デプロイの取り消し・サービスの停止など止める操作をする、環境変数を変える場面で使う。
---

# Railway の操作

## 新しいアプリの初期設定

新しいアプリを Railway にデプロイするときは、次を自動で行う：

1. `preview` ブランチを `main` から作って push
2. Railway に `preview` 環境を `production` から複製して作る
3. `preview` 環境のソースブランチを `preview` にする
4. プレビュー用の Railway サービスドメインを生成する
5. **環境変数 `TZ=Asia/Tokyo` を production・preview の両方に設定する**

- スクリプト：プロジェクトのフォルダで `~/.claude/scripts/setup-railway-preview.sh` を実行
- 運用：`preview` に push → プレビュー URL で確認 → `main` に push して本番
- **preview 環境の Stripe キーはテストキーに差し替える**（本番キーのままだと実際に課金される）

## タイムゾーン

- Railway は UTC で動く。日本時間を扱うアプリは環境変数 `TZ=Asia/Tokyo` を必ず設定する
- `TZ` は libc の `tzset()` を使うので ICU データに依存しない。設定するだけで `new Date().getHours()` が JST を返す
- 表示は `Intl.DateTimeFormat('ja-JP', { timeZone: 'Asia/Tokyo' })`
- 手動オフセット（`getTime() + 9*60*60*1000`）は Date 内部の時刻が壊れるので新規では使わない
- 教訓：yscc-ticket で試合時間が何度もずれた（UTC ＋ ICU なしの環境で toLocaleString が無視された）

## 止める操作（破壊的操作）

- auto-deploy の無効化・Queue の全キャンセルなどの前に、SERVING の deployment ID を記録する
- 「ビルドを止めたい」が目的なら、サービスの稼働を止める操作は選ばない
- auto-deploy の無効化は「再有効化 ＋ 手動デプロイ」とセットで行う
- 教訓：2026-05-14 IntraCanvas の停止事故から

## 環境変数・ドメイン・スケール

- 稼働中のサービスの変更は「提案 → 承認 → 実行 → 本番の生存確認」（CLAUDE.md の「安全」）
- 環境変数はまず Railway の画面で設定する案を出す
- 稀に "Failed to create deployment" がインフラ側の原因で出る。再デプロイで直る
