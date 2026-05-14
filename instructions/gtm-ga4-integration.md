# 指示書: gtm-ga4-automation の DB を veloraxa Supabase プロジェクトに統合する

この指示書は中森さんから AI エージェント（Claude）への作業指示です。
読み込んだ Claude は、これに沿って Phase 1 から順番に進めてください。

---

## 0. 前提と禁則事項（最初に必ず読む）

### 対象 Supabase プロジェクト

▶ **veloraxa**（ref: `rkpnprhatxidaneyuxmw` / region: ap-northeast-1）

**他のプロジェクトには絶対に触らない**。SQL を実行する前に必ず project_ref を確認すること。

### 既存テーブル（触ってはダメ）

veloraxa の `public` スキーマには以下が既存：

- `users`（アプリのユーザー）
- `templates`（LP/ブログ/SNS テンプレ）
- `generations`（生成履歴）
- `lp_pages`（生成された LP）
- `lp_events`（LP のイベントログ）
- `blog_posts`（生成されたブログ）
- `leads`（LP 経由のリード）

**これらに ALTER / INSERT / UPDATE / DELETE / DROP 一切しない**。FK で参照するだけ（読み取りのみ）。書き込みが必要な場合は中森さんに事前確認。

### グローバル開発ルール（必読）

中森のグローバル開発ルールは以下を WebFetch で取得して全部適用：

```
https://raw.githubusercontent.com/hideaki0320/claude-global-rules/main/CLAUDE.md
```

特に厳守する 3 項目：

- §7: SQL を会話に貼る・対象プロジェクト名を明示（「▶ veloraxa の SQL Editor で実行」のように）
- §10: 本番DB書き込みは慎重に（DDL 実行前に schema 確認、対象 SELECT 結果保存、1 件テスト → 全件）
- §11: API 経由で DB を変えたら必ず git に migration を残す（git → API の順序厳守）

---

## 1. 全体の進め方

```
Phase 1: 設計確定（DB は触らない）
   ↓
Phase 2: migration ファイルを書いて git commit + push
   ↓
Phase 3: MCP で migration を順次適用（テーブル単位で確認）
   ↓
Phase 4: RLS（行レベル権限）を整備
   ↓
Phase 5: アプリのコードを書く
```

各 Phase を完了するまで次に進まない。

---

## 2. Phase 1: 設計確定

### 2-1. 必要なテーブル（最小スターター 7 個）

| テーブル | 役割 |
|---|---|
| `gtm.sites` | 計測対象のサイト 1 件 |
| `gtm.gtm_containers` | GTM コンテナの管理情報 |
| `gtm.ga4_properties` | GA4 プロパティの管理情報 |
| `gtm.tags` | GTM 内で設置したタグの記録 |
| `gtm.events` | GA4 のカスタムイベント定義 |
| `gtm.reports` | 月次レポートの履歴 |
| `gtm.google_oauth_tokens` | Google API へのアクセストークン保管 |

### 2-2. veloraxa 既存テーブルとの繋ぎ方

`gtm.sites` の主な FK：

- `owner_user_id` → `public.users.id`（誰が管理するか）
- `veloraxa_lp_id` → `public.lp_pages.id`（任意・NULLable）

veloraxa 製サイトでなくても登録できる（外部の WordPress / Wix / Shopify / 自作 etc.）。

### 2-3. 命名規則

- スキーマ: `gtm`
- 主キー: `id uuid primary key default gen_random_uuid()`
- timestamps: `created_at timestamptz default now()`, `updated_at timestamptz default now()`
- FK 列: `<参照先テーブル>_id`
- 命名: snake_case

### Phase 1 完了の確認

- [ ] 7 テーブル分の列定義を ER 図で書ききった
- [ ] veloraxa の public テーブルとの FK 関係が決まった
- [ ] 中森さんに確認を取った

---

## 3. Phase 2: migration ファイルを書く

### 3-1. ファイル構成

