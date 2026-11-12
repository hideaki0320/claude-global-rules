#!/bin/bash
set -euo pipefail

# Railway プレビュー環境セットアップスクリプト
# 使い方: プロジェクトディレクトリで実行
#   ~/.claude/scripts/setup-railway-preview.sh

PREVIEW_BRANCH="preview"
PREVIEW_ENV="preview"

echo "=== Railway プレビュー環境セットアップ ==="
echo ""

# 前提チェック
if ! command -v railway &>/dev/null; then
  echo "ERROR: railway CLI が見つかりません。brew install railway でインストールしてください。"
  exit 1
fi

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "ERROR: git リポジトリ内で実行してください。"
  exit 1
fi

# Railway にリンク済みか確認
if ! railway status &>/dev/null 2>&1; then
  echo "ERROR: Railway プロジェクトにリンクされていません。"
  echo "  railway link でプロジェクトをリンクしてください。"
  exit 1
fi

# サービス名を取得
SERVICE_NAME=$(railway service list --json 2>/dev/null | python3 -c "
import sys, json
services = json.load(sys.stdin)
linked = [s for s in services if s.get('isLinked')]
print(linked[0]['name'] if linked else '')
" 2>/dev/null || echo "")

if [ -z "$SERVICE_NAME" ]; then
  echo "ERROR: リンク済みのサービスが見つかりません。"
  exit 1
fi

echo "プロジェクト: $(basename "$(pwd)")"
echo "サービス: $SERVICE_NAME"
echo ""

# 1. preview ブランチ作成
echo "[1/4] preview ブランチ作成..."
CURRENT_BRANCH=$(git branch --show-current)

if git show-ref --verify --quiet "refs/heads/$PREVIEW_BRANCH" 2>/dev/null; then
  echo "  -> $PREVIEW_BRANCH ブランチは既に存在します（スキップ）"
else
  git branch "$PREVIEW_BRANCH" main
  echo "  -> $PREVIEW_BRANCH ブランチを main から作成しました"
fi

if git ls-remote --heads origin "$PREVIEW_BRANCH" | grep -q "$PREVIEW_BRANCH"; then
  echo "  -> リモートに $PREVIEW_BRANCH は既に存在します（スキップ）"
else
  git push -u origin "$PREVIEW_BRANCH"
  echo "  -> リモートに $PREVIEW_BRANCH を push しました"
fi

# 2. Railway preview 環境作成
echo ""
echo "[2/4] Railway preview 環境作成..."
EXISTING_ENVS=$(railway environment list --json 2>/dev/null | python3 -c "
import sys, json
envs = json.load(sys.stdin)
print(' '.join(e['name'] for e in envs))
" 2>/dev/null || echo "")

if echo "$EXISTING_ENVS" | grep -qw "$PREVIEW_ENV"; then
  echo "  -> $PREVIEW_ENV 環境は既に存在します（スキップ）"
else
  railway environment new "$PREVIEW_ENV" --duplicate production
  echo "  -> $PREVIEW_ENV 環境を production から複製しました"
fi

# 3. preview 環境のソースブランチを設定
# 注意: `railway environment edit --service-config <svc> source.branch preview` は
# 「設定しました」と出るが、実際のデプロイ元（deploymentTrigger の branch）は main のまま変わらない
# （2026-11-12 maltese-site で確認）。そのため GraphQL の deploymentTrigger を直接読んで更新し、
# 読み直して preview になっていることを確かめる。既に preview なら何もしない（冪等）。
echo ""
echo "[3/4] ソースブランチを $PREVIEW_BRANCH に設定..."
STATUS_JSON=$(railway status --json)
STATUS_JSON="$STATUS_JSON" python3 - "$PREVIEW_ENV" "$SERVICE_NAME" "$PREVIEW_BRANCH" <<'PY'
import json, os, sys, time, urllib.request, urllib.error

env_name, svc_name, want = sys.argv[1], sys.argv[2], sys.argv[3]
st = json.loads(os.environ["STATUS_JSON"])
project_id = st["id"]
envs = {e["node"]["name"]: e["node"]["id"] for e in st["environments"]["edges"]}
svcs = {s["node"]["name"]: s["node"]["id"] for s in st["services"]["edges"]}
if env_name not in envs or svc_name not in svcs:
    sys.exit(f"ERROR: 環境 {env_name} またはサービス {svc_name} が見つかりません")
env_id, svc_id = envs[env_name], svcs[svc_name]

cfg = json.load(open(os.path.expanduser("~/.railway/config.json")))
token = os.environ.get("RAILWAY_API_TOKEN") or cfg.get("user", {}).get("accessToken") or cfg.get("user", {}).get("token")
if not token:
    sys.exit("ERROR: Railway のトークンが見つかりません。railway login してください")

def gql(query, variables):
    req = urllib.request.Request(
        "https://backboard.railway.com/graphql/v2",
        data=json.dumps({"query": query, "variables": variables}).encode(),
        headers={"Authorization": "Bearer " + token, "Content-Type": "application/json",
                 "User-Agent": "setup-railway-preview"})
    try:
        res = json.load(urllib.request.urlopen(req, timeout=30))
    except urllib.error.HTTPError as e:
        sys.exit(f"ERROR: Railway API {e.code}（トークン切れなら railway login）: {e.read()[:300]!r}")
    if res.get("errors"):
        sys.exit(f"ERROR: Railway API: {res['errors']}")
    return res["data"]

Q = """query($p:String!,$e:String!,$s:String!){
  deploymentTriggers(projectId:$p, environmentId:$e, serviceId:$s){ edges{ node{ id branch repository } } } }"""

def triggers(eid):
    d = gql(Q, {"p": project_id, "e": eid, "s": svc_id})
    return [x["node"] for x in d["deploymentTriggers"]["edges"]]

# 環境を複製した直後はトリガーがまだ無いことがあるので少し待つ
trs = []
for _ in range(6):
    trs = triggers(env_id)
    if trs:
        break
    time.sleep(5)
if not trs:
    sys.exit(f"ERROR: {env_name} 環境に GitHub のデプロイトリガーがありません。"
             f"先に railway service source connect --repo <owner/repo> --branch main で GitHub に接続してください")

for t in trs:
    if t["branch"] == want:
        print(f"  -> {t['repository']} は既に {want} ブランチからデプロイされます（スキップ）")
        continue
    print(f"  -> {t['repository']}: {t['branch']} -> {want} に変更します")
    gql("mutation($id:String!,$b:String!){ deploymentTriggerUpdate(id:$id, input:{branch:$b}){ id branch } }",
        {"id": t["id"], "b": want})

# 読み直して確かめる
bad = [t for t in triggers(env_id) if t["branch"] != want]
if bad:
    sys.exit(f"ERROR: {env_name} 環境のデプロイ元が {want} になっていません: {bad}")
print(f"  -> 確認済み: {env_name} 環境のデプロイ元は {want} ブランチです")

# 本番側が preview になっていないかも確かめる（変更はしない）
if "production" in envs:
    prod = triggers(envs["production"])
    for t in prod:
        if t["branch"] == want:
            sys.exit(f"ERROR: production 環境のデプロイ元が {want} になっています。確認してください: {t}")
    if prod:
        print(f"  -> production 環境のデプロイ元: {', '.join(t['branch'] for t in prod)}")
PY

# 4. preview 環境にサービスドメインを生成
echo ""
echo "[4/4] プレビュー用ドメイン生成..."
PREVIEW_DOMAINS=$(railway domain list --environment "$PREVIEW_ENV" --service "$SERVICE_NAME" --json 2>/dev/null | python3 -c "
import sys, json
domains = json.load(sys.stdin)
service_domains = [d['domain'] for d in domains if d.get('projectDomain')]
print(' '.join(service_domains))
" 2>/dev/null || echo "")

if [ -n "$PREVIEW_DOMAINS" ]; then
  echo "  -> ドメインは既に存在します: $PREVIEW_DOMAINS"
else
  railway domain --environment "$PREVIEW_ENV" --service "$SERVICE_NAME" 2>/dev/null
  echo "  -> Railway サービスドメインを生成しました"
fi

# 完了
echo ""
echo "=== セットアップ完了 ==="
echo ""
echo "使い方:"
echo "  1. preview ブランチにコードを push してプレビュー確認"
echo "     git checkout preview && git merge main && git push"
echo "  2. 問題なければ main に push して本番デプロイ"
echo "     git checkout main && git push"
echo ""
echo "プレビュー URL:"
railway domain list --environment "$PREVIEW_ENV" --service "$SERVICE_NAME" 2>/dev/null || echo "  (railway domain list --environment preview で確認)"
echo ""

# 元のブランチに戻る
if [ "$CURRENT_BRANCH" != "$(git branch --show-current)" ]; then
  git checkout "$CURRENT_BRANCH" 2>/dev/null
fi
