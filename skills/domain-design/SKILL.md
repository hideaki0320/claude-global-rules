---
name: domain-design
description: ドメイン・DNS・ホスト名を設計・変更するときの決まり。新しいアプリのドメインを決める、apex（裸ドメイン）に向ける、独自ドメイン・マルチテナントを扱う、ネームサーバーや DNS レコードを変える、ドメイン障害を調べる場面で使う。
---

# ドメイン・DNS の設計

外部から見えるアプリを作るときは、**ホスト名の設計を最初に決める**。後から直すと認証・決済に波及して動かせなくなる。

## 1. アプリ本体を apex（裸ドメイン）に置かない

```
正) app.example.com   CNAME → ホスティング先    ← アプリ本体
    example.com       A     → 転送用サーバー     → 301 で app. へ
誤) example.com       A     → ホスティング先のIP直打ち  ← 時限爆弾
```

DNS の仕様上、**apex には CNAME を置けない**（NS/MX/TXT と共存できない）。apex を Railway 等に向けるには A レコードで IP を直接書くしかなく、ホスティング側が IP を変えた瞬間に落ちる。CNAME は名前を指すので自動で追従する。

例外：Vercel（anycast）、Cloudflare（CNAME flattening）、ALIAS/ANAME 対応の DNS なら apex でも安全。**Xserver + Railway の組み合わせでは不可**なので、必ずサブドメインに置く。

## 2. 予約サブドメインをテナント判定から外す

「知らないホストは顧客のドメイン」とする catch-all 設計では、`www` などが未登録の顧客と判定されて 404 になる。Vercel の公式実装（Platforms Starter Kit）も `rootDomain` と `www.rootDomain` を明示的に除外している。

```ts
const RESERVED = ['www', 'app', 'admin', 'api', 'mail', 'static', 'cdn', 'blog'];
const sub = host.replace(`.${rootDomain}`, '');
const isTenant = host.endsWith(`.${rootDomain}`) && !RESERVED.includes(sub);
```

除外していないと、DNS 側で www を用意しても 404 にしかならず、**「apex が壊れたら www に逃がす」という定石が使えない。**

## 3. 推奨構成

```
example.com          A     転送サーバー       → 301 → app.example.com
www.example.com      CNAME ホスティング先     → 301 → app.example.com（予約）
app.example.com      CNAME ホスティング先     アプリ本体（APP_URL はここ）
*.example.com        CNAME ホスティング先     テナント用
customer.com         CNAME ホスティング先     顧客の独自ドメイン
```

**ホスティング先の IP がどこにも書かれていない**のが要点。

## 4. 障害のとき

**ドメイン障害では、DNS の外形調査より先にアプリのホスト判定コード（middleware.ts 等）を読む。** 読まずに DNS 変更を提案して悪化させた例がある（下）。

## 5. DNS・ネームサーバーを変えるとき

- 変更は「提案 → 承認 → 実行 → 本番の生存確認」。戻し方（元の NS・元の値）を記録してから
- 切替前に、新しい DNS サーバーへ直接 dig して全レコードを照合する
- メールの MX・SPF・DKIM・DMARC と、Resend など送信サービスのレコードを落とさない

## 教訓：2026-09-06 veloraxa.com が半日停止

Railway がエッジを `66.33.22.0/23` から `69.46.46.0/24` に移設。Railway に載る15ドメインのうち、**apex にアプリ本体を置いていた veloraxa.com だけ**が A レコードの IP 直打ちで取り残され、403 になった。他の14件は CNAME で無傷。

さらに `www` が予約されておらず未登録テナントとして 404 を返す設計だったため、www に逃がす復旧策も使えなかった。`NEXT_PUBLIC_APP_URL` を変えれば直せるが、認証コールバックと Stripe の戻り URL の11か所に波及するため断念し、IP 直打ちのまま復旧した。アプリのコードを読まずに DNS 変更を提案し、403 を 000 に悪化させた。
