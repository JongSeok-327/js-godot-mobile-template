extends Node
## headless 테스트 러너.
##
## `-s`(SceneTree 스크립트) 방식이 아니라 씬으로 도는 이유: 스크립트 모드에서는
## autoload가 아예 인스턴스화되지 않아 EventBus 같은 전역 식별자가 컴파일조차
## 되지 않는다. 정상 게임 모드로 띄워야 실제 환경 그대로 테스트할 수 있다.
##
## 각 테스트는 `run(t)` 하나만 가진 RefCounted다. t.check / t.eq로 단언한다.

const TESTS: Array[Script] = [
	preload("res://tests/test_save_manager.gd"),
	preload("res://tests/test_settings.gd"),
	preload("res://tests/test_audio_manager.gd"),
	preload("res://tests/test_scene_manager.gd"),
	preload("res://tests/test_theme.gd"),
]

var _passed := 0
var _failed := 0


func _ready() -> void:
	# root가 자식을 세팅하는 동안에는 add_child()가 거부된다.
	# 트리에 노드를 붙여 검사하는 테스트를 위해 한 프레임 넘긴 뒤 시작한다.
	await get_tree().process_frame

	for script in TESTS:
		var suite: RefCounted = script.new()
		print("── %s" % script.resource_path.get_file())
		suite.run(self)

	print("\n통과 %d / 실패 %d" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("  ✓ %s" % label)
	else:
		_failed += 1
		printerr("  ✗ %s" % label)


func eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		_passed += 1
		print("  ✓ %s" % label)
	else:
		_failed += 1
		printerr("  ✗ %s — 기대: %s / 실제: %s" % [label, expected, actual])
