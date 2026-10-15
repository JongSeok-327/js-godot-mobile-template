# CLAUDE.md — MobileGame Template

Godot 4.7.1 / GDScript로 만드는 **재사용 가능한 2D 세로 모바일 게임 틀**.
실제 게임 로직은 이 틀 위에 얹는다. 구현 플랜은 `docs/PLAN.md` 참고.

> 이 틀 위에 처음 얹은 게임은 kongkong(원버튼 러너, iOS 출시)이다. 아래 내용 중
> "kongkong 에서 밟았다" 로 적힌 것은 거기서 실제로 겪고 템플릿으로 되돌린 것이다.

## 하네스: 개발·검증·기기 확인·출시

**목표:** 변경마다 같은 순서(구현 → 판정 → 기기 확인)를 지키고, 전체 점검은 발견마다 반박 검증해 오탐을 거른다.

**호출 조건:** 기능 추가·버그 수정·전체 점검·기기 확인·출시 준비·반복 수정 루프 요청은
`game-orchestrator` 스킬을 사용한다. 단순 질문에는 직접 답한다.

| 스킬 / 에이전트 | 역할 |
|---|---|
| `game-orchestrator` | 요청을 흐름(수정·점검·기기·출시·루프)으로 나눠 아래를 부른다 |
| `game-verify` / `game-verifier` | `tools/verify.sh` 로 PASS/FAIL 판정. 고치지 않는다 |
| `game-device-qa` | `tools/device.sh` 로 Android·iPhone 설치·캡처·로그 |
| `game-release` | 출시 막힘을 사람 작업/자동화 가능으로 나눈다 |
| `game-loop` | ralph-loop 위에서 작업 목록을 하나씩 처리, `loop_gate.sh` 가 완료 판정 |

게임을 얹으면 점검 영역(`game-orchestrator` 흐름 2)과 기기 확인 목록에 게임 고유 항목을 더한다.

`.claude/settings.json` 은 `rm -rf`·`git push --force`·`git reset --hard`·`git clean -f` 를 막는다 —
`game-loop` 가 사람 없이 도는 동안의 안전장치다. 루프에 필요한 허용은 각자 `settings.local.json` 에 둔다.

