extends Control
## 최초 진입 씬.
##
## 로고를 잠깐 보여주는 동안 autoload들이 초기화를 끝낸다 — 사용자에게는
## "로딩 화면"이지만 실제 목적은 첫 프레임의 어수선함을 가리는 것이다.

## 로고 노출 최소 시간(초).
const SPLASH_TIME := 0.8

@onready var _title: Label = %Title


func _ready() -> void:
	_title.text = str(ProjectSettings.get_setting("application/config/name", ""))
	await get_tree().create_timer(SPLASH_TIME).timeout
	SceneManager.change_scene("main_menu")
