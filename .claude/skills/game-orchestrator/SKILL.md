---
name: game-orchestrator
description: 이 Godot 모바일 게임 프로젝트의 작업을 종류별 흐름으로 묶는 하네스 진입점. 기능 추가·버그 수정, 전체 점검(코드 리뷰·감사), 기기 확인, 출시 준비, 반복 수정 루프("루프로", "밤새", "다 고칠 때까지", "반복해서") 요청에 사용한다. "~고쳐줘", "~추가해줘", "전체 점검", "개선할 부분 찾아줘", "출시 준비", 그리고 후속 요청("다시 실행", "그 부분만 다시", "이전 결과 바탕으로 보완", "검증만 다시")에도 사용한다. 단순 질문·설명 요청에는 쓰지 않고 직접 답한다.
---

# game-orchestrator

요청을 아래 다섯 흐름 중 하나로 분류해 실행한다. 둘 이상이 섞이면 순서대로 잇는다.

## 0단계: 맥락 확인

- `git status` — 작업 트리가 더러우면 사용자에게 먼저 알린다 (남의 변경 위에 덮어쓰지 않는다).
- `_workspace/` 가 있고 "그 부분만 다시"류 요청이면 해당 단계만 다시 돌린다. 새 요청이면 `_workspace/` 를 `_workspace_<날짜>/` 로 옮기고 새로 시작한다.
- 워크플로를 다시 돌리는 요청이고 직전 `runId` 가 있으면 `resumeFromRunId` 로 재개한다.

## 흐름 1 — 기능 추가·버그 수정

**실행 모드:** 서브에이전트 위임

1. 구현: 직접 하거나 `Agent(subagent_type: "godot-prompter:godot-game-dev")`. **버그는 재현 테스트를 먼저 쓰고**, 실패를 확인한 뒤 고친다.
2. 판정: `Agent(subagent_type: "game-verifier")`. FAIL 이면 1로 돌아간다 (최대 2회, 그 뒤엔 사용자에게 보고).
3. 기기 확인: 광고·저장·네트워크·수명주기·레이아웃·플랫폼 분기를 건드렸으면 `Agent(subagent_type: "game-device-qa")` 에 **바꾼 것**을 알려 해당 목록만 확인시킨다.
4. CLAUDE.md 의 계약을 바꿨거나 새 함정을 밟았으면 CLAUDE.md 를 갱신한다.
5. 커밋 (메시지에 왜·어떻게 확인했는지).

## 흐름 2 — 전체 점검

**실행 모드:** 워크플로 조율 (`Workflow` — 이 스킬을 불러온 것이 실행 동의다). **`Workflow` 가 없으면 아래 "대체 경로" 로 같은 구조를 돌린다.**

이 흐름의 본질은 **구조**다: 영역별 점검 → 발견 하나마다 반박 검증 → `confirmed` 만 보고. 실행 도구는 갈아 끼울 수 있다. 도구는 세션 설정에 따라 꺼져 있을 수 있으므로(kongkong 2026-10-03 실행에서 "Workflow is disabled for this session"), 도구가 없다고 흐름을 건너뛰거나 검증 단계를 생략하지 않는다.

메인이 먼저 점검 영역을 정해 `args.dimensions` 로 넘긴다. 기본 3개, 사용자가 "철저히"라고 하면 늘린다. 기본 영역:

| key | 범위 |
|---|---|
| `persistence` | `autoload/save_manager.gd`, `autoload/settings.gd`, 게임 데이터 스크립트 — 저장 원자성, int/float, 마이그레이션, 이중 지급 |
| `flow-ads` | `scenes/`, `scenes/overlays/`, `scripts/services/*ad*` — 일시정지·뒤로가기·수명주기, 광고 응답 소비, 버튼 상태 |
| `services-platform` | `autoload/services.gd`, `scripts/services/`, `export_presets.cfg` — 네트워크 실패 경로, 플랫폼 분기, export 필터 |

게임을 얹으면 게임 핵심 로직(상태머신·경제 등)을 별도 영역으로 추가한다.

