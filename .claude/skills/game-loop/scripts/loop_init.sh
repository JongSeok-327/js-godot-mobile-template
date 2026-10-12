#!/usr/bin/env bash
# 루프 작업 공간 준비. _workspace/loop/ 에 PROMPT·TASKS·PROGRESS 를 둔다.
# 이미 있으면 _workspace/loop_<시각>/ 로 보관하고 새로 만든다 (지우지 않는다).
#
#   .claude/skills/game-loop/scripts/loop_init.sh [최대 반복 수, 기본 15]
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
T=.claude/skills/game-loop/templates
W=_workspace/loop
MAX="${1:-15}"
if [ -d "$W" ]; then
  keep="_workspace/loop_$(date +%Y%m%d_%H%M%S)"
  # 같은 초에 두 번 돌면 이름이 겹친다 — 그러면 mv 가 기존 보관 폴더 "안으로" 넣는다.
  n=1; base="$keep"; while [ -e "$keep" ]; do keep="${base}_$n"; n=$((n+1)); done
  mv "$W" "$keep"; echo "기존 루프 기록 보관: $keep"
fi
mkdir -p "$W"
cp "$T/PROMPT.md" "$T/TASKS.md" "$T/PROGRESS.md" "$W/"
echo "준비됨: $W/{PROMPT,TASKS,PROGRESS}.md"
echo
echo "1) $W/TASKS.md 의 예시 줄을 지우고 실제 작업을 채운다."
echo "2) 다음을 Claude Code 프롬프트에 그대로 입력해 시작한다:"
echo
echo "/ralph-loop:ralph-loop _workspace/loop/PROMPT.md 를 읽고 처음부터 그대로 따르라 --max-iterations $MAX --completion-promise LOOP_DONE"
echo
echo "중단: /ralph-loop:cancel-ralph"
