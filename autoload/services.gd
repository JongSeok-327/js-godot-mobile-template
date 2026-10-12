extends Node
## 플랫폼 서비스 로케이터.
##
## 게임 코드는 `Services.ads` / `Services.iap`만 본다. 광고·결제 SDK는
## 플랫폼마다 다르고 에디터에는 아예 없으므로, 인터페이스 뒤에 숨겨두고
## 구현을 바꿔 끼운다. 인터페이스는 scripts/services/에 있다.
##
## **실제 SDK를 붙이는 지점은 아래 _ready() 두 줄이 전부다.**
## AdService/IAPService를 상속한 구현을 만들어 Null 대신 넣으면 된다 —
## 게임 코드는 건드릴 필요가 없다.

var ads: AdService
var iap: IAPService


func _ready() -> void:
	ads = NullAdService.new()
	iap = NullIAPService.new()

	# 광고가 화면을 덮는 동안 배경음악을 멈춘다 (iOS 는 광고가 떠도 앱이 일시정지되지 않는다).
	ads.fullscreen_changed.connect(AudioManager.set_music_paused)

	# 실제 SDK는 초기화에 시간이 걸린다. 앱 시작 시 한 번만 부르고,
	# 결과가 필요하면 initialized signal을 듣는다.
	ads.initialize()
	iap.initialize()
