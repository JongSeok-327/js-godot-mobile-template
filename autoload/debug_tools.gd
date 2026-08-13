extends Node
## 디버그 도구 부착점. 릴리스 빌드에서는 아무 일도 하지 않는다.
##
## 패널을 `preload`하지 않고 `load()`로 가져오는 이유: 릴리스 export preset에서
## `debug/*`를 통째로 제외할 수 있어야 하기 때문이다. preload는 컴파일 시점에
## 의존성이 박혀서, 파일이 빠진 릴리스 빌드가 로드 에러로 죽는다.
## **여기 말고 어디서도 debug/를 참조하지 말 것.**

const PANEL_SCENE_PATH := "res://debug/debug_panel.tscn"

## register_cheat()로 치트가 추가됐을 때. 패널이 버튼을 붙인다.
signal cheat_registered(label: String, callback: Callable)

## {"label": String, "callback": Callable}
var _cheats: Array[Dictionary] = []
var _panel: CanvasLayer


func _ready() -> void:
	if not OS.is_debug_build():
		return
	# 릴리스 preset에서 제외했다면 파일 자체가 없다 — load() 에러 대신 조용히 넘어간다.
	if not ResourceLoader.exists(PANEL_SCENE_PATH):
		push_warning("[debug] 패널 씬이 없어 건너뛴다: %s" % PANEL_SCENE_PATH)
		return

	var scene: PackedScene = load(PANEL_SCENE_PATH)
	_panel = scene.instantiate()
	add_child(_panel)


## 디버그 패널에 버튼 하나를 붙인다. 게임 쪽에서 치트를 다는 지점:
## [codeblock]
## DebugTools.register_cheat("코인 +100", func() -> void: _add_coins(100))
## [/codeblock]
## 릴리스 빌드에서는 목록에만 남고 아무 일도 일어나지 않는다.
func register_cheat(label: String, callback: Callable) -> void:
	_cheats.append({"label": label, "callback": callback})
	cheat_registered.emit(label, callback)


func get_cheats() -> Array[Dictionary]:
	return _cheats


## 디버그 패널이 떠 있는지. 릴리스 빌드에서는 항상 false.
func has_panel() -> bool:
	return _panel != null
