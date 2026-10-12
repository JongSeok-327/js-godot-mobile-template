extends SceneTree
## 프로젝트의 모든 GDScript 를 게임이 로드하는 방식 그대로 파싱해 본다.
##
##   "$GODOT" --headless --path . -s res://tools/parse_check.gd
##
## 스모크(`--quit`·씬별 스모크)는 autoload 와 씬이 **참조하는** 스크립트만 컴파일한다.
## 어디서도 아직 안 붙인 스크립트·`load()` 로만 가져오는 스크립트(debug/, 애드온 구현)의
## 파스 에러는 그 경로를 실제로 탈 때까지 숨는다 — 이게 그걸 잡는다.
##
## `--check-only` 를 쓰지 않는 이유: autoload 가 등록되기 전에 컴파일해서 `EventBus` 같은
## 전역 이름을 쓰는 정상 코드도 "Identifier not found" 로 실패한다. `_initialize()` 는
## autoload 등록 뒤에 돈다. (출처: Claude-Code-Game-Studios `godot-parse-check.gd`)
##
## 출력: 실패한 스크립트마다 `PARSE FAIL: <경로>`, 마지막 줄 `parse_check: N개 중 실패 M`.
## 종료 코드는 실패가 있으면 1.

## 엔진이 관리하거나 우리가 고치지 않는 곳.
const SKIP_DIRS := ["res://.godot", "res://addons", "res://build", "res://.claude"]


func _initialize() -> void:
	var paths := _scripts("res://")
	var failed := 0
	for path in paths:
		var script := load(path) as Script
		if script == null or not script.can_instantiate():
			printerr("PARSE FAIL: ", path)
			failed += 1
	print("parse_check: %d개 중 실패 %d" % [paths.size(), failed])
	quit(1 if failed > 0 else 0)


func _scripts(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for name in DirAccess.get_files_at(dir):
		if name.ends_with(".gd"):
			found.append(dir.path_join(name))
	for sub in DirAccess.get_directories_at(dir):
		var path := dir.path_join(sub)
		if path not in SKIP_DIRS:
			found.append_array(_scripts(path))
	return found
