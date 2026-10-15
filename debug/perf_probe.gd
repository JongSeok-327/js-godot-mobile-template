extends Node
## 디버그 빌드 전용 — 프레임 끊김 추적(kongslash 첫 판 렉에서 가져옴). 40ms 넘는 프레임을 그 직전 일과 함께 적어
## user://perf_log.txt 에 덧붙인다. 기기에서 `tools/device.sh ios-pull Documents/perf_log.txt x.txt` 로 가져온다.
## 게임 씬이 디버그 빌드에서만 `load()` 로 붙이고(릴리스는 debug/* 제외), 의심 가는 일 직전에 `mark("이름")` 을 부른다.

const SLOW_MS := 40.0
const LOG_PATH := "user://perf_log.txt"

var _lines: PackedStringArray = []
var _recent: PackedStringArray = []
var _start_ms := Time.get_ticks_msec()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_lines.append("=== 판 시작 (앱 켜고 %.1fs)" % (Time.get_ticks_msec() / 1000.0))


func mark(what: String) -> void:
	_recent.append("%s@%d" % [what, Time.get_ticks_msec() - _start_ms])
	if _recent.size() > 6:
		_recent.remove_at(0)


func _process(delta: float) -> void:
	var ms := delta * 1000.0
	if ms > SLOW_MS:
		_lines.append("%6dms 프레임 %.0fms  직전: %s" % [Time.get_ticks_msec() - _start_ms, ms, ", ".join(_recent)])


func _exit_tree() -> void:
	var f := FileAccess.open(LOG_PATH, FileAccess.READ_WRITE if FileAccess.file_exists(LOG_PATH) else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_string("\n".join(_lines) + "\n")
