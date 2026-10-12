#!/usr/bin/env bash
# 검증 한 번에: 스모크 → 전체 스크립트 파스 → 씬별 스모크 → 단위 테스트 → 누수 기준선 판정.
# 결과는 마지막 줄 "VERDICT: PASS|FAIL" 로 끝난다. 종료 코드도 같다(0/1).
#
#   tools/verify.sh [--import]
#
# 왜 스크립트인가: GDScript 에러는 종료 코드 0 으로 나오고, "통과 N / 실패 0" 뒤에
# 스크립트 에러가 따로 찍히며, 누수 숫자는 기준선과 비교해야 의미가 있다.
# 사람(과 에이전트)이 매번 이걸 기억해 grep 하면 언젠가 하나를 빠뜨린다.
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/Applications/Godot_4.7.1.app/Contents/MacOS/Godot}"
# 누수 기준선 (CLAUDE.md "테스트"). 바꾸면 그 문단도 같이 고친다.
LEAK_OBJECTDB_MAX="${LEAK_OBJECTDB_MAX:-4}"
LEAK_RESOURCE_MAX="${LEAK_RESOURCE_MAX:-2}"
ERR_PATTERN="SCRIPT ERROR|Parse Error|Failed to load"
fail=0
note() { echo "  $*"; }

if [ "${1:-}" = "--import" ]; then
  echo "== 임포트"
  "$GODOT" --headless --path . --import >/dev/null 2>&1
fi

echo "== 스모크"
out=$("$GODOT" --headless --path . --quit 2>&1 | grep -E "$ERR_PATTERN")
if [ -n "$out" ]; then echo "$out" | head -5; fail=1; else note "OK"; fi

# 스모크는 참조되는 스크립트만 컴파일한다 — 아직 안 붙인 스크립트까지 전부 파싱한다.
echo "== 전체 스크립트 파스"
out=$("$GODOT" --headless --path . -s res://tools/parse_check.gd 2>&1)
if echo "$out" | grep -q "PARSE FAIL"; then
  echo "$out" | grep -E "PARSE FAIL|Parse Error" | head -6; fail=1
else
  note "$(echo "$out" | grep -E "^parse_check:" || echo "요약 줄 없음")"
fi

# 씬 목록은 SceneManager.SCENES 레지스트리에서 읽는다 — 씬을 추가하면 여기도 자동으로 돈다.
echo "== 씬별 스모크"
scenes=$(grep -oE '"res://[^"]+\.tscn"' autoload/scene_manager.gd | tr -d '"')
n=0; scene_fail=0
for s in $scenes; do
  n=$((n + 1))
  out=$("$GODOT" --headless --path . "$s" --quit-after 40 2>&1 | grep -E "$ERR_PATTERN")
  if [ -n "$out" ]; then note "$s: 실패"; echo "$out" | head -3; scene_fail=1; fi
done
[ $scene_fail -eq 0 ] && note "OK (${n}개 씬)" || fail=1

echo "== 단위 테스트"
log=$(mktemp); trap 'rm -f "$log"' EXIT
./tests/run_all.sh > "$log" 2>&1; rc=$?
summary=$(grep -E "^통과 [0-9]+ / 실패 [0-9]+" "$log" | tail -1)
note "${summary:-요약 줄 없음 — 러너가 끝나지 않았거나 컴파일 실패}"
grep -E "^  ✗" "$log" | head -10
if [ $rc -ne 0 ] || [ -z "$summary" ] || ! echo "$summary" | grep -q "실패 0$"; then
  grep -E "$ERR_PATTERN|초 안에 끝나지" "$log" | head -5
  fail=1
fi

echo "== 누수 기준선 (ObjectDB ≤ $LEAK_OBJECTDB_MAX, resource ≤ $LEAK_RESOURCE_MAX)"
odb=$(grep -oE "[0-9]+ ObjectDB instances were leaked" "$log" | grep -oE "^[0-9]+" | tail -1)
res=$(grep -oE "[0-9]+ resources still in use" "$log" | grep -oE "^[0-9]+" | tail -1)
odb=${odb:-0}; res=${res:-0}
note "ObjectDB $odb / resource $res"
if [ "$odb" -gt "$LEAK_OBJECTDB_MAX" ] || [ "$res" -gt "$LEAK_RESOURCE_MAX" ]; then
  note "기준선 초과 — 새 누수다. 타입 확인: \"\$GODOT\" --headless --verbose --path . res://tests/test_runner.tscn"
  fail=1
fi

if [ $fail -eq 0 ]; then echo "VERDICT: PASS"; exit 0; else echo "VERDICT: FAIL"; exit 1; fi
