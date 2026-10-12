---
name: game-device-qa
description: 게임을 iPhone 실기기·Android 에뮬레이터/실기기에 설치하고 스크린샷·로그·앱 데이터로 변경 사항을 확인한다. 광고·저장·앱 수명주기·세이프 에어리어·햅틱·레이아웃·플랫폼 분기를 바꿨을 때, "기기에서 확인해줘", "에뮬레이터로 봐줘", "실기기 테스트" 요청에 사용한다. 단위 테스트 판정은 game-verify 다.
---

# game-device-qa

## 도구

```bash
D=tools/device.sh
$D android                # 디버그 APK export → 설치 → 실행
$D logs                   # [ads] [save] SCRIPT ERROR ERROR
$D logs "패턴"
$D shot <스크래치패드>/x.png
$D ios                    # iPhone: iOS Debug export → 빌드 → 설치 → 실행
$D ios-release            # iPhone: 출시 preset → Release 빌드(개발 서명) → 설치 — 디버그 패널 없음 확인용
$D ios-shot <스크래치패드>/x.png
$D ios-pull Documents/save.json <스크래치패드>/save.json
```

패키지명·번들 ID·Xcode 프로젝트 이름은 `export_presets.cfg` 에서 읽는다.
기기가 여러 대면 `ANDROID_SERIAL=<serial>` (`adb devices` 로 확인).
기기가 없으면 에뮬레이터: `"$HOME/Library/Android/sdk/emulator/emulator" -avd Pixel_6_API35 -gpu host &`

화면비만 보면 되는 레이아웃 확인은 기기 대신 데스크톱 촬영으로 먼저 본다:
`"$GODOT" --path . res://debug/layout_shots.tscn -- --out=<스크래치패드>/shots`

**iPhone 은 이렇게 확인한다 (kongkong 에서 정립):**
- 올리기 **전에 스모크**(`game-verify`)를 돌린다. 파스 에러가 난 스크립트를 올리면 그 스크립트를
  참조하는 화면까지 통째로 깨진다.
- Godot 의 `print` 는 `devicectl --console` 로 **안 나온다**. 기기에서 값을 보려면 `user://` 에
  파일로 쓰고 `ios-pull Documents/<파일>` 로 가져온다. 측정 코드는 데스크톱에서 그 파일이 실제로
  생기는지 먼저 확인한다.
- 화면을 봐야 하면 사람에게 그 화면을 띄워 달라고 하고 `ios-shot`. 사용자 체감("흔들린다")은
  캡처 픽셀·측정 로그로 먼저 원인을 좁힌다.
- 잠금 상태면 실행만 실패한다 — 사람에게 잠금 해제를 부탁한다.

## 변경 종류별 확인 목록

이번 변경에 해당하는 것만 확인한다.

| 바꾼 것 | 확인 | 근거로 남길 것 |
|---|---|---|
| 광고 | SDK 초기화 로그 → 광고 버튼이 **화면을 나가지 않고** 켜짐(`rewarded_ready_changed`) → 끝까지 보면 보상 → 닫은 뒤 다음 광고 로드 → 광고 중 음악 정지·일시정지 메뉴 없음 | 로그 줄, 전후 스크린샷 |
| 광고 실패 경로 | 비행기 모드(`adb shell cmd connectivity airplane-mode enable`) → 재시도 로그, 광고 버튼 비활성. **끝나면 반드시 해제** | 로그 줄, 스크린샷 |
| 저장 | `adb shell run-as <패키지> ls -la files/` 에 `save.json` + `save.json.bak`, `.tmp` 없음 | ls 출력 |
| 레이아웃 | 세이프 에어리어(노치·홈 인디케이터), 긴 숫자·이름 | 스크린샷 |
| 플랫폼 분기 | Android 에서 기존 동작 유지 (예: 종료 버튼 보임). iOS 는 `ios` 로 실기기 확인 + export 결과(Info.plist) | 스크린샷, plist 발췌 |
| 햅틱 | 설정에서 진동 켜기 → 한 번 울림, 끄면 안 울림 | 사람 확인 |

## 지켜야 할 것

- **좌표는 그 기기의 스크린샷을 보고 정한다.** 해상도·비율이 기기마다 달라 같은 좌표가 다른 버튼을 누른다.
- 광고는 디버그 빌드에서 항상 테스트 단위를 쓰게 만든다 — 실제 단위로 반복 재생하면 무효 트래픽으로 계정이 정지된다.
- iOS 시뮬레이터는 쓰지 않는다 (CLAUDE.md iOS 절). 실기기는 사람이 연결·신뢰·개발자 모드를 켜야 한다.
- `monkey` 로 앱을 띄우지 않는다 — UI 를 무작위로 누른다.
