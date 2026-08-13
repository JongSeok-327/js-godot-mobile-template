# Godot 모바일 게임 재사용 템플릿 구축 플랜

## ⚠️ 핸드오프: 이 문서로 새 컴퓨터에서 이어서 작업하기

이 플랜은 다른 맥에서 작성·승인된 후 폴더째 옮겨진 것이다. **이어가는 방법**:

1. 이 `JS-GAME/` 폴더에서 `claude` 실행
2. 프롬프트 입력: *"`docs/PLAN.md`를 읽고 Phase 0부터 플랜대로 구현해줘. 커밋 단위는 플랜의 구현 순서 표를 따라줘."*
3. Phase 0 툴링(GodotPrompter 플러그인, Godot 4.7.1, export templates)은 컴퓨터별 설치라 이 머신에서 실행해야 함 — 아래에 단계로 포함

**주의**: 아래 "환경 확인 완료" 내용(Android SDK 경로, OpenJDK 21 경로, debug keystore, AVD 목록)은 **플랜을 작성한 맥 기준 조사 결과**다. 이 컴퓨터에서는 Phase 0 시작 시 동일 항목(Android SDK 위치, JDK 17–21 존재, `~/.android/debug.keystore` 유무)을 재확인하고, 경로가 다르면 이 머신 기준으로 대체할 것.

---

## Context

`JS-GAME/`(빈 디렉토리에서 시작)에 **재사용 가능한 Godot 모바일 게임 틀**을 만든다. 실제 게임은 나중에 이 틀 위에 얹는 방식 — 씬 전환, 저장, 오디오, 설정, UI 흐름 같은 "모든 모바일 게임에 필요한 공통 기반"을 먼저 완성한다.

**확정된 결정사항** (사용자 확인 완료):
- Godot **4.7.1** (최신 안정판, brew cask 버전 확인됨) + **GDScript**
- **2D 세로(portrait)** 모바일 기준, **Android 우선** — iOS는 나중에 확장 가능하도록 플랫폼 의존 코드는 추상화 뒤에 숨기되, 지금은 설정하지 않음
- 코어 모듈 + 다국어(ko/en/ja) 뼈대 + 광고·IAP 스텁 + 오브젝트 풀링·유틸 + 디버그 패널 전부 포함
- 에셋: Kenney(CC0, 상업 사용 가능) 무료 팩을 플레이스홀더로 사용, 나중에 교체 전제
- **GodotPrompter** Claude Code 플러그인을 먼저 설치해 55개 Godot 스킬의 가이드를 받으며 구현 (mattpocock/skills는 게임 개발 스킬이 없어 선택 사항 — 기본 미설치)

**환경 확인 완료 (플랜 작성 머신 기준 — 새 머신에서 재확인 필요)**: Android SDK(`~/Library/Android/sdk`, build-tools ~36.1, emulator AVD 5개), OpenJDK 21(`/opt/homebrew/opt/openjdk@21/...`), 디버그 keystore(`~/.android/debug.keystore`) 모두 존재. Godot만 설치하면 됨.

---

## Phase 0 — 툴링 부트스트랩 (repo 밖 작업, 커밋 없음)

1. GodotPrompter 설치: `claude plugin marketplace add jame581/skillsmith` → 플러그인 설치 (정확한 플러그인명은 marketplace list로 확인) → 세션 재시작으로 스킬 로드
2. Godot 설치: `brew install --cask godot` → `/Applications/Godot.app/Contents/MacOS/Godot --version`으로 `4.7.1.stable` 확인
3. Android export templates: GitHub releases에서 `Godot_v4.7.1-stable_export_templates.tpz` 다운로드 → `~/Library/Application Support/Godot/export_templates/4.7.1.stable/`에 설치 (버전 문자열 정확히 일치 필수)
4. 에디터 설정 (Phase 1 후 `--headless --editor --quit` 1회 실행으로 생성):
   - `export/android/android_sdk_path` = `~/Library/Android/sdk`
   - `export/android/java_sdk_path` = `/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home` (keg-only라 Godot이 자동 인식 못 함 — 명시 필수. 실패 시 Zulu 17 폴백)
   - `export/android/debug_keystore` = `~/.android/debug.keystore` (user `androiddebugkey` / pass `android`)

## 디렉토리 구조

