#!/bin/bash
# デスクトップでセッション開始時に、グローバルルール（このリポ）を GitHub の最新にする。
# ~/.claude/settings.json の SessionStart フックから呼ぶ。失敗してもセッションは止めない（常に exit 0）。
R="$HOME/.claude/global-rules"
[ -d "$R/.git" ] || exit 0
before=$(git -C "$R" rev-parse HEAD 2>/dev/null) || exit 0
GIT_TERMINAL_PROMPT=0 git -C "$R" pull --ff-only -q >/dev/null 2>&1 || exit 0
after=$(git -C "$R" rev-parse HEAD 2>/dev/null) || exit 0
if [ "$before" != "$after" ]; then
  n=$(git -C "$R" log --oneline "$before..$after" | wc -l | tr -d ' ')
  echo "グローバルルール（~/.claude/CLAUDE.md・~/.claude/skills）が GitHub から更新されました（${n}件）。このセッションが読み込んだ CLAUDE.md は古い可能性があるので、最初に ~/.claude/CLAUDE.md を読み直すこと。"
  git -C "$R" log --oneline "$before..$after" | head -10
fi
exit 0
