extends RefCounted
## `locale/translations.csv` 가 **조용히 틀리는** 경우를 막는다.
##
## 번역이 비었거나 키가 CSV 에 없으면 Godot 은 에러 없이 키 문자열(`MENU_PLAY`)을 그대로
## 화면에 그린다. 플레이스홀더(`%d`, `{name}`)가 언어마다 다르면 그 언어에서만 포맷이
## 깨진다 — 개발자가 평소 쓰는 언어로는 절대 안 보인다.
## (Claude-Code-Game-Studios `/localize validate` 의 완전성·플레이스홀더 검사를 옮겼다.)

const CSV_PATH := "res://locale/translations.csv"
const SCENE_DIRS := ["res://scenes", "res://ui"]
const CODE_DIRS := ["res://autoload", "res://scenes", "res://scripts", "res://ui"]


func run(t: Node) -> void:
	var rows := _read_csv()
	var header: PackedStringArray = rows.pop_front()
	for locale in Settings.SUPPORTED_LOCALES:
		t.check(header.has(locale), "CSV 에 %s 열이 있다" % locale)

	var keys := {}
	var placeholder := RegEx.create_from_string("%(?:\\.\\d+)?[sdif]|\\{[a-z_]+\\}")
	var empty: Array[String] = []
	var mismatched: Array[String] = []
	for row in rows:
		keys[row[0]] = true
		var expected := _placeholders(placeholder, row[1])
		for i in range(1, header.size()):
			if i >= row.size() or row[i].strip_edges().is_empty():
				empty.append("%s/%s" % [row[0], header[i]])
			elif _placeholders(placeholder, row[i]) != expected:
				mismatched.append("%s/%s" % [row[0], header[i]])
	t.check(empty.is_empty(), "번역이 빈 칸이 없다 (%s)" % ", ".join(empty))
	t.check(mismatched.is_empty(), "언어마다 플레이스홀더가 같다 (%s)" % ", ".join(mismatched))

	var missing: Array[String] = []
	for key in _used_keys():
		if not keys.has(key):
			missing.append(key)
	t.check(missing.is_empty(), "씬·코드가 쓰는 번역 키가 CSV 에 있다 (없음: %s)" % ", ".join(missing))


func _read_csv() -> Array:
	var rows := []
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	while not file.eof_reached():
		var line := file.get_csv_line()
		if line.size() > 1 or (line.size() == 1 and not line[0].is_empty()):
			rows.append(line)
	return rows


func _placeholders(regex: RegEx, text: String) -> Array:
	var found := []
	for m in regex.search_all(text):
		found.append(m.get_string())
	found.sort()
	return found


## 씬의 `text = "KEY"` 와 코드의 `tr("KEY")`. 대문자·숫자·밑줄로만 된 글자만 키로 본다 —
## "English" 같은 고정 글자나 디버그 패널의 한국어 라벨은 번역 대상이 아니다.
func _used_keys() -> PackedStringArray:
	var keys := PackedStringArray()
	var scene_key := RegEx.create_from_string('\\btext = "([A-Z][A-Z0-9_]+)"')
	var code_key := RegEx.create_from_string('\\btr\\("([A-Z][A-Z0-9_]+)"\\)')
	for path in _files(SCENE_DIRS, ".tscn"):
		for m in scene_key.search_all(FileAccess.get_file_as_string(path)):
			keys.append(m.get_string(1))
	for path in _files(CODE_DIRS, ".gd"):
		for m in code_key.search_all(FileAccess.get_file_as_string(path)):
			keys.append(m.get_string(1))
	return keys


func _files(dirs: Array, ext: String) -> PackedStringArray:
	var files := PackedStringArray()
	for dir in dirs:
		for name in DirAccess.get_files_at(dir):
			if name.ends_with(ext):
				files.append(dir.path_join(name))
		for sub in DirAccess.get_directories_at(dir):
			files.append_array(_files([dir.path_join(sub)], ext))
	return files