```
JS-GAME/
├── project.godot / export_presets.cfg / CLAUDE.md / README.md / .gitignore / .gitattributes
├── autoload/          # EventBus, SaveManager, Settings, AudioManager,
│                      # SceneManager(.tscn+.gd), Services, DebugTools
├── scenes/            # boot/, main_menu/, game/, overlays/(pause_menu, settings_menu, game_over)
├── ui/                # theme/default_theme.tres, components/
├── scripts/           # services/(ad_service, iap_service + null 구현), input/touch_controller.gd,
│                      # utils/(object_pool.gd, node_utils.gd)
├── debug/             # debug_panel.tscn+.gd (릴리스 빌드 제외)
├── locale/            # translations.csv (key,en,ko,ja)
├── assets/            # audio/(bus_layout, music, sfx), fonts/, sprites/, ui/kenney_ui/
├── tests/             # run_all.sh + test_*.gd (SceneTree 기반 headless 테스트)
└── build/             # export 산출물 (gitignore)
```

## Autoload 설계 (등록 순서 = 초기화 순서)

1. **EventBus** — 전역 signal 허브만 (로직 없음): `scene_change_started/finished`, `game_paused`, `game_over`, `language_changed`, `save_completed`
2. **SaveManager** — `user://save.json`, `{"version": N, "data": {...}}` 구조. `get_value/set_value/save/load/has_save/wipe` + `_migrate(from_version, raw)` 버전 마이그레이션 체인
3. **Settings** — `user://settings.cfg` (ConfigFile, 저장 데이터와 분리 — 세이브 초기화해도 설정 유지). 볼륨(master/music/sfx, AudioServer 즉시 반영) + locale(TranslationServer 반영)
4. **AudioManager** — `PROCESS_MODE_ALWAYS`(일시정지 중에도 음악 유지). 음악 플레이어 2개 크로스페이드 + SFX 풀 8개. 버스: `Master ← Music, SFX`
5. **SceneManager** — 씬 autoload(.tscn): CanvasLayer(100) + ColorRect + AnimationPlayer로 페이드 전환. `SCENES` 딕셔너리 레지스트리(문자열 ID → 경로, 게임 코드에 경로 하드코딩 방지). `change_scene(id)` / `reload_current()`. **씬 전환 시 `paused = false` 강제 리셋** (고전적 stuck-pause 버그 방어)
6. **Services** — 서비스 로케이터. `Services.ads` / `Services.iap`에 Null 구현 기본 할당. `AdService`/`IAPService`는 `class_name` 인터페이스(initialize/show_rewarded/purchase 등 + signal), Null 구현은 로그 후 즉시 성공 signal emit → SDK 없이도 게임 흐름 테스트 가능. 나중에 AdMob 등을 붙여도 게임 코드는 무변경
7. **DebugTools** — `OS.is_debug_build()`일 때만 `load()`(preload 금지 — 릴리스 preset에서 `debug/*` 제외 가능하게)로 디버그 패널 생성. FPS/메모리, 씬 점프, locale 순환, 세이브 초기화, 치트 훅

**Autoload 아님**: `ObjectPool`(인스턴스 생성해 쓰는 클래스, `acquire/release` + `_pool_reset()` 규약), `TouchController`(게임 씬에 넣는 컴포넌트 노드 — tap/long_press/drag/swipe signal)

## 씬 흐름

`boot(main_scene, 로고+autoload 초기화 은폐)` → `main_menu` → `game(셸: HUD+일시정지 버튼+게임플레이 자리)` + 오버레이(`pause_menu`=CanvasLayer ALWAYS, `settings_menu`=메뉴/일시정지 양쪽에서 재사용, `game_over`)

- Android 뒤로가기: `quit_on_go_back=false` + `NOTIFICATION_WM_GO_BACK_REQUEST` 처리 (게임=일시정지 토글, 메뉴=종료)
- 백그라운드 전환: `NOTIFICATION_APPLICATION_PAUSED` → 자동 일시정지 + 저장 (Android는 백그라운드 후 언제든 프로세스 킬 가능)

## project.godot 핵심 설정

