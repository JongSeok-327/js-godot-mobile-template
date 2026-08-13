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


## SDK 초기화. 앱 시작 시 한 번 — Services가 대신 불러준다.
@abstract func initialize() -> void


## 리워드 광고를 지금 띄울 수 있는지. 버튼 활성화 판단용.
@abstract func is_rewarded_ready() -> bool


## placement는 호출 지점 이름("double_reward" 등) — 지표용이라 signal로 되돌아온다.
@abstract func show_rewarded(placement: String) -> void


@abstract func show_interstitial(placement: String) -> void
