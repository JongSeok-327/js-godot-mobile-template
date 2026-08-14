# MobileGame Template

Godot 4.7.1 기반 **2D 세로(portrait) 모바일 게임 템플릿**.
모든 모바일 게임에 공통으로 필요한 기반(씬 전환, 저장, 오디오, 설정, UI 흐름,
입력, 다국어, 서비스 추상화)을 먼저 갖춰두고 그 위에 게임을 얹는 구조다.

Android 실기기(에뮬레이터)까지 검증된 상태다. 게임플레이는 비어 있다 —
`scenes/game/game.tscn`의 `Gameplay` 노드가 그 자리다.

## 포함되는 것

- **EventBus** — 전역 signal 허브
- **SaveManager** — `user://save.json` + 버전 마이그레이션
- **Settings** — `user://settings.cfg` (볼륨/언어, 세이브와 분리)
- **AudioManager** — 음악 크로스페이드 + SFX 풀, 일시정지 중에도 동작
- **SceneManager** — 페이드 전환 + 씬 ID 레지스트리
- **Services** — 광고/IAP 인터페이스 + Null 구현 (SDK 없이 흐름 테스트 가능)
- **DebugTools** — 디버그 빌드 전용 패널 (FPS, 씬 점프, 언어 순환, 세이브 초기화)
- ObjectPool, TouchController(tap/long press/drag/swipe), ko/en/ja 다국어
- 안드로이드 뒤로가기·백그라운드 전환 처리, safe area 대응 HUD

## 시작하기

```bash
GODOT=/Applications/Godot_4.7.1.app/Contents/MacOS/Godot

"$GODOT" --headless --path . --import   # 최초 클론 후 1회 (필수)
"$GODOT" --path .                       # 게임 실행
"$GODOT" --path . --editor              # 에디터
./tests/run_all.sh                      # 테스트
```

`--import`를 건너뛰면 번역이 로드되지 않는다 — `.godot/`과
`locale/*.translation`은 임포트로 생성되는 산출물이라 저장소에 없다.

## 게임을 얹을 때

1. `scenes/game/game.tscn`의 `Gameplay` 노드 아래에 게임플레이를 만든다.
2. 새 씬은 `SceneManager.SCENES`에 ID로 등록한다 (경로 하드코딩 금지).
3. UI 문자열은 `locale/translations.csv`에 키로 추가한다.
4. 리스타일은 `ui/theme/default_theme.tres`의 색·모서리만 바꾸면 된다.
5. 패키지명(`com.jsgame.template`)과 `icon.svg`를 교체한다.

## 문서

- `CLAUDE.md` — 환경, 명령어, 코드 규약, 테스트 인프라, Android 빌드
- `docs/PLAN.md` — 이 템플릿을 만든 구현 플랜 (Phase 0~8)
