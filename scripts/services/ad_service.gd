@abstract
class_name AdService
extends RefCounted
## 광고 SDK 인터페이스. 게임 코드는 이 타입만 본다.
##
## 실제 구현(AdMob 등)을 붙일 때는 이 클래스를 상속해서 Services.ads에 꽂는다.
## 게임 코드는 한 줄도 바뀌지 않는다.
##
## 결과는 전부 signal로 돌아온다 — 요청 함수는 값을 반환하지 않는다.
## 실제 광고는 네트워크와 전면 UI를 거치므로 동기 응답이 애초에 불가능하다.

## initialize() 결과.
signal initialized(success: bool)

## 리워드 광고가 끝났을 때. rewarded=false면 중도 이탈 — 보상을 주면 안 된다.
signal rewarded_completed(placement: String, rewarded: bool)

## 전면 광고가 닫혔을 때.
signal interstitial_closed(placement: String)

## `is_rewarded_ready()` 가 바뀌었을 때. **광고 버튼은 이걸 듣고 다시 그린다.**
##
## 실제 SDK 는 광고를 받는 데 몇 초가 걸리고, 보여준 뒤에는 다음 광고를 새로 받는다.
## 화면을 열 때 한 번만 보면 부팅 직후의 버튼은 꺼진 채 안 켜진다.
signal rewarded_ready_changed(is_ready: bool)

## 광고가 화면을 덮기 시작했을 때(true)·닫혔을 때(false). 배경음악을 멈추는 데 쓴다.
##
## iOS 광고는 같은 앱 위에 뜨는 화면이라 앱이 일시정지되지 않는다 — 알려주지 않으면
## 광고 소리 뒤로 게임 음악이 계속 흐른다 (iPhone 실기기에서 밟았다).
## 실제 구현은 띄우기 직전에 true, 닫힌 직후(결과 signal 보다 먼저) false 를 보낸다.
signal fullscreen_changed(showing: bool)


## SDK 초기화. 앱 시작 시 한 번 — Services가 대신 불러준다.
@abstract func initialize() -> void


## 리워드 광고를 지금 띄울 수 있는지. 버튼 활성화 판단용.
@abstract func is_rewarded_ready() -> bool


## placement는 호출 지점 이름("double_reward" 등) — 지표용이라 signal로 되돌아온다.
##
## 결과는 `rewarded_completed` 로 **반드시** 돌아온다 — 준비가 안 됐으면 false 로.
## 부르는 화면은 그걸 기다리며 버튼을 잠가 두므로, 조용히 돌아가면 그 화면이 영영 잠긴다.
## 이미 하나를 보여주는 중이면(연타) 새 요청은 무시한다 — 답은 앞선 요청이 돌려준다.
@abstract func show_rewarded(placement: String) -> void


## 전면 광고를 지금 띄울 수 있는지. 못 띄우면 호출자는 광고 없이 그냥 진행한다.
@abstract func is_interstitial_ready() -> bool


## 결과는 `interstitial_closed` 로 **반드시** 돌아온다 — 못 띄워도.
@abstract func show_interstitial(placement: String) -> void
