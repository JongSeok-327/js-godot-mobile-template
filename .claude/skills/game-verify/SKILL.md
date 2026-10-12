---
name: game-verify
description: 이 Godot 4.7.1 프로젝트의 변경을 스모크·씬별 스모크·단위 테스트·누수 기준선으로 판정한다. 코드·씬·에셋·preset 을 바꾼 뒤, 커밋 전에, "테스트 돌려줘", "검증해줘", "깨진 거 없나" 요청에 사용한다. 기기 동작 확인(광고·햅틱·레이아웃)은 이 스킬이 아니라 game-device-qa 다.
---

# game-verify

## 판정은 스크립트 한 번으로 한다

```bash
tools/verify.sh            # 평소
tools/verify.sh --import   # 새 클론·새 에셋·새 번역·새 스크립트(.uid)
```

마지막 줄이 `VERDICT: PASS` 또는 `VERDICT: FAIL`, 종료 코드도 같다.
씬별 스모크는 `SceneManager.SCENES` 에 등록된 씬을 전부 돈다 — 씬을 추가하면 따로 고칠 것이 없다.
전체 스크립트 파스(`tools/parse_check.gd`)는 어디서도 참조하지 않는 스크립트까지 로드해 본다 —
`PARSE FAIL: <경로>` 줄이 나오면 그 파일이다.

**직접 Godot 을 불러 grep 하지 않는다.** 스크립트가 이미 다음 함정을 다 막는다:
- GDScript 에러는 종료 코드 0 으로 나온다 → 출력 문자열로 판정한다.
- `run_all.sh` 의 스크립트 에러는 "통과 N / 실패 0" **뒤에** 따로 찍힌다 → 요약 줄만 보면 실패를 통과로 읽는다.
- 누수 숫자는 0 이 아니어도 정상일 수 있다 → 기준선과 비교해야 한다.

## 누수 기준선

`tools/verify.sh` 의 `LEAK_OBJECTDB_MAX` / `LEAK_RESOURCE_MAX` (템플릿 기준 4 / 2) 이하가 정상이다 (CLAUDE.md "테스트").
효과음 `preload` 상수가 붙든 오디오 스트림은 누수 보고보다 늦게 해제돼 무해한 누수로 잡힌다.

넘으면 새 누수다. 타입을 확인한다:
```bash
"$GODOT" --headless --verbose --path . res://tests/test_runner.tscn 2>&1 | grep -A40 "Leaked instance"
```
- 전부 오디오(`AudioStream*`, `OggPacket*`)이고 새 테스트가 새 효과음을 재생했다면 → 기준선을 올린다. `verify.sh` 와 CLAUDE.md 를 **같이** 고친다.
- `Node` 등 다른 타입이 보이면 → 진짜 누수다. 기준선을 올리지 않는다.

## FAIL 일 때 보고

출력에 나온 `✗` 줄과 `SCRIPT ERROR` 줄을 **원문 그대로** 인용한다. 원인을 추측해 덧붙이지 않는다 — 고치는 쪽이 원문을 보고 판단한다.
