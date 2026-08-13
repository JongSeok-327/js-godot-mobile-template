# CLAUDE.md — MobileGame Template

Godot 4.7.1 / GDScript로 만드는 **재사용 가능한 2D 세로 모바일 게임 틀**.
실제 게임 로직은 이 틀 위에 얹는다. 구현 플랜은 `docs/PLAN.md` 참고.

## 환경

| 항목 | 값 |
|---|---|
| Godot 실행 파일 | `/Applications/Godot_4.7.1.app/Contents/MacOS/Godot` |
| Godot 버전 | `4.7.1.stable` (`/Applications/Godot.app`의 4.6.2와 병행 설치) |
| export templates | `~/Library/Application Support/Godot/export_templates/4.7.1.stable/` |
| Android SDK / JDK | **미설치** — Phase 7(Android export) 보류 중 |

> export template 버전 문자열은 에디터 버전과 **정확히** 일치해야 한다.
> Godot을 업그레이드하면 템플릿도 같은 버전으로 재설치할 것.

## 명령어

```bash
GODOT=/Applications/Godot_4.7.1.app/Contents/MacOS/Godot

# 스모크 테스트 — 매 커밋 전 필수 (파스 에러/깨진 autoload/누락 리소스 검출)
"$GODOT" --headless --path . --quit

# 에디터에서 실행
"$GODOT" --path . --editor

# 단위 테스트 (SceneTree 기반, Phase 2부터)
./tests/run_all.sh
```

## 코드 규약

- **`res://` 경로는 전부 lowercase snake_case.** macOS는 대소문자를 무시하지만
  Android는 구분한다 — 맥에서 돌던 게 기기에서 리소스 누락으로 깨지는 대표 원인.
- 씬 경로를 게임 코드에 하드코딩하지 않는다. `SceneManager.SCENES` 레지스트리의
  문자열 ID를 쓴다.
- 플랫폼 의존 코드(광고/IAP 등)는 `scripts/services/`의 인터페이스 뒤에 숨긴다.
  게임 코드는 `Services.ads` / `Services.iap`만 본다.
- 디버그 전용 리소스는 `debug/`에 두고 `preload`가 아닌 `load`로 가져온다
  (릴리스 preset에서 `debug/*`를 제외할 수 있어야 하므로).

## 디렉토리

```
autoload/   EventBus, SaveManager, Settings, AudioManager, SceneManager, Services, DebugTools
scenes/     boot/, main_menu/, game/, overlays/
ui/         theme/, components/
scripts/    services/, input/, utils/
debug/      디버그 패널 (릴리스 빌드 제외)
locale/     translations.csv (key,en,ko,ja)
assets/     audio/, fonts/, sprites/, ui/
tests/      run_all.sh + test_*.gd
build/      export 산출물 (gitignore)
```

## Android (Phase 7 — 보류)

이 머신에 JDK/Android SDK/adb가 없어 APK export는 아직 검증되지 않았다.
재개하려면 JDK 17–21, Android command-line tools(SDK + platform-tools + emulator),
`~/.android/debug.keystore`가 필요하고, 에디터 설정에 다음을 지정해야 한다:

- `export/android/android_sdk_path`
- `export/android/java_sdk_path` (Homebrew openjdk는 keg-only라 자동 인식 안 됨 — 명시 필수)
- `export/android/debug_keystore`

`gradle_build=false`로 시작한다 — 순수 템플릿은 gradle이 불필요하다.
실제 Android 플러그인(AdMob 등)을 붙이는 시점에 gradle 빌드로 전환할 것.

릴리스 keystore는 저장소에 넣지 않는다. 출시 시점에 생성:

```bash
keytool -v -genkey -keystore release.keystore -alias <alias> \
  -keyalg RSA -keysize 2048 -validity 10000
```
