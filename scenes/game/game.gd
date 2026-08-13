extends Control
## 게임 셸.
##
## 실제 게임플레이는 Gameplay 노드 아래에 얹는다. 이 스크립트가 책임지는 것은
## HUD, 일시정지, 안드로이드 생명주기뿐이다.

const PauseMenuScene := preload("res://scenes/overlays/pause_menu.tscn")

@onready var _pause_button: Button = %PauseButton

var _pause_menu: CanvasLayer


func _ready() -> void:
	_pause_button.pressed.connect(toggle_pause)

	_pause_menu = PauseMenuScene.instantiate()
	_pause_menu.visible = false
	_pause_menu.resume_requested.connect(set_paused.bind(false))
	_pause_menu.main_menu_requested.connect(_on_main_menu_requested)
	add_child(_pause_menu)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			# 안드로이드 뒤로가기 — 게임 중에는 일시정지 토글.
			toggle_pause()
		NOTIFICATION_APPLICATION_PAUSED:
			# 백그라운드로 넘어가면 안드로이드는 언제든 프로세스를 죽일 수 있다.
			# 멈추고 저장부터 한다.
			set_paused(true)
			SaveManager.save_game()


func toggle_pause() -> void:
	set_paused(not get_tree().paused)


func set_paused(paused: bool) -> void:
	if get_tree().paused == paused:
		return

	get_tree().paused = paused
	_pause_menu.visible = paused
	if paused:
		_pause_menu.focus_default()

	EventBus.game_paused.emit(paused)


func _on_main_menu_requested() -> void:
	# paused 해제는 SceneManager가 전환 직전에 강제로 처리한다.
	SceneManager.change_scene("main_menu")