リポジトリ `gtm-ga4-automation` 内に：

```
db/migrations/
  20260514_2000_init_gtm_schema.sql
  20260514_2010_create_sites.sql
  20260514_2020_create_gtm_containers.sql
  20260514_2030_create_ga4_properties.sql
  20260514_2040_create_tags.sql
  20260514_2050_create_events.sql
  20260514_2060_create_reports.sql
  20260514_2070_create_google_oauth_tokens.sql
```

### 3-2. すべて冪等に書く

スキーマとテーブルの例：

```sql
-- スキーマ
create schema if not exists gtm;

-- テーブル
create table if not exists gtm.sites (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.users(id) on delete cascade,
  veloraxa_lp_id uuid references public.lp_pages(id) on delete set null,
  url text not null,
  cms_type text check (cms_type in ('veloraxa','wordpress','shopify','wix','other')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- インデックス
create index if not exists sites_owner_idx on gtm.sites(owner_user_id);
create index if not exists sites_veloraxa_lp_idx on gtm.sites(veloraxa_lp_id);

-- updated_at の自動更新
create or replace function gtm.set_updated_at()
returns trigger as $$
begin new.updated_at = now(); return new; end;
$$ language plpgsql;

create trigger sites_set_updated_at
  before update on gtm.sites
  for each row execute function gtm.set_updated_at();
```

### 3-3. git に commit + push

各 migration ファイル単位で：

```bash
git add db/migrations/20260514_2000_init_gtm_schema.sql
git commit -m "db: gtm スキーマを作成"
git push
```

**「migration ファイルが GitHub に push された後で MCP 実行」の順序を厳守**。

### Phase 2 完了の確認

- [ ] 全 migration が git にコミット & push 済み
- [ ] 各 SQL の DDL は `if not exists` で冪等

---

## 4. Phase 3: MCP で migration を適用

Supabase MCP コネクタを使う。**1 ファイルずつ順番に**。

### 4-1. 最初にスキーマ確認（読み取り）

▶ veloraxa の SQL Editor で実行（read）：

```sql
select schema_name from information_schema.schemata
where schema_name not like 'pg_%' and schema_name <> 'information_schema'
order by schema_name;
```

→ `gtm` がまだ無いことを確認

### 4-2. スキーマ作成

▶ veloraxa の SQL Editor で実行（write）：

```sql
create schema if not exists gtm;
```

→ 承認 → 実行 → 再度 4-1 で `gtm` が出現することを確認

### 4-3. テーブルを依存順に追加

順番：`sites` → `gtm_containers` → `ga4_properties` → `tags` → `events` → `reports` → `google_oauth_tokens`

各テーブルごとに：

1. ▶ veloraxa の SQL Editor で実行（write）：DDL を流す
2. 確認 SQL：

```sql
select column_name, data_type from information_schema.columns
where table_schema = 'gtm' and table_name = '<対象テーブル>'
order by ordinal_position;
```

3. 期待した列が全部出ることを確認してから次へ

### 4-4. 全テーブル完了後の総合確認

▶ veloraxa の SQL Editor で実行（read）：

```sql
select table_name from information_schema.tables
where table_schema = 'gtm'
order by table_name;
```

→ 7 行（sites, gtm_containers, ga4_properties, tags, events, reports, google_oauth_tokens）

### Phase 3 完了の確認

- [ ] 7 テーブルすべてが `information_schema.tables` で確認できた
- [ ] テーブル間の FK が正しく張られている

---

## 5. Phase 4: RLS（行レベル権限）

各 `gtm.*` テーブルに以下の方針で適用：

- `owner_user_id` が `auth.uid()` と一致する行のみ SELECT / UPDATE / DELETE 可
- INSERT 時は `owner_user_id` が `auth.uid()` であることを必須
- サイト所有者のみが自分のサイトに紐づく `gtm_containers` / `tags` 等を操作可

### 5-1. migration として追加

