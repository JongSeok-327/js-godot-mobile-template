# MobileGame Template

Godot 4.7.1 기반 **2D 세로(portrait) 모바일 게임 템플릿**.
모든 모바일 게임에 공통으로 필요한 기반(씬 전환, 저장, 오디오, 설정, UI 흐름,
입력, 다국어, 서비스 추상화)을 먼저 갖춰두고 그 위에 게임을 얹는 구조다.

## 포함되는 것

- **EventBus** — 전역 signal 허브
- **SaveManager** — `user://save.json` + 버전 마이그레이션
- **Settings** — `user://settings.cfg` (볼륨/언어, 세이브와 분리)
- **AudioManager** — 음악 크로스페이드 + SFX 풀, 일시정지 중에도 동작
- **SceneManager** — 페이드 전환 + 씬 ID 레지스트리
- **Services** — 광고/IAP 인터페이스 + Null 구현 (SDK 없이 흐름 테스트 가능)
- **DebugTools** — 디버그 빌드 전용 패널 (FPS, 씬 점프, 언어 순환, 세이브 초기화)
- ObjectPool, TouchController(tap/long press/drag/swipe), ko/en/ja 다국어

## 실행

```bash
GODOT=/Applications/Godot_4.7.1.app/Contents/MacOS/Godot

"$GODOT" --path . --editor   # 에디터
"$GODOT" --headless --path . --quit   # 스모크 테스트
```

## 상태

구현 진행 상황과 남은 작업은 `docs/PLAN.md`를 참고. Android export(Phase 7)는
툴체인 미설치로 보류 중이다.
