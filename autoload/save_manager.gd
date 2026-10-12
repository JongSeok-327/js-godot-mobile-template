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
## 더 최신 버전 앱이 쓴 세이브를 읽었다. 이 상태에서는 **저장하지 않는다** —
## 빈 상태로 시작한 뒤 첫 저장이 그 세이브를 덮어버린다 (다운그레이드).
var _foreign_save := false


func _ready() -> void:
	load_game()


func has_save() -> bool:
	return FileAccess.file_exists(save_path) or FileAccess.file_exists(_backup_path())


func get_value(key: String, default: Variant = null) -> Variant:
	return _data.get(key, default)


## 정수 값 읽기.
##
## **JSON은 int를 float로 되돌린다** — 120을 저장해도 다시 읽으면 120.0이다.
## `==` 비교는 통과해서 눈치채기 어렵지만 `typeof`, `%d` 포맷, Dictionary 키,
## 정수 나눗셈에서 조용히 어긋난다. 정수로 다뤄야 하는 값은 전부 이걸로 읽는다.
func get_int(key: String, default: int = 0) -> int:
	var value: Variant = _data.get(key, default)
	var value_type := typeof(value)
	if value_type == TYPE_INT or value_type == TYPE_FLOAT:
		return int(value)
	return default


func set_value(key: String, value: Variant) -> void:
	_data[key] = value


## 메모리 상태를 디스크에 기록한다. set_value는 자동 저장하지 않는다.
##
## **임시 파일에 다 쓴 뒤 이름을 바꿔 끼운다.** `FileAccess.open(WRITE)` 는 여는
## 순간 파일을 0바이트로 자르는데, 안드로이드는 앱이 백그라운드로 갈 때 —
## 정확히 저장이 도는 순간 — 프로세스를 죽일 수 있다. 그 사이에 죽으면 진행도가
## 전부 사라진다. 이름 바꾸기는 원자적이라 본 파일은
## 언제나 "직전 것" 아니면 "새 것" 이다.
##
## 바꾸기 전에 직전 정상본을 `.bak` 로 남긴다 — 저장 장치 오류처럼 원자성으로도
## 못 막는 손상에서 한 단계 전으로 돌아갈 수 있다.
func save_game() -> bool:
	if _foreign_save:
		push_warning("[save] 더 최신 버전의 세이브 위에는 저장하지 않는다")
		return false
	var tmp_path := save_path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("[save] 쓰기 실패 (%s): %s" % [tmp_path, FileAccess.get_open_error()])
		return false
	var written := file.store_string(JSON.stringify({"version": SAVE_VERSION, "data": _data}, "\t"))
	file.close()
	if not written:
		push_error("[save] 기록 실패 (%s) — 본 파일은 그대로 둔다" % tmp_path)
		return false

	if FileAccess.file_exists(save_path):
		DirAccess.copy_absolute(save_path, _backup_path())
	var err := DirAccess.rename_absolute(tmp_path, save_path)
	if err != OK:
		push_error("[save] 교체 실패 (%s): %d" % [save_path, err])
		return false
	EventBus.save_completed.emit()
	return true


## 디스크에서 읽어 메모리를 채운다. 세이브가 없거나 깨졌으면 빈 상태로 시작한다.
##
## 본 파일이 깨졌으면 **직전 정상본(`.bak`)으로 살아난다.** 거기까지 깨졌을 때만
## 빈 상태다.
func load_game() -> bool:
	_data = {}
	_foreign_save = false
	if not has_save():
		return false
	if _load_from(save_path):
		return true
	if _foreign_save:
		return false
	if FileAccess.file_exists(_backup_path()) and _load_from(_backup_path()):
		push_warning("[save] 본 세이브가 깨져 직전 백업으로 복구했다")
		return true
	push_error("[save] 세이브 파싱 실패 — 빈 상태로 시작한다")
	return false


func _load_from(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[save] 읽기 실패 (%s): %s" % [path, FileAccess.get_open_error()])
		return false
	var text := file.get_as_text()
	file.close()

	# JSON.parse_string 은 깨진 입력마다 ERROR 를 찍는다 — 백업으로 넘어갈 경로에서
	# 에러가 두 번 찍히지 않게 조용히 파싱한다.
	var json := JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return false

	var raw: Dictionary = json.data
	var version := int(raw.get("version", 0))
	if version > SAVE_VERSION:
		push_warning("[save] 더 최신 버전의 세이브(v%d > v%d) — 읽지도 덮어쓰지도 않는다"
			% [version, SAVE_VERSION])
		_foreign_save = true
		return false

	_data = _migrate(version, raw) if version < SAVE_VERSION else raw.get("data", {})
	return true


func _backup_path() -> String:
	return save_path + ".bak"


## 세이브를 지우고 메모리도 비운다. 설정(Settings)은 건드리지 않는다.
func wipe() -> void:
	_data = {}
	_foreign_save = false
	# 백업까지 지워야 한다 — 남겨 두면 다음 로드가 "본 파일이 없다" 를 "깨졌다" 로
	# 읽고 지운 데이터를 되살린다.
	for path in [save_path, save_path + ".tmp", _backup_path()]:
		if FileAccess.file_exists(path):
			var err := DirAccess.remove_absolute(path)
			if err != OK:
				push_error("[save] 삭제 실패 (%s): %d" % [path, err])


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