```javascript
export const meta = {
  name: 'game-audit',
  description: '영역별 코드 점검 후 발견마다 반박 검증해 확인된 것만 남긴다',
  phases: [{ title: '점검' }, { title: '검증' }],
}

const FINDINGS = { type: 'object', required: ['findings'], properties: {
  findings: { type: 'array', items: { type: 'object',
    required: ['title', 'file', 'line', 'scenario', 'severity'], properties: {
      title: { type: 'string' }, file: { type: 'string' }, line: { type: 'integer' },
      scenario: { type: 'string', description: '구체적 입력/상태 → 잘못된 결과' },
      severity: { type: 'string', enum: ['high', 'medium', 'low'] } } } } } }
const VERDICT = { type: 'object', required: ['status', 'reason'], properties: {
  status: { type: 'string', enum: ['confirmed', 'refuted', 'uncertain'] },
  reason: { type: 'string' } } }

const results = await pipeline(
  args.dimensions,
  d => agent(
    `Godot 4.7.1 GDScript 저장소에서 다음 영역을 줄 단위로 읽고 **실제로 잘못 동작하는** 버그만 찾아라. 스타일·취향은 제외.\n` +
    `영역: ${d.key} — ${d.scope}\n` +
    `먼저 CLAUDE.md 를 읽어라. 거기 적힌 계약·함정은 이미 의도된 설계다 — 그걸 버그로 보고하지 마라.\n` +
    `godot-prompter:godot-code-review 스킬이 있으면 불러와 참고하라. 각 발견에 구체적 재현 시나리오(입력/상태 → 잘못된 결과)를 적어라. 확신 없는 것은 넣지 마라.`,
    { label: `점검:${d.key}`, phase: '점검', schema: FINDINGS, model: 'opus' }),
  review => parallel((review?.findings ?? []).map(f => () =>
    agent(
      `다음 버그 보고를 **반박하려고** 검증하라. 해당 파일과 호출 경로를 직접 읽고, 시나리오가 실제로 일어나는지 확인하라. ` +
      `CLAUDE.md 의 설계 결정과 충돌하면 refuted. 재현 경로가 코드로 확인되면 confirmed, 판단 불가면 uncertain.\n${JSON.stringify(f)}`,
      { label: `검증:${f.file}:${f.line}`, phase: '검증', schema: VERDICT, model: 'opus', effort: 'high' })
      .then(v => ({ ...f, verdict: v }))))
)
const all = results.flat().filter(Boolean)
const confirmed = all.filter(f => f.verdict?.status === 'confirmed')
const uncertain = all.filter(f => f.verdict?.status === 'uncertain')
log(`발견 ${all.length}건 중 확인 ${confirmed.length}건, 판단 보류 ${uncertain.length}건`)
return { confirmed, uncertain, refutedCount: all.length - confirmed.length - uncertain.length }
```

`args` 예: `{ "dimensions": [{ "key": "persistence", "scope": "autoload/save_manager.gd, autoload/settings.gd — 저장 원자성, int/float, 마이그레이션" }, ...] }`

### 대체 경로 — `Workflow` 가 없을 때 (서브에이전트)

같은 두 단계를 `Agent` 도구로 돌린다. kongkong 에서 이 방식으로 10건 → 확인 8 · 보류 1 · 반박 1 을 얻었다.

1. **점검:** 영역마다 `Agent(subagent_type: "general-purpose", model: "opus", run_in_background: true)` 를 **한 메시지에 병렬로** 띄운다. 프롬프트에 넣을 것:
   - 영역 파일 목록과 관심사 (위 표)
   - **읽기 전용** ("파일은 고치지 마라", 네트워크 영역이면 "실서버에 요청하지 마라")
   - CLAUDE.md 를 먼저 읽고 거기 적힌 계약을 버그로 보고하지 말 것
   - **이미 고친 것**(`git log` 최근 커밋)과 **이미 아는 미해결**을 명시해 다시 보고하지 않게 할 것 — 안 넣으면 점검이 아는 얘기로 채워진다
   - 출력은 `FINDINGS` 스키마와 같은 JSON 하나
2. **검증:** 점검 결과가 **도착하는 대로** 발견마다 반박 검증 에이전트를 붙인다 (다른 영역이 끝나길 기다리지 않는다 — `pipeline()` 과 같은 효과). 프롬프트에 넣을 것:
   - 발견 원문(JSON)과 "반박하려고 검증하라", 출력은 `VERDICT` 스키마
   - **"특히 확인할 것"** — 그 주장이 기대고 있는 전제를 짚어 준다 (도달 가능한 상태인가, 외부 규칙은 공식 문서로 확인했나, 수치는 상수로 계산했나). kongkong 에서 이 항목 덕분에 HTTP 상태 매핑을 공식 문서로 확정했고, await 재개 주장은 Godot 에서 직접 재현해 반박됐다
   - 같은 파일의 짧은 발견 두 건은 한 에이전트에 묶어도 된다 (각각 판정을 따로 받는다)
