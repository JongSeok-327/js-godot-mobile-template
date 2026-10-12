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
	_test_write_is_atomic(t)
	_test_recovers_from_backup(t)
	_test_future_version_not_overwritten(t)
	_test_json_returns_float(t)
	_test_get_int(t)

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
	for path in [TEST_PATH, TEST_PATH + ".tmp", TEST_PATH + ".bak"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


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


## 쓰는 도중에 죽어도 **본 파일은 온전해야 한다.**
##
## `FileAccess.open(WRITE)` 는 여는 순간 파일을 0바이트로 자른다. 안드로이드는
## 앱이 백그라운드로 갈 때 — 정확히 저장이 도는 순간 — 프로세스를 죽일 수 있어서,
## 그 사이에 죽으면 진행도가 전부 날아간다.
## 그래서 임시 파일에 다 쓴 뒤 이름을 바꿔 끼운다. 여기서는 "쓰다 만 임시 파일" 을
## 남겨 두고 본 파일이 그대로인지 본다.
func _test_write_is_atomic(t: Node) -> void:
	var sm := _make()
	sm.set_value("coins", 300)
	sm.save_game()
	t.check(not FileAccess.file_exists(TEST_PATH + ".tmp"), "저장이 끝나면 임시 파일이 남지 않는다")

	# 다음 저장 도중에 죽었다 — 임시 파일은 반쯤 쓰였고 본 파일은 손대지 않았다.
	var tmp := FileAccess.open(TEST_PATH + ".tmp", FileAccess.WRITE)
	tmp.store_string('{"version": 1, "data": {"coi')
	tmp.close()

	var loaded := _make()
	t.check(loaded.load_game(), "쓰다 만 임시 파일이 있어도 본 파일을 읽는다")
	t.eq(loaded.get_int("coins"), 300, "직전에 저장한 값이 그대로다")
	_cleanup()


## 본 파일이 깨졌으면 **직전 정상본으로 살아난다.**
func _test_recovers_from_backup(t: Node) -> void:
	var sm := _make()
	sm.set_value("coins", 100)
	sm.save_game()
	sm.set_value("coins", 200)
	sm.save_game()          # 이 시점에 .bak 에는 100 이 남는다
	_write_raw("")          # 본 파일이 어떤 이유로든 비었다

	var loaded := _make()
	t.check(loaded.load_game(), "본 파일이 깨지면 백업에서 읽는다")
	t.eq(loaded.get_int("coins"), 100, "백업은 직전 정상본이다")
	_cleanup()


## 새 버전 앱의 세이브를 옛 앱이 읽으면 **덮어쓰면 안 된다** (다운그레이드).
## 로드를 거부하는 것만으로는 부족했다 — 빈 상태로 시작한 뒤 첫 저장이
## 새 버전 세이브를 빈 데이터로 덮었다.
func _test_future_version_not_overwritten(t: Node) -> void:
	var future := SaveManagerScript.SAVE_VERSION + 1
	var original := '{"version": %d, "data": {"coins": 999}}' % future
	_write_raw(original)
	var sm := _make()
	sm.load_game()
	sm.set_value("coins", 1)
	t.check(not sm.save_game(), "미래 버전 세이브 위에는 저장을 거부한다")
	t.eq(FileAccess.get_file_as_string(TEST_PATH), original, "미래 버전 세이브가 그대로 남는다")
	_cleanup()


## 문제 자체를 못 박아 둔다 — 이게 false가 되는 날이 오면 get_int도 필요 없다.
func _test_json_returns_float(t: Node) -> void:
	var sm := _make()
	sm.set_value("coins", 120)
	t.eq(typeof(sm.get_value("coins")), TYPE_INT, "저장 전 메모리 값은 int")
	sm.save_game()

	var loaded := _make()
	loaded.load_game()
	t.eq(typeof(loaded.get_value("coins")), TYPE_FLOAT, "JSON 왕복 후 get_value 는 float")
	t.check(loaded.get_value("coins") == 120, "값 자체는 같아서 == 비교로는 못 잡는다")
	t.eq(typeof(loaded.get_int("coins")), TYPE_INT, "get_int 는 int 로 돌려준다")
	t.eq(loaded.get_int("coins"), 120, "값도 보존된다")
	_cleanup()


func _test_get_int(t: Node) -> void:
	var sm := _make()
	t.eq(sm.get_int("missing"), 0, "없는 키는 0")
	t.eq(sm.get_int("missing", 7), 7, "없는 키는 지정한 기본값")
	sm.set_value("nick", "kong")
	t.eq(sm.get_int("nick", -1), -1, "정수가 아닌 값은 기본값으로 떨어진다")
	sm.set_value("ratio", 3.9)
	t.eq(sm.get_int("ratio"), 3, "float 는 버림")
