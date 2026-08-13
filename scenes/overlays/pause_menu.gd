extends CanvasLayer
## 일시정지 오버레이.
##
## 트리가 멈춘 상태에서도 버튼이 눌려야 하므로 PROCESS_MODE_ALWAYS다.
## 여기서는 일시정지 상태를 직접 바꾸지 않는다 — signal만 올리고 판단은 게임 셸이 한다.

signal resume_requested
signal settings_requested
signal main_menu_requested


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	%ResumeButton.pressed.connect(resume_requested.emit)
	%MainMenuButton.pressed.connect(main_menu_requested.emit)


func focus_default() -> void:
	%ResumeButton.grab_focus()
