extends Node
## 버튼 클릭음을 자동으로 붙인다.
##
## 씬마다 버튼 하나하나에 효과음을 연결하면 새 버튼을 추가할 때마다 빠뜨리고,
## 런타임에 만든 버튼(디버그 패널의 씬 점프 버튼 등)은 아예 놓친다.
## 트리에 들어오는 모든 BaseButton을 여기서 한 번에 잡는다 — 씬 코드는 무변경.
##
## `node_added`는 모든 노드 추가마다 불리지만 하는 일은 타입 검사 하나다.
## 프레임마다 수백 개를 스폰하는 게임이라면 이 autoload를 빼고 씬별로 붙여라.
##
## 특정 버튼만 조용히 하려면: `button.set_meta("silent", true)`

const CLICK_SFX := preload("res://assets/audio/sfx/ui_click.ogg")
const SILENT_META := &"silent"


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(_on_button_pressed.bind(node))


func _on_button_pressed(button: BaseButton) -> void:
	if button.get_meta(SILENT_META, false):
		return
	AudioManager.play_sfx(CLICK_SFX)
