---
name: game-loop
description: 확인된 버그·작업 목록을 ralph-loop 로 사람 없이 하나씩 처리하는 루프 엔지니어링 절차. 작업 목록(TASKS) 준비, 시작 명령, 객관적 완료 판정(loop_gate.sh), 중단·회고를 다룬다. "루프로 돌려줘", "밤새 고쳐줘", "다 고칠 때까지 반복", "점검 결과 전부 처리", "ralph" 요청과 루프 재개·결과 정리 요청에 사용한다. 한 건을 지금 바로 고치는 일은 game-orchestrator 흐름 1 이다.
---

# game-loop

ralph-loop 는 응답이 끝날 때마다 **같은 프롬프트**를 다시 넣는다(Stop hook). 이 스킬은 거기에 두 가지를 더한다:

1. **기억은 파일에** — 프롬프트가 매번 같으므로 진행 상황은 `_workspace/loop/TASKS.md`(할 일)와 `PROGRESS.md`(한 일)에만 있다.
2. **끝은 게이트가 정한다** — ralph 의 완료 판정은 모델이 `<promise>` 를 쓰는 것뿐이다. 그래서 `loop_gate.sh` 가 `OPEN` 을 낼 때만 쓰게 한다. 게이트는 작업 목록·`verify.sh`·커밋 상태를 직접 본다.

## 루프에 맞는 일 / 안 맞는 일

| 맞는다 | 안 맞는다 (목록에 넣지 않는다) |
|---|---|
| 재현 테스트로 "고쳐졌다"를 판정할 수 있는 버그 | 기기에서만 보이는 문제(광고·햅틱·레이아웃) |
| 흐름 2 점검에서 **confirmed** 된 항목 | 아트·아이콘·색감처럼 취향이 걸린 일 |
| 테스트 보강, 문서-코드 불일치 수정 | 계정·키·스토어 설정 (사람 작업) |
| | 설계 결정이 필요한 일 ("어떤 방식으로 할지"가 열려 있음) |

애매하면 넣지 않는다. 루프는 판단을 대신하지 않는다 — 판단이 필요한 작업은 루프 안에서 `[BLOCKED]` 로 끝날 뿐이다.

## 절차

### 1. 작업 목록 만들기

보통은 `game-orchestrator` **흐름 2(전체 점검)** 결과에서 시작한다:
1. 흐름 2 워크플로의 `confirmed` 를 사용자에게 보여준다.
2. **사용자가 고른 것만** 작업으로 만든다. 각 줄에 파일·줄, 재현 시나리오(입력/상태 → 기대 / 실제)를 적는다. 루프는 그 줄만 보고 일한다 — 맥락을 줄에 담아라.
3. 위험이 큰 것부터 위에 둔다. 루프는 위에서부터 처리한다.

### 2. 준비와 시작

```bash
.claude/skills/game-loop/scripts/loop_init.sh 15     # 최대 반복 15
```
`_workspace/loop/` 에 `PROMPT.md`·`TASKS.md`·`PROGRESS.md` 가 생긴다 (기존 것은 시각 붙여 보관). 메인이 `TASKS.md` 를 채운 뒤, 출력된 시작 명령을 **사용자가 입력**한다 (슬래시 명령은 사용자만 입력할 수 있다):

```
/ralph-loop:ralph-loop _workspace/loop/PROMPT.md 를 읽고 처음부터 그대로 따르라 --max-iterations 15 --completion-promise LOOP_DONE
```

명령 이름은 **`/ralph-loop:ralph-loop`** 다 (플러그인 명령은 플러그인 이름이 접두어로 붙는다). 플러그인 README 의 `/ralph-loop` 는 이 환경에서 "Unknown command" 가 된다 — kongkong 첫 실전에서 실제로 그랬다.

프롬프트를 파일 포인터로 두는 이유: 슬래시 명령 인자는 단어 단위로 이어 붙여져 상태 파일에 들어가므로 긴 규칙을 넣으면 따옴표·줄바꿈이 깨진다. 규칙은 `PROMPT.md` 에서 고치면 다음 반복부터 반영된다.

`--max-iterations` 는 **항상** 준다. 작업 수 × 1.5 정도 (막히는 작업은 두 번 시도한다).

### 3. 도는 동안

반복 하나 = 작업 하나: 재현 테스트(실패 확인) → 수정 → `verify.sh` → 커밋 + `[x]` + PROGRESS 한 줄. 두 번 FAIL 이면 되돌리고 `[BLOCKED]`. 세부 규칙은 `templates/PROMPT.md`.

권한 창이 뜨면 루프가 거기서 멈춘다. 루프가 쓰는 명령(`tools/verify.sh`, `./tests/run_all.sh`, `git add`·`commit`)을 `.claude/settings.local.json` 에 미리 허용해 둔다 (`git push`·`reset --hard`·삭제는 허용하지 않는다). 공유 `.claude/settings.json` 의 deny 목록이 강제 푸시·`reset --hard`·`rm -rf`·`git clean -f` 를 막는다.

### 4. 끝·중단

- 정상 종료: 게이트 `OPEN` → `<promise>LOOP_DONE</promise>` → Stop hook 이 상태 파일을 지운다.
- 상한 도달: 상태 파일이 지워지고 그냥 멈춘다. `TASKS.md` 에 남은 `- [ ]` 가 미처리분이다.
- 수동 중단: `/ralph-loop:cancel-ralph`. 진행 중이던 작업의 커밋 안 된 변경은 남는다 — `git status` 로 확인.

### 5. 정리와 회고

1. `TASKS.md` 의 `[x]`/`[BLOCKED]`/`[ ]` 수와 `git log` 의 루프 커밋을 사용자에게 보고한다. `[BLOCKED]` 는 사유와 함께 따로 묶는다 — 사람이 볼 것들이다.
2. 기기 확인이 필요한 커밋(광고·저장·플랫폼)이 있으면 `game-device-qa` 를 돌린다. 루프는 기기를 보지 않는다.
3. `PROGRESS.md` 에 같은 종류의 막힘이 반복됐으면 `harness:evolve` 로 에이전트·스킬·`PROMPT.md` 에 반영한다 (바깥 루프).

## 게이트

```bash
.claude/skills/game-loop/scripts/loop_gate.sh [TASKS 파일]
```
OPEN 조건: 대기 작업 0 · `verify.sh` PASS · 커밋 안 된 변경 없음 (`_workspace/` 는 gitignore). `[BLOCKED]` 는 대기로 치지 않는다 — 막힌 작업 때문에 루프가 끝나지 못하면 상한까지 헛돈다. 막힘은 끝난 뒤 사람이 본다.
