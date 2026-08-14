#!/usr/bin/env bash
# headless 단위 테스트 일괄 실행.
set -uo pipefail

GODOT="${GODOT:-/Applications/Godot_4.7.1.app/Contents/MacOS/Godot}"
TIMEOUT_SEC="${TEST_TIMEOUT:-120}"
cd "$(dirname "$0")/.."

log=$(mktemp)
trap 'rm -f "$log"' EXIT

"$GODOT" --headless --path . res://tests/test_runner.tscn > "$log" 2>&1 &
pid=$!

# macOS에는 timeout(1)이 없어 직접 감시한다.
# 임포트가 안 된 새 클론에서는 러너가 끝나지 않고 매달린다 — 그때 여기서 끊는다.
for _ in $(seq 1 "$TIMEOUT_SEC"); do
	kill -0 "$pid" 2>/dev/null || break
	sleep 1
done

if kill -0 "$pid" 2>/dev/null; then
	kill -9 "$pid" 2>/dev/null
	cat "$log"
	echo ""
	echo "${TIMEOUT_SEC}초 안에 끝나지 않았다 — 러너가 멈췄다."
	echo "새로 클론했다면 임포트를 먼저 돌려라:"
	echo "  \"\$GODOT\" --headless --path . --import"
	exit 1
fi

wait "$pid"
code=$?
cat "$log"

# GDScript 컴파일/로드 실패는 종료 코드 0으로 나온다 — 출력도 같이 검사해야 한다.
if grep -qE 'SCRIPT ERROR|Failed to load script|Parse Error|Failed loading resource' "$log"; then
	echo ""
	echo "스크립트/리소스 에러 감지 — 실패 처리"
	exit 1
fi

exit $code
