#!/bin/bash
# クラウド（Claude Code on the web）のセッション開始時に、GitHub の最新のグローバルルールを読み込む。
# 各リポの .claude/hooks/global-rules.sh にこのファイルをそのまま置き、.claude/settings.json の SessionStart から
#   bash "$CLAUDE_PROJECT_DIR/.claude/hooks/global-rules.sh" 1
#   bash "$CLAUDE_PROJECT_DIR/.claude/hooks/global-rules.sh" 2
# の2つを呼ぶ（フックの出力は1つ1万文字までなので、CLAUDE.md を前半・後半に分けて渡す）。
# 1 はスキルも ~/.claude/skills に入れて、再読み込み（reloadSkills）を頼む。
# デスクトップ（~/.claude/global-rules がある）では何もしない。失敗してもセッションは止めない（常に exit 0）。

PART="${1:-1}"
SRC="https://raw.githubusercontent.com/hideaki0320/claude-global-rules/main/CLAUDE.md"
TAR="https://codeload.github.com/hideaki0320/claude-global-rules/tar.gz/refs/heads/main"

[ -d "$HOME/.claude/global-rules/.git" ] && exit 0

md="$(curl -fsSL --max-time 15 "$SRC" 2>/dev/null)"
if [ -z "$md" ]; then
  [ "$PART" = "1" ] && echo "グローバルルールを GitHub から取得できませんでした（$SRC）。作業の前に WebFetch でこの URL を全文読み、読めなければ中森に報告すること。"
  exit 0
fi

n=$(printf '%s\n' "$md" | wc -l | tr -d ' ')
h=$(( (n + 1) / 2 ))
if [ "$PART" = "1" ]; then
  body="$(printf '%s\n' "$md" | sed -n "1,${h}p")"
  head="【グローバルルール（前半）】GitHub hideaki0320/claude-global-rules の最新。後半は別に読み込まれる。"
else
  body="$(printf '%s\n' "$md" | sed -n "$((h + 1)),\$p")"
  head="【グローバルルール（後半）】"
fi

reload=false
if [ "$PART" = "1" ]; then
  tmp="$(mktemp -d)"
  if curl -fsSL --max-time 20 "$TAR" 2>/dev/null | tar -xz -C "$tmp" --strip-components=1 2>/dev/null && [ -d "$tmp/skills" ]; then
    mkdir -p "$HOME/.claude/skills"
    cp -R "$tmp/skills/." "$HOME/.claude/skills/" && reload=true
  fi
  rm -rf "$tmp"
fi

text="$head
$body"
if command -v python3 >/dev/null 2>&1; then
  RELOAD="$reload" python3 -c 'import json,os,sys; o={"hookEventName":"SessionStart","additionalContext":sys.stdin.read()}
if os.environ.get("RELOAD")=="true": o["reloadSkills"]=True
print(json.dumps({"hookSpecificOutput":o},ensure_ascii=False))' <<< "$text"
else
  printf '%s\n' "$text"
fi
exit 0
