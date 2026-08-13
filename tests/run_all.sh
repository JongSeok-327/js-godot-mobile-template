#!/usr/bin/env bash
# headless 단위 테스트 일괄 실행.
set -uo pipefail

GODOT="${GODOT:-/Applications/Godot_4.7.1.app/Contents/MacOS/Godot}"
cd "$(dirname "$0")/.."

output=$("$GODOT" --headless --path . res://tests/test_runner.tscn 2>&1)
code=$?
echo "$output"

# GDScript 컴파일/로드 실패는 종료 코드 0으로 나온다 — 출력도 같이 검사해야 한다.
if grep -qE 'SCRIPT ERROR|Failed to load script|Parse Error' <<<"$output"; then
	echo ""
	echo "스크립트 에러 감지 — 실패 처리"
	exit 1
fi

exit $code
