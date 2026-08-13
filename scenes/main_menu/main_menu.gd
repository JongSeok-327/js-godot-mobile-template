extends Control
## 메인 메뉴.
##
## 버튼 라벨은 번역 키다 — Godot이 Control의 text를 자동 번역한다.
## locale/translations.csv가 붙기 전까지는 키가 그대로 보인다.

@onready var _play_button: Button = %PlayButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_play_button.grab_focus()


func _on_play_pressed() -> void:
	SceneManager.change_scene("game")


func _on_quit_pressed() -> void:
	get_tree().quit()