3. 결과 원문은 `_workspace/01_audit_findings.json` 에 `confirmed` / `uncertain` / `refuted` 로 나눠 남긴다.

결과 처리:
1. `confirmed` 를 심각도 순으로 사용자에게 보고하고, `uncertain` 은 따로 묶는다.
2. 사용자가 고치라고 하면 건마다 **흐름 1** 로 처리한다 (재현 테스트 → 수정 → 판정). 여러 건을 사람 없이 처리하려면 **흐름 5** 로 넘긴다.
3. 결과 원문은 `_workspace/01_audit_findings.json` 에 남긴다.

## 흐름 3 — 기기 확인만

`game-device-qa` 하나. 무엇을 바꿨는지(또는 무엇을 보고 싶은지)를 프롬프트에 넣는다.

## 흐름 4 — 출시 준비

`game-release` 하나. 결과의 "사람 작업"은 사용자에게 그대로 전달하고, "자동화 가능" 중 사용자가 고른 것만 흐름 1로 처리한다.

## 흐름 5 — 반복 수정 루프

**실행 모드:** ralph-loop (같은 프롬프트 반복 + 파일 기억 + 객관적 완료 게이트)

`game-loop` 스킬을 따른다. 요약:
1. 작업 목록 원천: 보통 흐름 2 의 `confirmed`. **사용자가 고른 항목만** 넣는다. 기기·아트·계정·설계 판단이 필요한 일은 넣지 않는다.
2. `.claude/skills/game-loop/scripts/loop_init.sh <최대반복>` → `_workspace/loop/TASKS.md` 채우기 → 출력된 `/ralph-loop:ralph-loop ...` 명령을 **사용자가 입력**.
3. 반복 하나 = 작업 하나 = 흐름 1 + 커밋. 두 번 FAIL 이면 `[BLOCKED]`.
4. 완료는 `loop_gate.sh` 가 `OPEN` 일 때만 (`<promise>LOOP_DONE</promise>`).
5. 끝나면 결과 보고 → 필요하면 `game-device-qa` → 막힘 패턴이 보이면 `harness:evolve`.

## 데이터 전달

| 단계 | 방법 |
|---|---|
| 서브에이전트 결과 | 반환 메시지 (짧은 판정·목록) |
| 워크플로 결과 | 구조화된 반환값 → `_workspace/01_audit_findings.json` |
| 스크린샷·미리보기 | 스크래치패드 경로로 전달 |
| 루프 상태 | `_workspace/loop/TASKS.md`·`PROGRESS.md` (반복 사이의 유일한 기억) |

## 오류 처리

- 판정(FAIL)·기기 확인 실패는 한 번 고쳐 다시 돈다. 두 번째도 실패하면 출력 원문과 함께 사용자에게 넘긴다.
- 사용량 한도·권한 거부·기기 미연결처럼 다시 해도 같은 실패는 재시도하지 않고, 어디까지 됐는지 확인해 보고한다.
- 워크플로에서 빠진 영역(`null`)은 `log` 로 몇 개가 빠졌는지 알리고 보고서에도 적는다. 빠진 영역을 추측으로 채우지 않는다.
- 에이전트가 확인하지 못한 항목은 "미검증" 으로 남긴다. 확인한 것처럼 바꿔 쓰지 않는다.

## 테스트 시나리오

**정상 흐름:** "게임 오버 화면에서 점수 표시가 틀린 것 같아 고쳐줘" → 흐름 1. 재현 테스트 작성(실패 확인) → 수정 → `game-verifier` PASS → UI 만 바뀌었으므로 기기 확인은 레이아웃 항목만 → 커밋.

**오류 흐름:** "전체 점검해줘" → 흐름 2 워크플로에서 한 영역 에이전트가 실패해 `null` → 나머지 결과만 검증해 보고하고 "services-platform 영역 점검 누락" 을 명시. 사용자가 "그 영역만 다시" 하면 `resumeFromRunId` 로 재개 — 완료된 영역은 캐시를 쓴다.

**오류 흐름 2:** 흐름 1 에서 `game-verifier` 가 누수 기준선 초과로 FAIL → `--verbose` 결과가 전부 오디오이고 새 효과음을 재생하는 테스트를 추가한 경우라면 기준선을 올린다(스크립트와 CLAUDE.md 동시). `Node` 가 보이면 진짜 누수로 보고 고친다.