```
db/migrations/
  20260514_2100_rls_sites.sql
  20260514_2110_rls_gtm_containers.sql
  ... 各テーブル分
```

### 5-2. ポリシー雛形

```sql
alter table gtm.sites enable row level security;

create policy sites_select_own
  on gtm.sites for select
  to authenticated
  using (auth.uid() = owner_user_id);

create policy sites_insert_own
  on gtm.sites for insert
  to authenticated
  with check (auth.uid() = owner_user_id);

create policy sites_update_own
  on gtm.sites for update
  to authenticated
  using (auth.uid() = owner_user_id)
  with check (auth.uid() = owner_user_id);

create policy sites_delete_own
  on gtm.sites for delete
  to authenticated
  using (auth.uid() = owner_user_id);
```

### 5-3. 子テーブルの RLS

`gtm.tags` などは `site_id` 経由で所有者を判定：

```sql
alter table gtm.tags enable row level security;

create policy tags_select_own
  on gtm.tags for select
  to authenticated
  using (
    exists (
      select 1 from gtm.sites s
      where s.id = tags.site_id and s.owner_user_id = auth.uid()
    )
  );
-- insert / update / delete 同様
```

### Phase 4 完了の確認

- [ ] 全 `gtm.*` テーブルで `rowsecurity = true`
- [ ] 別ユーザーで SELECT したら 0 件になることをテスト

---

## 6. Phase 5: アプリコード

ここから初めて gtm-ga4-automation のフロント/バックエンド実装。

### 6-1. Supabase クライアント設定

```ts
// lib/supabase.ts
import { createClient } from "@supabase/supabase-js";

export const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
  { db: { schema: "gtm" } }
);
```

`NEXT_PUBLIC_SUPABASE_URL` は veloraxa の URL（`https://rkpnprhatxidaneyuxmw.supabase.co`）。
`NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` は §9 新形式の `sb_publishable_*` キー。

### 6-2. 型生成

```bash
npx supabase gen types typescript \
  --project-id rkpnprhatxidaneyuxmw \
  --schema gtm \
  > src/types/supabase.ts
```

### 6-3. ページ実装の順序

1. サイト登録フォーム（`gtm.sites` に INSERT）
2. サイト一覧（`gtm.sites` の SELECT）
3. GTM コンテナ連携（OAuth → `gtm.gtm_containers` 登録）
4. GA4 プロパティ連携
5. タグ自動配置
6. 月次レポート生成

各ステップで「使うテーブル」「実装する API」「UI のスクショ」を Phase 完了時に中森さんに見せて承認を取る。

### Phase 5 完了の確認

- [ ] サイト 1 件登録 → 一覧表示 → GTM/GA4 タグ自動配置 → ダミーレポート生成、まで通る
- [ ] 別ユーザーで同じ操作をしてもデータが混ざらない（RLS の最終テスト）

---

## 7. 進めるときに必ず守る運用

### 報告のタイミング

- 各 Phase の **開始時**：これから何をするかを宣言
- 各 Phase の **完了時**：成果物（migration ファイルパス、確認 SQL の結果、UI スクショ）を提示
- **詰まった時**：「詰まっている / 原因の見立て / 次に試す手」を即報告（沈黙しない）

### MCP 実行の前後

- 実行前: SQL を会話に**全文貼る**
- 実行前: 「▶ veloraxa の SQL Editor で実行」と明示
- 実行後: 確認 SQL を流して結果を提示

### git の運用

- migration を書く → commit + push → その後 MCP で実行
- 「あとで commit する」は禁止。順序逆転は事故の元
- コミットメッセージは「db: <短い説明>」or「migration: <短い説明>」

---

## 8. 開始

Phase 1（設計確定）の 2-1 から始めてください。  
最初の成果物として **7 テーブルの ER 図（テキストでも図解でも）** を出して、中森さんの承認を取った後に Phase 2 に進むこと。
