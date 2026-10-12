#!/usr/bin/env bash
# 루프 완료 판정. 모델의 "다 됐다" 선언 대신 이것의 출력으로 끝을 정한다.
# 마지막 줄: LOOP_GATE: OPEN | CLOSED   (종료 코드 0 | 1)
#
#   .claude/skills/game-loop/scripts/loop_gate.sh [TASKS 파일]
#
# OPEN 조건 (셋 다):
#   1. 작업 목록에 대기(- [ ]) 가 0 개
#   2. verify.sh PASS
#   3. 커밋 안 된 변경이 없다 (gitignore 된 _workspace 는 제외 — 거기 기록만 남는다)
# LOOP_GATE_SKIP_VERIFY=1 은 게이트 자체를 시험할 때만 쓴다.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
VLOG=$(mktemp); trap 'rm -f "$VLOG"' EXIT
TASKS="${1:-_workspace/loop/TASKS.md}"
open=1

if [ ! -f "$TASKS" ]; then
  echo "작업 목록 없음: $TASKS"; open=0
else
  pending=$(grep -cE '^- \[ \]' "$TASKS" || true)
  done_n=$(grep -cE '^- \[x\]' "$TASKS" || true)
  blocked=$(grep -cE '^- \[BLOCKED\]' "$TASKS" || true)
  echo "작업: 완료 $done_n · 막힘 $blocked · 대기 $pending"
  [ "$pending" -eq 0 ] || { echo "대기 작업이 남아 있다"; open=0; }
fi

dirty=$(git status --porcelain)
if [ -n "$dirty" ]; then
  echo "커밋 안 된 변경:"; echo "$dirty" | head -10; open=0
fi

if [ "${LOOP_GATE_SKIP_VERIFY:-0}" = "1" ]; then
  echo "verify: 건너뜀 (게이트 시험 모드)"
elif [ $open -eq 1 ]; then
  # 앞 조건이 이미 닫혔으면 오래 걸리는 판정은 돌리지 않는다.
  if tools/verify.sh > $VLOG 2>&1; then
    echo "verify: PASS ($(grep -E '통과 [0-9]+' $VLOG | tr -s ' '))"
  else
    echo "verify: FAIL"; grep -E "✗|SCRIPT ERROR|실패|초과" $VLOG | head -8; open=0
  fi
fi

if [ $open -eq 1 ]; then echo "LOOP_GATE: OPEN"; exit 0; else echo "LOOP_GATE: CLOSED"; exit 1; fi
