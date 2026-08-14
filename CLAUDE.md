# CLAUDE.md — MobileGame Template

Godot 4.7.1 / GDScript로 만드는 **재사용 가능한 2D 세로 모바일 게임 틀**.
실제 게임 로직은 이 틀 위에 얹는다. 구현 플랜은 `docs/PLAN.md` 참고.

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
```

> `.godot/`과 `locale/*.translation`은 저장소에 없다 — 둘 다 임포트로 생성되는
> 산출물이다. 새로 클론했다면 `--import`를 먼저 돌려야 번역이 로드되고
> 스모크 테스트가 통과한다. 반대로 스크립트의 `.uid` 파일은 커밋한다
> (머신마다 새로 생성되면 `uid://` 참조가 깨진다).

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

## 디렉토리

```
autoload/   EventBus, SaveManager, Settings, AudioManager, SceneManager, Services, DebugTools
scenes/     boot/, main_menu/, game/, overlays/
ui/         theme/, components/
scripts/    services/, input/, utils/
debug/      디버그 패널 (릴리스 빌드 제외)
locale/     translations.csv (key,en,ko,ja)
assets/     audio/(bus layout, sfx), fonts/(Noto KR·JP), ui/(슬라이더 그래버)
tests/      run_all.sh + test_runner.tscn + test_*.gd
build/      export 산출물 (gitignore)
```

## 테스트

`./tests/run_all.sh` 하나로 전부 돈다. 프레임워크는 쓰지 않는다.

새 테스트를 추가하려면: `tests/test_*.gd`를 `extends RefCounted`로 만들고
`func run(t: Node) -> void` 하나만 두고, `tests/test_runner.gd`의 `TESTS` 배열에
preload로 등록한다. 단언은 `t.check(조건, 라벨)` / `t.eq(실제, 기대, 라벨)`.

함정 세 가지 — 전부 실제로 밟은 것이다:

- **`-s res://tests/x.gd` 스크립트 모드를 쓰지 마라.** 그 모드에서는 autoload가
  인스턴스화되지 않아 `EventBus` 같은 전역 식별자가 **컴파일조차 되지 않는다**.
  그래서 러너를 씬(`test_runner.tscn`)으로 띄운다.
- **GDScript 컴파일 에러는 종료 코드 0으로 나온다.** `run_all.sh`가 출력에서
  `SCRIPT ERROR|Failed to load script|Parse Error`를 함께 검사하는 이유다.
  Godot을 직접 호출하지 말고 항상 `run_all.sh`로 돌려라.
- **테스트에서 `Node`를 `.new()`로 만들면 `free()` 해야 한다.** RefCounted가
  아니라서 안 하면 종료 시 ObjectDB 누수로 잡힌다.

러너는 한 프레임 넘긴 뒤 시작한다 — `root`가 자식을 세팅하는 동안에는
`add_child()`가 거부되기 때문이다.

## Android

아래 명령은 전부 실제로 실행해 검증한 것이다.

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

런처 액티비티는 `GodotAppLauncher`다. `GodotApp`은 exported=false라 `am start`로
직접 띄우면 Permission Denial이 난다.

`monkey`로 앱을 띄우지 말 것 — 랜덤 이벤트를 주입해서 UI를 눌러버린다.

### preset

`gradle_build=false`로 시작한다 — 순수 템플릿은 gradle이 불필요하다.
실제 Android 플러그인(AdMob 등)을 붙이는 시점에 gradle 빌드로 전환할 것.

아키텍처는 `arm64-v8a` 단독이다 — APK 크기가 절반이고 요즘 기기와 에뮬레이터를
모두 커버한다. 32비트 기기까지 필요하면 `armeabi-v7a`를 켤 것.

패키지명 `com.jsgame.template`과 `icon.svg`는 **플레이스홀더다.** 실제 게임을
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
