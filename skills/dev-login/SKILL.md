---
name: dev-login
description: ログインが必要なアプリで、ローカル開発用のログイン（/api/dev-login）を作るときの手順。新規プロジェクトでログイン機能を実装したとき、ローカルでログイン後の画面を確かめたいときに使う。
---

# ローカル開発用ログイン（dev-login）

- ログインが必要なアプリには `/api/dev-login` ルートを必ず作る
- `NODE_ENV === "development"` のときだけ動き、本番では 404 を返す
- 仕組み：`generateLink({ type: "magiclink" })` → `hashed_token` を取得 → `verifyOtp({ token_hash, type: "magiclink" })` で SSR の Cookie にセッションを書き込み → リダイレクト
- **認証バイパス（`NODE_ENV` を見て認証を飛ばす）は絶対禁止**（CVE-2022-39382 の教訓）
- dev-login のルートは `.gitignore` に入れるか、本番ガード付きでコミットする
- 新規プロジェクトでログイン機能を実装したら、同時に dev-login も作る
