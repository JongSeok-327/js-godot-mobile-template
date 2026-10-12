#!/usr/bin/env bash
# 기기 확인 도우미. 하위 명령:
#   android         디버그 APK export → 설치 → 실행 (기기 1대: 에뮬레이터 또는 실기기)
#   logs [패턴]     godot 로그에서 패턴 검색 (기본: SCRIPT ERROR / ERROR / [save] [ads])
#   shot <파일>     Android 화면 캡처 (PNG)
#   ios             iPhone 실기기: "iOS Debug" export → xcodebuild → 설치 → 실행
#   ios-release     iPhone 실기기: 출시용 "iOS" preset → Release 빌드(개발 인증서로 서명) → 설치
#   ios-shot <파일> iPhone 화면 캡처
#   ios-pull <앱 경로> <파일>  앱 데이터에서 파일 가져오기 (user:// = Documents/)
#
# 패키지명·Xcode 프로젝트 이름은 export_presets.cfg 에서 읽는다 — 게임을 얹고 바꿔도 여기는 그대로다.
# iOS 는 로컬 preset 에 Team ID(무료 Personal Team 도 됨)가 있어야 한다 — 커밋 금지(.githooks).
# 여러 Android 기기가 붙어 있으면 ANDROID_SERIAL=<serial> 로 고른다 (adb devices).
set -uo pipefail
cd "$(dirname "$0")/.."
# build/ 는 프로젝트 안이라 .gdignore 가 없으면 Godot 이 산출물(iOS .app 의 PNG 등)까지
# 리소스로 가져와 패키지에 섞는다(kongkong 실측 +1.9MB, export 마다 아이콘 ERROR).
mkdir -p build && touch build/.gdignore
export JAVA_HOME="${JAVA_HOME:-$HOME/Library/Java/jdk-21.0.12+8/Contents/Home}"
ADB="$HOME/Library/Android/sdk/platform-tools/adb"
GODOT="${GODOT:-/Applications/Godot_4.7.1.app/Contents/MacOS/Godot}"
PKG=$(grep -m1 '^package/unique_name=' export_presets.cfg | cut -d'"' -f2)
BUNDLE=$(grep -m1 '^application/bundle_identifier=' export_presets.cfg | cut -d'"' -f2)
# Xcode 프로젝트·scheme 이름 = iOS preset export_path 의 파일 이름.
APP=$(grep -A10 '^name="iOS"$' export_presets.cfg | grep -m1 '^export_path=' | cut -d'"' -f2 | xargs basename | sed 's/\.xcodeproj$//')

ios_build() {  # $1=preset $2=Debug|Release $3=프로젝트 디렉터리 $4=DerivedData
  local proj="$3/$APP.xcodeproj"
  mkdir -p "$3"
  if [ "$2" = Release ]; then
    "$GODOT" --headless --path . --export-release "$1" "$proj" 2>&1 | grep -E "ERROR|SCRIPT" | head -5
  else
    "$GODOT" --headless --path . --export-debug "$1" "$proj" 2>&1 | grep -E "ERROR|SCRIPT" \
      | grep -v "AppIcon.appiconset\|SplashImage" | head -5
  fi
  # 출시 preset 은 배포 인증서로 서명하게 돼 있다(App Store 제출용). 무료 팀엔 배포 인증서가
  # 없으니 기기 확인은 개발 인증서로 덮어쓴다.
  # DerivedData 를 따로 둔다 — Xcode 앱이 같은 프로젝트를 열고 있으면 공용 DerivedData 의
  # SPM 산출물(광고 SDK 등)을 지워 명령줄 빌드가 매번 깨졌다(kongkong).
  local build=(xcodebuild -project "$proj" -scheme "$APP" -configuration "$2" -derivedDataPath "$4"
               -destination "id=$DEV" -allowProvisioningUpdates CODE_SIGN_IDENTITY="Apple Development" build)
  if ! "${build[@]}" 2>&1 | grep -q "BUILD SUCCEEDED"; then
    xcodebuild -project "$proj" -scheme "$APP" -derivedDataPath "$4" -resolvePackageDependencies >/dev/null 2>&1
    "${build[@]}" 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)" | sort -u | tail -3 | tee /dev/stderr \
      | grep -q SUCCEEDED || { echo "빌드 실패 — 설치하지 않는다"; exit 1; }
  fi
  xcrun devicectl device install app --device "$DEV" "$4/Build/Products/$2-iphoneos/$APP.app" 2>&1 \
    | grep -iE "error|installed" | head -2
  xcrun devicectl device process launch --terminate-existing --device "$DEV" "$BUNDLE" 2>&1 | tail -1
}

