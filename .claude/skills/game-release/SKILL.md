---
name: game-release
description: 게임의 iOS·Android 출시 준비를 점검하고 남은 일을 사람 작업/자동화 가능 작업으로 나눈다. "출시 준비", "남은 작업", "TestFlight", "App Store 제출", "Play 스토어", "심사", "스토어 등록", "keystore", "Team ID" 요청에 사용한다.
---

# game-release

## 확인 목록

상태는 저장소에서 직접 확인한다. 기억으로 답하지 않는다.

### 공통

| 항목 | 확인 방법 | 사람 작업? |
|---|---|---|
| 패키지명·번들 ID | `export_presets.cfg` 가 플레이스홀더 `com.jsgame.template` 이 아님 | 결정은 사람 (스토어 등록 뒤 변경 불가) |
| 앱 이름·버전 | `project.godot` 의 `config/name`·`config/version`, preset 의 버전 | — |
| 앱 아이콘 | `config/icon` 이 플레이스홀더 `icon.svg` 가 아님 | 아트는 사람 |
| 디버그 패널 제외 | 출시 preset 의 `exclude_filter` 에 `debug/*` | — |
| 실제 키·광고 단위 | `config/*.cfg` 가 있고, **커밋되지 않았다** (`.githooks` 켜짐: `git config core.hooksPath`) | 값 발급은 사람 |
| `.cfg` 가 패키지에 들어가는가 | preset `include_filter` 에 `config/*.cfg` (리소스가 아니라 자동 포함 안 된다) | — |
| 개인정보 처리방침 URL | — | **사람** (게시). 초안은 코드의 수집 항목에서 뽑아 줄 수 있다 |
| 개인정보 라벨 | App Store "앱 개인정보 보호" 응답·Play "데이터 보안" 양식이 방침·실제 수집(광고 SDK 포함)과 맞음 | **사람** (콘솔 입력). 항목 초안은 자동화 가능 |
| 권한 | preset 의 권한·사용 설명마다 실제로 쓰는 곳이 있음 (안 쓰는 권한은 심사 질문거리) | — |
| 백그라운드 동작 | 홈으로 나갔다 돌아오기·통화·잠금에서 일시정지·저장·복귀가 맞음 (`game-device-qa`) | 기기 확인 |
| 패키지 크기 | export 산출물 크기 확인 — 셀룰러 다운로드 경고·스토어 한도에 걸리지 않음 | — |

### iOS

| 항목 | 확인 방법 | 사람 작업? |
|---|---|---|
| Xcode 본체 | `xcode-select -p` 가 `/Applications/Xcode.app/...` | 설치는 사람 |
| Team ID | 로컬 preset 의 `app_store_team_id` 가 비어 있지 않음 (커밋은 빈 값) | **사람** (Developer Program 가입. 무료 Personal Team 은 실기기 7일 설치까지만) |
| 실기기 Release 확인 | `tools/device.sh ios-release` | — |
| 최소 iOS / iPhone 전용 | preset: 15.0 / `targeted_device_family=0` | — |
| 카메라·마이크·사진 설명 | 두 iOS preset 모두 비어 있지 않음 | — |
| ATT | 맞춤 광고를 안 쓰면 팝업 없음 → `NSUserTrackingUsageDescription` 도 없어야 한다 | 정책 판단은 사람 |
| 종료 버튼 | iOS 에서 숨김 (`main_menu.gd`) | — |
| 사용자 생성 콘텐츠 | 닉네임·채팅 등이 있으면 신고·차단 기능 필요 (App Store 1.2) | — |

### Android

| 항목 | 확인 방법 | 사람 작업? |
|---|---|---|
| 릴리스 keystore | preset 의 keystore 항목 | **사람** (생성·보관. 잃으면 업데이트 불가) |
| AAB | 릴리스 preset `gradle_build/export_format=1` (gradle 빌드 필요) | — |
| 비공개 테스트 | 신규 개인 계정은 프로덕션 전 테스터 12명 × 14일 연속 | **사람** |
| 진동 권한 | `permissions/vibrate=true` | — |

## 정책은 확인한다

스토어 요건은 바뀐다. 판단이 걸린 항목은 Apple/Google 공식 문서를 확인하고 출처 링크를 남긴다.
