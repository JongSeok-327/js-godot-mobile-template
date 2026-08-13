extends Node
## 게임 진행 데이터 저장/복원. `user://save.json`.
##
## 파일 구조는 항상 `{"version": N, "data": {...}}` — 최상위에 version을 두어야
## 나중에 스키마가 바뀌어도 기존 세이브를 마이그레이션할 수 있다.
##
## 설정(볼륨/언어)은 여기 넣지 않는다. Settings가 별도 파일로 관리하므로
## 세이브를 초기화해도 설정은 유지된다.

const SAVE_VERSION := 1
const DEFAULT_SAVE_PATH := "user://save.json"

## 테스트에서 실제 세이브를 건드리지 않도록 경로를 갈아끼울 수 있게 둔다.
var save_path := DEFAULT_SAVE_PATH

var _data: Dictionary = {}


func _ready() -> void:
	load_game()


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func get_value(key: String, default: Variant = null) -> Variant:
	return _data.get(key, default)


func set_value(key: String, value: Variant) -> void:
	_data[key] = value


## 메모리 상태를 디스크에 기록한다. set_value는 자동 저장하지 않는다.
func save_game() -> bool:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("[save] 쓰기 실패 (%s): %s" % [save_path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "data": _data}, "\t"))
	file.close()
	EventBus.save_completed.emit()
	return true


## 디스크에서 읽어 메모리를 채운다. 세이브가 없거나 깨졌으면 빈 상태로 시작한다.
func load_game() -> bool:
	_data = {}
	if not has_save():
		return false

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_error("[save] 읽기 실패 (%s): %s" % [save_path, FileAccess.get_open_error()])
		return false
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[save] 세이브 파싱 실패 — 빈 상태로 시작한다")
		return false

	var raw: Dictionary = parsed
	var version := int(raw.get("version", 0))
	if version > SAVE_VERSION:
		push_warning("[save] 더 최신 버전의 세이브(v%d > v%d) — 덮어쓰지 않도록 무시한다"
			% [version, SAVE_VERSION])
		return false

	_data = _migrate(version, raw) if version < SAVE_VERSION else raw.get("data", {})
	return true


## 세이브를 지우고 메모리도 비운다. 설정(Settings)은 건드리지 않는다.
func wipe() -> void:
	_data = {}
	if FileAccess.file_exists(save_path):
		var err := DirAccess.remove_absolute(save_path)
		if err != OK:
			push_error("[save] 삭제 실패 (%s): %d" % [save_path, err])


## 버전 마이그레이션 체인.
## 스키마를 바꿀 때: SAVE_VERSION을 +1 하고, 직전 버전 번호로 case를 추가한다.
## 각 case는 "v → v+1" 한 단계만 책임진다.
func _migrate(from_version: int, raw: Dictionary) -> Dictionary:
	var data: Dictionary = raw.get("data", {})
	var version := from_version
	while version < SAVE_VERSION:
		match version:
			0:
				# v0: version 필드가 없고 최상위가 곧 데이터였던 초기 포맷.
				if not raw.has("data"):
					data = raw.duplicate(true)
					data.erase("version")
			_:
				push_warning("[save] v%d 마이그레이션 규칙이 없다 — 건너뛴다" % version)
		version += 1
	return data