일부 도구는 [Claude-Code-Game-Studios](https://github.com/Donchitos/Claude-Code-Game-Studios) 에서
가져와 다듬었다 (`tools/parse_check.gd`, 번역 검사, 출시 체크리스트의 모바일 항목, deny 목록).

## 환경

| 항목 | 값 |
|---|---|
| Godot 실행 파일 | `/Applications/Godot_4.7.1.app/Contents/MacOS/Godot` |
| Godot 버전 | `4.7.1.stable` |
| export templates | `~/Library/Application Support/Godot/export_templates/4.7.1.stable/` |
| JDK | `~/Library/Java/jdk-21.0.12+8/Contents/Home` (Temurin 21) |
| Android SDK | `~/Library/Android/sdk` (build-tools 35.0.0, platform 35, platform-tools, emulator) |
| debug keystore | `~/.android/debug.keystore` (alias `androiddebugkey` / pass `android`) |
| 에뮬레이터 AVD | `Pixel_6_API35` (Android 15, arm64-v8a) |

Homebrew 없이 사용자 디렉토리에만 설치했다 — sudo도, 대화형 프롬프트도 필요 없다.
Godot 에디터 설정(`editor_settings-4.7.tres`)에 위 SDK/JDK/keystore 경로가 등록되어 있다.

> export template 버전 문자열은 에디터 버전과 **정확히** 일치해야 한다.
> Godot을 업그레이드하면 템플릿도 같은 버전으로 재설치할 것.

## 명령어

```bash
GODOT=/Applications/Godot_4.7.1.app/Contents/MacOS/Godot

# 최초 클론 후 1회 — 임포트 산출물 생성 (필수)
"$GODOT" --headless --path . --import

# 스모크 테스트 — 매 커밋 전 필수 (파스 에러/깨진 autoload/누락 리소스 검출)
"$GODOT" --headless --path . --quit

# 에디터에서 실행
"$GODOT" --path . --editor

# 단위 테스트
./tests/run_all.sh

# 커밋 전 판정 한 번에 — 스모크 + 전체 스크립트 파스 + 씬별 스모크(SceneManager.SCENES 전부) + 테스트 + 누수 기준선
tools/verify.sh            # 마지막 줄 VERDICT: PASS|FAIL
tools/verify.sh --import   # 새 클론·새 에셋·새 번역·새 스크립트

# 최초 클론 후 1회 — 커밋 검사 훅 켜기 (Team ID 채운 preset·config/*.cfg·서명 키 커밋 차단)
git config core.hooksPath .githooks

# 화면비별 촬영 (iPhone 7종 + Android 2종 × 등록된 씬, 데스크톱 실행 — 시뮬레이터 대용)
"$GODOT" --path . res://debug/layout_shots.tscn -- --out=/절대/경로
```

> **커밋 전에는 `verify.sh` 의 마지막 줄을 문자열로 비교한다** — `r=$(tools/verify.sh | tail -1); [ "$r" = "VERDICT: PASS" ] && git commit ...`.
> `set -e` 나 `&&` 로 이어 두면 파이프 끝(`tail`)의 종료 코드만 보여서 FAIL 인데 커밋된 적이 있다(kongslash).

> **스모크는 종료 코드만 보면 안 된다** — GDScript 에러는 exit 0 으로 나온다.
> 출력에서 `SCRIPT ERROR|Parse Error|Failed to load` 를 봐야 한다. `verify.sh` 가 그걸 한다.
> 또 스모크는 autoload·씬이 **참조하는** 스크립트만 컴파일한다. 아직 안 붙인 스크립트나
> `load()` 로만 가져오는 스크립트의 파스 에러는 `tools/parse_check.gd` 가 전부 로드해 잡는다
> (`_initialize()` 에서 로드하므로 autoload 이름을 쓰는 코드도 정상 컴파일된다).

> `.godot/`과 `locale/*.translation`은 저장소에 없다 — 둘 다 임포트로 생성되는
> 산출물이다. 반대로 스크립트의 `.uid` 파일은 커밋한다 (머신마다 새로 생성되면
> `uid://` 참조가 깨진다).
>
> **임포트를 건너뛰면 스모크 테스트로는 안 잡힌다** — 번역과 폰트가 없어도
> `--quit`은 exit 0을 낸다. 대신 테스트 러너가 끝나지 않고 매달리므로
> `run_all.sh`가 타임아웃(기본 120초, `TEST_TIMEOUT`으로 조정)으로 끊고
> 임포트하라고 알려준다.

## 코드 규약

- **`res://` 경로는 전부 lowercase snake_case.** macOS는 대소문자를 무시하지만
  Android는 구분한다 — 맥에서 돌던 게 기기에서 리소스 누락으로 깨지는 대표 원인.
- 씬 경로를 게임 코드에 하드코딩하지 않는다. `SceneManager.SCENES` 레지스트리의
  문자열 ID를 쓴다.
- 플랫폼 의존 코드(광고/IAP 등)는 `scripts/services/`의 인터페이스 뒤에 숨긴다.
  게임 코드는 `Services.ads` / `Services.iap`만 본다.
- 디버그 전용 리소스는 `debug/`에 두고 `preload`가 아닌 `load`로 가져온다
  (릴리스 preset에서 `debug/*`를 제외할 수 있어야 하므로).
- **UI 테마는 의도적으로 코드 정의다** (`ui/theme/default_theme.tres`의 StyleBoxFlat).
  게임을 얹을 때 여기서 색·모서리만 바꾸면 리스타일된다 — 스프라이트로 갈아끼우면
  그때마다 아트를 새로 그려야 한다. Kenney 에셋은 슬라이더 그래버와 클릭음에만 썼다
  (엔진 기본 아이콘/무음을 없애려는 목적). CJK 폰트는 번들이 필수다 — 시스템 폰트에
  맡기면 기기마다 자형이 달라진다.
- **화면별 스타일은 `theme_type_variation` 이름으로 고른다.** 이름이 틀리거나 테마에 없으면
  에러 없이 기본 모양으로 그려진다 — `test_theme.gd` 가 씬에서 쓰는 이름이 전부 테마에 있는지 검사한다.
- **화면을 덮는 Control 은 `mouse_filter = IGNORE`.** 하나라도 STOP 이면 GUI 가 터치를
  소비해 `_unhandled_input` 까지 오지 않는다 — 반응이 없는데 에러도 로그도 없다 (kongkong 에서 밟았다).
- **스크롤 목록의 항목은 버튼 말고는 `mouse_filter = PASS`.** `PanelContainer` 기본값 STOP 이면
  카드 위를 끌어도 스크롤이 안 된다(에러 없음). `test_scroll_touch.gd` 가 씬 안의 스크롤을 훑고,
  런타임에 붙이는 항목 씬은 그 파일의 `ITEMS` 에 등록한다.
- **코드가 `tr()` 결과를 넣은 글자는 언어가 바뀌어도 그대로다** (번역 키만 Godot 이 다시 번역한다).
  그런 글자는 `NOTIFICATION_TRANSLATION_CHANGED` 에서 다시 쓴다 — 설정의 진동 켜짐/꺼짐이 그렇다.
  `test_locale_refresh.gd`.
- **번역 CSV 는 `test_translations.gd` 가 검사한다** — 빈 칸, 언어마다 다른 플레이스홀더(`%d`·`{name}`),
  씬의 `text = "KEY"`·코드의 `tr("KEY")` 가 CSV 에 없는 경우. 셋 다 Godot 은 에러 없이 키 글자를 그린다.
- **세이브의 정수는 `SaveManager.get_int()` 로 읽는다.** JSON 은 int 를 float 로 되돌린다 —
  `==` 는 통과해서 못 보고 `typeof`·`%d`·Dictionary 키·정수 나눗셈에서 조용히 어긋난다.
- **세이브는 원자적으로 쓴다** (`.tmp` 에 쓰고 rename, 직전본은 `.bak`). 본 파일이 깨지면 `.bak` 으로
  살아나고, 더 최신 버전 앱의 세이브는 읽지도 덮어쓰지도 않는다. `save_game()` 을 우회해 직접 쓰지 않는다.
- **물리 콜백(`area_entered` 등) 안에서 트리 조작·`monitoring` 변경·free 금지** →
  `call_deferred` / `set_deferred`. 풀에 반납할 때는 `set_deferred("monitorable", false)`.
- 진동은 `Settings.vibrate()` 로만 낸다 — 설정 검사가 한 곳에 있다. 데스크톱에서는 아무 일도 안 한다.
- **첫 판의 첫 타격이 끊긴다** (kongslash iPhone 실측 85ms) — 그 순간 처음 쓰는 것(효과음 디코더·햅틱 엔진·새 글자 크기의
  글리프·이펙트 셰이더)이 한꺼번에 준비된다. 판 시작 때 무음 재생·1ms 진동·투명 그리기로 한 번씩 **예열**한다.
  데스크톱에선 안 보인다 — 기기에서 `debug/perf_probe.gd`(40ms 넘는 프레임 + 직전 `mark()`)를 붙여 `ios-pull` 로 가져와 잰다.

## 서비스 교체 지점

게임 코드는 `Services.<slot>` 만 본다. 구현 교체는 `autoload/services.gd` 한 곳에서 일어난다.

- **광고 구현의 계약** (`scripts/services/ad_service.gd`):
  - `show_rewarded()` / `show_interstitial()` 은 못 띄워도 **반드시** 결과 signal 을 돌려준다 —
    부르는 화면은 그걸 기다리며 버튼을 잠가 둔다. 연타로 들어온 두 번째 요청은 무시한다.
  - 보상 지급 신호는 광고가 **닫힌 뒤에** 보낸다 (SDK 의 "보상 받음" 콜백은 닫히기 전에 온다).
  - 준비 상태가 바뀌면 `rewarded_ready_changed` — 실제 SDK 는 부팅 후 몇 초 뒤에 준비된다.
    광고 버튼은 화면을 열 때 한 번이 아니라 이 signal 로 다시 그린다.
  - 띄울 때 `fullscreen_changed(true)`, 닫힐 때(결과 signal 보다 먼저) `false`. `Services` 가 이걸
    `AudioManager.set_music_paused` 에 연결해 둔다 — **iOS 광고는 앱을 일시정지시키지 않아서**
    안 쏘면 광고 뒤로 배경음악이 흐른다 (kongkong iPhone 에서 밟았다).
  - 디버그 빌드는 cfg 와 무관하게 **구글 테스트 광고 단위**를 쓰게 만든다. 개발 중 실제 단위로
    반복 재생하면 무효 트래픽으로 계정이 정지된다.
  - 리워드 광고가 열리면 Android 는 `NOTIFICATION_APPLICATION_PAUSED` 가 **반드시** 온다. 광고 중에는
    이 알림으로 일시정지 메뉴를 띄우거나 저장하지 않게 게임 쪽에서 상태를 보고 거른다.
- **`@abstract` 메서드를 하나라도 빼먹으면 파싱 에러로 부팅이 안 된다.** 새 구현은 인스턴스화를
  테스트에 넣는다.
- **애드온(SDK 플러그인) 클래스를 쓰는 구현은 이름이 아니라 `load()` 로 가져온다.** 이름으로 쓰면
  그 함수를 컴파일할 때 스크립트가 딸려 오고, 애드온의 `static var` 초기화가 **데스크톱에서도**
  가짜 플러그인 노드를 만든다. 분기를 안 타도 그렇다 — kongkong 에서 누수가 ObjectDB 8 → 80 으로 뛰었다.
  같은 이유로 테스트에서 애드온 클래스를 건드리지 않는다.
- **`HTTPRequest` 는 Node 다.** RefCounted 서비스는 소유할 수 없으니 `Services` 아래에 호스트 노드를
  두고 넘긴다. 요청마다 새로 만들고 완료 시 `queue_free`.
- **서버 응답에 `JSON.parse_string()` 을 쓰지 않는다** — 깨진 입력마다 ERROR 를 찍는다. 프록시의 HTML
  오류 페이지·204 빈 바디가 실제로 들어온다. `JSON.new().parse()` 로 조용히 파싱한다.
- **실제 키·광고 단위는 `config/*.cfg`** (gitignore, `.example` 만 커밋). cfg 는 리소스가 아니라서
  export 에 자동으로 안 들어간다 — preset `include_filter` 에 `config/*.cfg` 를 넣는다. 빼면 에디터에서는
  되는데 **기기에서만 조용히 폴백한다.** 파일이 없으면 실패시키지 말고 Null 구현으로 떨어뜨린다.
- **테스트는 실서버에 쓰지 않는다.** 네트워크 서비스를 붙이면 `test_runner.gd` 가 도는 동안 그 슬롯을
  Null 구현으로 못 박는다.

## 디렉토리

```
autoload/   EventBus, SaveManager, Settings, AudioManager, SceneManager, Services, DebugTools
scenes/     boot/, main_menu/, game/, overlays/
ui/         theme/, components/
scripts/    services/, input/, utils/
debug/      디버그 패널, 화면비 촬영 도구, 프레임 끊김 기록(perf_probe) (릴리스 빌드 제외)
docs/store/ 스토어 등록 문구·개인정보·연령 등급 응답표 골격 (게임을 얹으면 채운다)
locale/     translations.csv (key,en,ko,ja)
assets/     audio/(bus layout, sfx), fonts/(Noto KR·JP), ui/(슬라이더 그래버), icon/(빈 스플래시)
tests/      run_all.sh + test_runner.tscn + test_*.gd
tools/      verify.sh(판정), parse_check.gd(전체 스크립트 파스), device.sh(기기 설치·캡처)
.githooks/  pre-commit (비밀·로컬 값 커밋 차단)
.claude/    하네스 스킬·에이전트 (game-*)
build/      export 산출물 (gitignore, .gdignore 필수)
```

## 테스트

`./tests/run_all.sh` 하나로 전부 돈다. 프레임워크는 쓰지 않는다.

새 테스트를 추가하려면: `tests/test_*.gd`를 `extends RefCounted`로 만들고
`func run(t: Node) -> void` 하나만 두고, `tests/test_runner.gd`의 `TESTS` 배열에
preload로 등록한다. 단언은 `t.check(조건, 라벨)` / `t.eq(실제, 기대, 라벨)`.

함정 — 전부 실제로 밟은 것이다:

- **`-s res://tests/x.gd` 스크립트 모드를 쓰지 마라.** 그 모드에서는 autoload가
  인스턴스화되지 않아 `EventBus` 같은 전역 식별자가 **컴파일조차 되지 않는다**.
  그래서 러너를 씬(`test_runner.tscn`)으로 띄운다.
- **GDScript 컴파일 에러는 종료 코드 0으로 나온다.** `run_all.sh`가 출력에서
  `SCRIPT ERROR|Failed to load script|Parse Error`를 함께 검사하는 이유다.
  Godot을 직접 호출하지 말고 항상 `run_all.sh`로 돌려라.
- **테스트에서 `Node`를 `.new()`로 만들면 `free()` 해야 한다.** RefCounted가
  아니라서 안 하면 종료 시 ObjectDB 누수로 잡힌다.
- **`run_all.sh` 출력을 grep 할 때는 마지막 줄까지 본다.** 스크립트 에러는 "통과 N / 실패 0"
  **뒤에** 따로 찍혀서, `grep "통과"` 만 하면 실패를 통과로 읽는다.

**누수 기준선은 ObjectDB 4 / resource 2 이하**다 (`tools/verify.sh` 의 `LEAK_*_MAX`). 지금 템플릿은
0 이 나오지만 4 / 2 가 한 번 나온 적이 있어 그만큼 여유를 뒀다. kongkong 에서는 효과음 `preload`
상수가 붙든 오디오 스트림이 누수 보고보다 늦게 해제돼 무해한 누수가 생겼다 (효과음 하나당 4 / 2).
넘으면 타입을 `"$GODOT" --headless --verbose --path . res://tests/test_runner.tscn` 로 본다 —
전부 오디오면 기준선을 올리되 `verify.sh` 와 이 문단을 같이 고치고, `Node` 가 보이면 진짜 누수다.

러너는 한 프레임 넘긴 뒤 시작한다 — `root`가 자식을 세팅하는 동안에는
`add_child()`가 거부되기 때문이다.

## iOS

```bash
# 실기기 확인 (Team ID 를 로컬 preset 에만 넣은 상태 — 커밋 금지)
tools/device.sh ios            # "iOS Debug" export → xcodebuild → 설치 → 실행
tools/device.sh ios-release    # 출시 preset 으로 Release 빌드 → 설치 (디버그 패널 없음 확인)
tools/device.sh ios-shot x.png
tools/device.sh ios-pull Documents/save.json x.json   # user:// = Documents/
tools/device.sh ios-archive    # App Store 제출용 archive → Organizer 를 연다 (Distribute App → App Store Connect)
```

- **preset 이 둘이다: `iOS`(릴리스, `debug/*` 제외)와 `iOS Debug`(디버그 패널 포함).** 하나로
  디버그 export 를 하면 제외 필터가 그대로 적용돼 디버그 패널이 사라진다 (kongkong 에서 밟았다).
  `export_project_only=true` 라 Xcode 프로젝트까지만 만들고, 빌드·서명·업로드는 Xcode 에서 한다.
- **`app_store_team_id` 가 비어 있으면 export 가 거부된다.** 커밋은 빈 값으로 한다 — `.githooks/pre-commit`
  이 채워진 Team ID 를 막는다.
- **Xcode 본체가 필요하다** — 명령줄 도구만으로는 `xcodebuild` 가 안 돈다.
- **시뮬레이터로는 못 돌린다 (Apple Silicon 기준).** Godot 4.7.1 공식 템플릿의 시뮬레이터용
  `libgodot.a` 는 x86_64 만 들어 있어 arm64 시뮬레이터 빌드가 링크에서 깨진다. 실기기(무료 Personal
  Team 으로 가능)로 확인하고, 화면비는 `debug/layout_shots.tscn` 으로 데스크톱에서 본다.
- 최소 iOS **15** (Xcode 27 이 15 미만을 거부한다), **iPhone 전용**(`targeted_device_family=0` —
  iPad 를 켜면 iPad 스크린샷까지 심사에 필요하다), 세로 고정.
- **카메라·마이크·사진 사용 설명은 빈 값이면 안 된다.** Godot iOS 템플릿이 세 키를 항상 Info.plist 에
  넣는다. 빈 값이면 Xcode 경고 + 업로드 거절 위험이라 "사용하지 않습니다" 문구를 en/ko/ja 로 넣어 뒀다.
- **iOS 에서는 메인 메뉴의 종료 버튼을 숨긴다.** iOS 에는 앱 종료 개념이 없고, 스스로 꺼지는 앱은
  충돌로 보여 심사 반려 사유다.
- **시작 화면에 Godot 로고를 띄우지 않는다.** `boot_splash/show_image=false` 만으로는 부족하다 —
  iOS 런치 스토리보드가 `boot_splash/image`(기본값 = Godot 로고)를 쓴다. 그래서 투명 이미지
  (`assets/icon/splash_blank.png`)를 지정했고, `boot.tscn` 바탕색을 `boot_splash/bg_color` 와 맞췄다.
  부팅 씬에 고정 대기를 두지 않는다 — 두면 시작이 굼떠 보인다.
- **`build/` 에는 `.gdignore` 가 있어야 한다** — 없으면 Godot 이 iOS 빌드 산출물(.app 안 PNG 등)을
  리소스로 가져와 패키지에 섞는다(kongkong 실측 +1.9MB). `device.sh` 가 매번 만든다. 손으로 export
  할 때도 `touch build/.gdignore` 먼저.
- 출시 preset 은 Apple Distribution 으로 서명된다(App Store 제출용). 무료 팀으로 기기 확인할 때만
  `device.sh ios-release` 가 `Apple Development` 로 덮어쓴다.
- Godot 의 `print` 는 `devicectl --console` 로 안 나온다. 기기에서 값을 보려면 `user://` 에 파일로 쓰고
  `ios-pull` 로 가져온다.
- 맞춤 광고용 추적 허용(ATT) 팝업을 넣으면 `NSUserTrackingUsageDescription` 문구와 요청 코드를 **함께**
  넣는다 (요청만 하고 문구가 없으면 크래시, 문구만 있으면 심사 질문).

### 업로드·심사 제출 (kongkong·kongslash 에서 밟은 것)

- **archive 는 `Apple Development` 로 서명한다** — 자동 서명 + 출시 preset 의 `Apple Distribution` 이 겹치면
  "conflicting provisioning settings" 로 실패한다. 배포 서명은 업로드 단계가 다시 한다. `device.sh ios-archive` 가 그렇게 한다.
- **업로드는 Organizer(Distribute App)로.** Xcode 27 에서 `xcodebuild -exportArchive`(destination upload)가 설정의
  Apple Accounts 에 계정이 있어도 "Failed to Use Accounts / No Accounts" 로 깨졌다(kongslash, kongkong 때는 됐다).
  사람 없이 올리려면 App Store Connect API 키(`.p8`, gitignore 됨)로 `-authenticationKeyPath/-KeyID/-KeyIssuerID` 를 쓴다.
- 업로드 뒤 "Upload Symbols Failed … GoogleMobileAds/UserMessagingPlatform dSYM" 경고는 **무해**하다(SDK 가 dSYM 없이 온다).
- `ITSAppUsesNonExemptEncryption=false` 는 Godot 템플릿 Info.plist 에 이미 있다 — 수출 규정 질문이 안 나온다.
- **App Store Connect 의 버전 문자열 = preset `short_version`** (예: 1.0.0). 새 앱의 기본값 "1.0" 그대로 두면 빌드가 안 붙는다.
- 스크린샷은 6.3인치 칸(1206×2622) 한 벌이면 된다 — 화면 밖 `SubViewport`(size 1206×2622, `size_2d_override` 로 720 폭)에
  장면을 띄워 찍는다(창으로 열면 화면 높이에 잘린다). 언어마다 따로 올린다.
  **올린 뒤 안내 창("앱 미리보기, 스크린샷 및 현지화")을 승인하지 않으면 일부가 구름 아이콘(처리 중)에서 멈추고**,
  "심사에 추가" 가 "1개 이상의 스크린샷 업로드가 완료되어야" 로 막힌다 — 언어별로 눈으로 확인하고, 멈춘 것은 지우고 다시 올린다.
  "헤더 및 검색 결과" 탭(5244×2950)에 떨어뜨리면 크기 오류로 거부된다 — "앱 미리보기 및 스크린샷" 탭을 먼저 연다.
- 게임 하위 카테고리에 "아케이드" 가 없다 (액션·캐주얼 등). 중국 본토는 게임 판호 없이는 못 내니 출시 지역에서 뺀다.
- 연령 등급 설문(7단계): 만화 폭력 "드문" → 9+. 닉네임이 남에게 보이면 "사용자 생성 콘텐츠" 예, 광고 SDK 면 "광고" 예.
  응답표·개인정보 라벨 초안은 `docs/store/` 에 둔다.

## Android

아래 명령은 전부 실제로 실행해 검증한 것이다. 같은 절차를 `tools/device.sh android|logs|shot` 이
패키지명을 preset 에서 읽어 한 번에 한다.

```bash
export JAVA_HOME="$HOME/Library/Java/jdk-21.0.12+8/Contents/Home"
export ANDROID_HOME="$HOME/Library/Android/sdk"
ADB="$ANDROID_HOME/platform-tools/adb"
GODOT=/Applications/Godot_4.7.1.app/Contents/MacOS/Godot

# 디버그 APK export (37MB, debug keystore로 서명됨)
"$GODOT" --headless --path . --export-debug "Android Debug" build/mobilegame-debug.apk

# 에뮬레이터 부팅 → 설치 → 실행
"$ANDROID_HOME/emulator/emulator" -avd Pixel_6_API35 -gpu host &
"$ADB" wait-for-device
"$ADB" install -r build/mobilegame-debug.apk
"$ADB" shell am start -n com.jsgame.template/com.godot.game.GodotAppLauncher

# 로그 확인 / 화면 캡처
"$ADB" logcat -d | grep -i godot
"$ADB" exec-out screencap -p > shot.png
```

진동(`Settings.vibrate()`)을 위해 두 Android preset 모두 `permissions/vibrate=true` 다.

런처 액티비티는 `GodotAppLauncher`다. `GodotApp`은 exported=false라 `am start`로
직접 띄우면 Permission Denial이 난다.

`monkey`로 앱을 띄우지 말 것 — 랜덤 이벤트를 주입해서 UI를 눌러버린다.

### preset

`gradle_build=false`로 시작한다 — 순수 템플릿은 gradle이 불필요하다.
실제 Android 플러그인(AdMob 등)을 붙이는 시점에 gradle 빌드로 전환할 것.

아키텍처는 `arm64-v8a` 단독이다 — APK 크기가 절반이고 요즘 기기와 에뮬레이터를
모두 커버한다. 32비트 기기까지 필요하면 `armeabi-v7a`를 켤 것.

패키지명·번들 ID `com.jsgame.template`과 `icon.svg`는 **플레이스홀더다** (Android·iOS preset 모두). 실제 게임을
얹을 때 둘 다 바꿔라 — 패키지명은 스토어 등록 후에는 변경할 수 없다.

Release preset은 `exclude_filter="debug/*"`로 디버그 패널을 제외한다. 확인 방법:

```bash
unzip -o build/mobilegame-release.apk -d /tmp/rel && grep -rl debug_panel /tmp/rel
# 아무것도 안 나와야 한다. 디버그 APK에는 assets/debug/debug_panel.gd.remap이 있다.
```

### 릴리스 서명

릴리스 keystore는 저장소에 넣지 않는다 — `--export-release`는 지금 서명 단계에서
의도적으로 실패한다(APK 자체는 생성됨). 출시 시점에 생성하고 에디터 설정 또는
preset의 keystore 항목에 지정할 것:

```bash
keytool -v -genkey -keystore release.keystore -alias <alias> \
  -keyalg RSA -keysize 2048 -validity 10000
```
