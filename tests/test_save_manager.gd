extends RefCounted
## SaveManager 저장/복원 + 버전 마이그레이션.
## 실제 세이브를 건드리지 않도록 임시 경로에 인스턴스를 새로 만들어 테스트한다.

const SaveManagerScript := preload("res://autoload/save_manager.gd")
const TEST_PATH := "user://test_save.json"

var _instances: Array[Node] = []


func run(t: Node) -> void:
	_cleanup()

	_test_roundtrip(t)
	_test_defaults(t)
	_test_wipe(t)
	_test_migrate_v0(t)
	_test_corrupt(t)
	_test_future_version(t)
	_test_save_completed_signal(t)

	_cleanup()
	# Node는 RefCounted가 아니라서 직접 해제하지 않으면 종료 시 누수로 잡힌다.
	for instance in _instances:
		instance.free()
	_instances.clear()


func _make() -> Node:
	# _ready()를 태우지 않으려고 트리에 넣지 않는다 (load 시점을 직접 통제).
	var sm: Node = SaveManagerScript.new()
	sm.save_path = TEST_PATH
	_instances.append(sm)
	return sm


func _cleanup() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)


func _write_raw(text: String) -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _test_roundtrip(t: Node) -> void:
	var sm := _make()
	t.check(not sm.has_save(), "세이브 없을 때 has_save는 false")
	sm.set_value("coins", 120)
	sm.set_value("stage", "forest_02")
	t.check(sm.save_game(), "save_game 성공")
	t.check(sm.has_save(), "저장 후 has_save는 true")

	var loaded := _make()
	t.check(loaded.load_game(), "load_game 성공")
	t.eq(loaded.get_value("coins"), 120, "int 값 복원")
	t.eq(loaded.get_value("stage"), "forest_02", "String 값 복원")
	_cleanup()


func _test_defaults(t: Node) -> void:
	var sm := _make()
	t.eq(sm.get_value("missing", 42), 42, "없는 키는 기본값 반환")
	t.eq(sm.get_value("missing"), null, "기본값 미지정 시 null")


func _test_wipe(t: Node) -> void:
	var sm := _make()
	sm.set_value("coins", 7)
	sm.save_game()
	sm.wipe()
	t.check(not sm.has_save(), "wipe 후 파일 삭제")
	t.eq(sm.get_value("coins"), null, "wipe 후 메모리도 비움")


func _test_migrate_v0(t: Node) -> void:
	# v0: version 필드 없이 최상위가 곧 데이터였던 초기 포맷.
	_write_raw('{"coins": 55, "stage": "cave_01"}')
	var sm := _make()
	t.check(sm.load_game(), "v0 세이브 로드 성공")
	t.eq(sm.get_value("coins"), 55, "v0 → v1 마이그레이션으로 값 보존")
	t.eq(sm.get_value("stage"), "cave_01", "v0 마이그레이션 후 다른 키도 보존")

	# 마이그레이션 결과를 다시 저장하면 현재 버전으로 기록되어야 한다.
	sm.save_game()
	var reloaded := _make()
	reloaded.load_game()
	t.eq(reloaded.get_value("coins"), 55, "마이그레이션 결과 재저장 후에도 유지")
	_cleanup()


func _test_corrupt(t: Node) -> void:
	_write_raw("{ 이건 JSON이 아니다 ")
	var sm := _make()
	t.check(not sm.load_game(), "깨진 세이브는 load_game false")
	t.eq(sm.get_value("coins"), null, "깨진 세이브 후 빈 상태로 시작")
	_cleanup()


func _test_future_version(t: Node) -> void:
	var future := SaveManagerScript.SAVE_VERSION + 1
	_write_raw('{"version": %d, "data": {"coins": 999}}' % future)
	var sm := _make()
	t.check(not sm.load_game(), "미래 버전 세이브는 로드 거부")
	t.eq(sm.get_value("coins"), null, "미래 버전 데이터는 읽지 않음")
	_cleanup()


func _test_save_completed_signal(t: Node) -> void:
	var fired := [false]
	var handler := func() -> void: fired[0] = true
	EventBus.save_completed.connect(handler)
	var sm := _make()
	sm.set_value("x", 1)
	sm.save_game()
	EventBus.save_completed.disconnect(handler)
	t.check(fired[0], "저장 시 EventBus.save_completed 발신")
	_cleanup()