case "${1:-}" in
  android)
    "$ADB" get-state >/dev/null 2>&1 || { echo "연결된 Android 기기가 없다 (adb devices)"; exit 1; }
    "$GODOT" --headless --path . --export-debug "Android Debug" build/debug.apk 2>&1 | grep -E "^ERROR" | head -5
    # 기기가 잠깐 offline 이 되면 install 이 조용히 실패하고 옛 APK 가 돈다 — kongkong 에서 밟았다.
    "$ADB" wait-for-device
    "$ADB" install -r build/debug.apk 2>&1 | tail -1 | grep -q Success || { echo "설치 실패"; exit 1; }
    "$ADB" logcat -c
    "$ADB" shell am force-stop "$PKG"
    # GodotApp 은 exported=false 라 직접 띄우면 Permission Denial — 런처 액티비티로 띄운다.
    "$ADB" shell am start -n "$PKG/com.godot.game.GodotAppLauncher" >/dev/null
    echo "설치·실행 완료 ($PKG). logs 로 확인한다."
    ;;
  logs)
    pat="${2:-\[ads\]|\[save\]|SCRIPT ERROR|ERROR}"
    "$ADB" logcat -d -s godot 2>/dev/null | grep -E "$pat" | tail -30
    ;;
  shot)
    [ -n "${2:-}" ] || { echo "사용: shot <파일.png>"; exit 1; }
    "$ADB" exec-out screencap -p > "$2" && echo "$2"
    ;;
  ios|ios-release|ios-shot|ios-pull)
    # 연결된 실기기 하나. 'available (paired)' 상태도 잡는다. 잠겨 있으면 실행만 실패한다(설치는 된다).
    DEV=$(xcrun devicectl list devices 2>/dev/null | awk '/physical/ && (/connected/ || /available/) {for(i=1;i<=NF;i++) if($i ~ /^[0-9A-F]{8}-[0-9A-F]{16}$/) print $i}' | head -1)
    [ -n "$DEV" ] || { echo "연결된 iPhone 이 없다 (xcrun devicectl list devices — 개발자 모드·신뢰 확인)"; exit 1; }
    case "$1" in
      ios-shot)
        [ -n "${2:-}" ] || { echo "사용: ios-shot <파일.png>"; exit 1; }
        xcrun devicectl device capture screenshot --device "$DEV" --destination "$2" >/dev/null 2>&1 && echo "$2"
        ;;
      ios-pull)
        [ -n "${3:-}" ] || { echo "사용: ios-pull Documents/save.json <파일>"; exit 1; }
        xcrun devicectl device copy from --device "$DEV" --domain-type appDataContainer \
          --domain-identifier "$BUNDLE" --source "$2" --destination "$3" 2>&1 | tail -1
        ;;
      *)
        grep -q 'app_store_team_id=""' export_presets.cfg && { echo "iOS preset 에 Team ID 가 비어 있다 — 로컬에만 넣는다(커밋 금지)"; exit 1; }
        # "iOS" 는 debug/* 를 빼므로 디버그 패널이 필요하면 "iOS Debug" 를 쓴다.
        if [ "$1" = ios-release ]; then ios_build "iOS" Release build/ios build/ios_rel_dd
        else ios_build "iOS Debug" Debug build/ios_debug build/ios_dd; fi
        ;;
    esac
    ;;
  *) sed -n '2,14p' "$0"; exit 1 ;;
esac
