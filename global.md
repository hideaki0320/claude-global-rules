# 全プロジェクト共通ルール

## 作業姿勢
- 絵文字アイコン禁止。Lucide React（またはHeroicons等）のSVGを使う
- 「コミットして」→ git add → commit → サブエージェントチェック → push を確認なしで一連実行。force pushのみ事前確認。pushを忘れるのは禁止
- 詰まったら即報告（原因の見立て＋次に試す手）。同じ失敗2回で止める。急に動かなくなったら環境変化を疑い同じ方法を繰り返さない
- ユーザーの観察事実は疑わない。報告された事実を前提に別の角度から探る
- 「考えて」「検討して」→ 実装前に2-3案をメリデメ付きで提示しユーザーの選択を待つ
- AskUserQuestionツール禁止。テキストで列挙して実装に進む（本番DB DROP等の破壊操作のみ例外）
- ユーザーに意味のない情報（残り99999パック等の内部管理値）を表示しない
- 確認できていない事実でアウトプットを作らない。クライアント向け成果物は特に厳格。嘘より出さない方が100倍マシ

## git・デプロイ
- push前サブエージェントチェック:

| 変更内容 | サブエージェント |
|---|---|
| **決済・課金・認証** | **chopper-security（省略不可）** |
| HTML / CSS / JS / 表示系 | sanji-ui-checker |
| 認証 / API / 秘密情報 | chopper-security |
| TypeScript / Next.js ビルド | franky-build-checker |

- push前にgrepで横展開チェック。変更パターンで `grep -rn "キーワード" src/ app/` を実行し類似箇所を確認
- 取り返しのつかない操作（git push・DB書き込み等）はbackground実行禁止。結果を確認してから次へ進む
- 新規WebプロジェクトはNext.js App Router。SPAは完全ログイン後ツールのみ

## 外部サービス・環境変数
- .envはRailway/Vercel等のUIで設定を第一案。提示時はコピペ可能なコードブロックで全文出す
- SQLは会話に全文貼る＋対象Supabaseプロジェクト名を明記（例:「▶ bizchain800のSQL Editorで実行」）
- 外部依存ありの機能は実装前に外部依存リスト（SaaS設定/DNS/環境変数）を提示。コードだけで完成にしない。メール送信はDKIM/SPF/Tracking CNAME/Webhook/環境変数を全部確認
- 外部サービス連携コードは仮説で本番に入れない。決済・カート・注文フローは動作確認してからpush
- 外部サービスのプロジェクト名はわかる名前にする。CLI2回失敗→ダッシュボード経由に切り替え
- 外部スケジューラは全項目チェックリスト提示（URL/method/headers/TZ/間隔/レスポンス保存）。設定後に手動実行で実データ確認。POST専用エンドポイントにはGET 405ガード
- 重い処理は事前にトークン消費目安を伝える。Agent4個以上は事前告知。Workflow/deep-researchは事前確認+許可が必要

## 認証
- 認証方式はOTPコード入力を必ず併設。マジックリンクだけ/OAuthだけにしない（iOS PWAで詰む）
- Supabase: signInWithOtp + テンプレに {{ .Token }} + verifyOtp

## メール送信安全策
- ボタン1つで即送信は**絶対禁止**
- 必須: (1)送信前の確認画面（プレビュー→最終確認の2段階） (2)送信先の選択機能 (3)メール文面の編集機能 (4)送信後の取り消し（遅延送信等）
- cron用エンドポイントと管理画面UIは分離
- 教訓: 2026-08-14に確認画面なしで215名に誤送信、全員に謝罪メール送付

## AIモデル名
最新を確認してから書く:

| プロバイダ | 高速 | 高性能 |
|---|---|---|
| Google Gemini | gemini-2.5-flash | gemini-2.5-pro |
| Anthropic Claude | claude-haiku-4-5-20251001 | claude-sonnet-4-6 / claude-opus-4-6 |
| OpenAI | gpt-4.1-mini | gpt-4.1 |

## dev-login
- ログイン必須アプリには `/api/dev-login` ルートを必ず作る
- `NODE_ENV === "development"` でのみ動作、本番では404
- 仕組み: generateLink → hashed_token → verifyOtp → Cookie → リダイレクト
- 認証バイパス（NODE_ENVチェックで認証スキップ）は**絶対禁止**（CVE-2022-39382）

## ルール管理
- 「全プロジェクト共通ルール追加して」→ `.claude/rules/global.md` を編集して全プロジェクトに展開
- 「このプロジェクトのルール追加して」→ `CLAUDE.md` を編集
