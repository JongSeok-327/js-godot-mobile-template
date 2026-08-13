extends Control
## 메인 메뉴.
##
## 버튼 라벨은 번역 키다 — Godot이 Control의 text를 자동 번역한다.
## locale/translations.csv가 붙기 전까지는 키가 그대로 보인다.

const SettingsMenuScene := preload("res://scenes/overlays/settings_menu.tscn")

@onready var _play_button: Button = %PlayButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton

var _settings_menu: CanvasLayer


func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_play_button.grab_focus()


func _notification(what: int) -> void:
	# 안드로이드 뒤로가기 — 메뉴에서는 종료. (quit_on_go_back=false라 직접 처리한다.)
	# 설정이 떠 있으면 설정이 자기 자신을 닫는다.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and _settings_menu == null:
		get_tree().quit()


func _on_play_pressed() -> void:
	SceneManager.change_scene("game")


func _on_settings_pressed() -> void:
	_settings_menu = SettingsMenuScene.instantiate()
	_settings_menu.closed.connect(_on_settings_closed)
	add_child(_settings_menu)


func _on_settings_closed() -> void:
	_settings_menu.queue_free()
	_settings_menu = null
	_settings_button.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()
