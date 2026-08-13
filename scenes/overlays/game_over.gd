extends CanvasLayer
## 게임 오버 오버레이.
##
## 일시정지 메뉴와 달리 사용자가 임의로 닫을 수 없다 — 재시도나 메뉴 복귀 중
## 하나를 골라야 한다. 뒤로가기로 빠져나가는 경로는 게임 셸이 막는다.

signal retry_requested
signal main_menu_requested


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	%RetryButton.pressed.connect(retry_requested.emit)
	%MainMenuButton.pressed.connect(main_menu_requested.emit)
	%RetryButton.grab_focus()