- 창: 720×1280, stretch `canvas_items` + `expand`(레터박스 없이 긴 화면 대응 — 모든 UI는 앵커 기반, HUD는 safe area 존중), orientation portrait, `keep_screen_on=true`
- 렌더러: **`gl_compatibility`** (2D 모바일 최적 + Android 에뮬레이터에서 Vulkan 기반 Mobile 렌더러의 블랙스크린 이슈 회피)
- `emulate_touch_from_mouse=true` (에디터에서 마우스로 터치 테스트)
- `import_etc2_astc=true` **에셋 추가 전에 설정** (첫 Android export 시 대량 리임포트 방지)
- locale: translations.csv → en/ko/ja, fallback en

## Android export

- `export_presets.cfg` 커밋 (2개 preset): **Android Debug** + **Android Release**(debug 패널 `debug/*` 리소스 제외 필터)
- `gradle_build=false` — 순수 템플릿은 gradle 불필요 (실제 Android 플러그인 추가 시점에 전환, CLAUDE.md에 문서화)
- `arm64-v8a`만 (APK 절반 크기, 에뮬레이터/실기기 커버), package `com.jsgame.template`(추후 변경), min/target SDK는 Godot 기본값(빈 값 유지)
- 릴리스 keystore는 미설정 — 출시 시점 keytool 명령을 CLAUDE.md에 문서화만

## 구현 순서 (1 논리 변경 = 1 커밋)

| Phase | 커밋 단위 | 검증 |
|---|---|---|
| 1. 뼈대 | ① git init + .gitignore(.godot/, build/, *.apk) ② project.godot + boot.tscn ③ CLAUDE.md/README 초안 | `--headless --path . --quit` exit 0 |
| 2. 코어 autoload | ④ EventBus ⑤ SaveManager+테스트 ⑥ Settings+테스트 ⑦ 버스 레이아웃+AudioManager ⑧ SceneManager+페이드 | 모듈별 headless 테스트 |
| 3. UI 흐름 | ⑨ 테마+폰트 ⑩ boot→menu ⑪ game 셸+pause(+뒤로가기/lifecycle) ⑫ settings 오버레이 ⑬ game_over | 에디터 실행, 전체 루프 클릭 |
| 4. 입력·i18n·유틸 | ⑭ TouchController ⑮ translations.csv+런타임 언어 전환 ⑯ ObjectPool+테스트+NodeUtils | headless 테스트 + 에디터 |
| 5. 서비스·디버그 | ⑰ Ad/IAP 인터페이스+Null+Services ⑱ 디버그 패널 | 에디터에서 리워드 광고 mock 흐름 |
| 6. 에셋 | ⑲ Kenney UI Pack + Interface Sounds(CC0) + Noto Sans KR/JP(OFL) 적용 | ko/ja 글자 렌더 확인 |
| 7. Android | ⑳ export_presets.cfg ㉑ APK export→에뮬레이터 검증 | 아래 E2E |
| 8. 마무리 | CLAUDE.md 최종화(검증된 명령 반영), tag v0.1.0 | — |

## 검증

- **매 커밋 스모크**: `Godot --headless --path . --quit` (파스 에러·깨진 autoload·누락 리소스 검출)
- **단위 테스트**: GUT 프레임워크는 템플릿에 과함 — `extends SceneTree` 스크립트를 `-s res://tests/test_*.gd`로 headless 실행 (SaveManager 마이그레이션, Settings, ObjectPool). `tests/run_all.sh`로 일괄 실행
- **E2E**: ① headless로 `--export-debug "Android Debug" build/jsgame-debug.apk` ② `emulator -avd Pixel_6` 부팅 ③ `adb install` + `am start` ④ `adb logcat -s godot`으로 스크립트 에러 없음 + boot→menu→game 육안 확인 ⑤ 릴리스 preset export 1회로 디버그 패널 제외 확인

## 주의사항 (구현 중 반영)

- **CJK 폰트**: Godot 기본 폰트에 한글/일본어 글리프 없음 → Noto Sans KR/JP를 테마 폰트 폴백으로 반드시 설정 (이번 요구사항에서 가장 놓치기 쉬운 지점)
- **대소문자**: macOS는 대소문자 무시, Android는 구분 → `res://` 경로 전부 lowercase snake_case 강제 (CLAUDE.md 규약)
- export template 버전은 에디터와 정확히 일치해야 함 — brew 업그레이드 시 재설치 필요 (`brew pin godot` 또는 문서화)
- 첫 headless export 전에 `--headless --editor --quit` 1회로 에디터 설정 파일 생성 필요
