extends RefCounted
## 스크롤 목록의 항목이 **끌기를 삼키지 않는가**.
##
## `ScrollContainer` 는 자식이 넘겨준 입력으로만 끌어서 스크롤한다. 항목의 바탕
## (`PanelContainer` 등)이 기본값 `MOUSE_FILTER_STOP` 이면 카드 위를 끌어도
## 아무 일도 안 일어난다 — 에러도 로그도 없다 (kongkong iPhone 스킨 화면에서 밟았다).
## 버튼은 예외다 — 눌러야 하므로 STOP 이 맞다.
##
## 씬 파일 안의 ScrollContainer 는 자동으로 훑는다. **런타임에 목록에 붙이는 항목 씬**
## (카드·행 등)은 정적으로 안 보이므로 ITEMS 에 등록한다.

const SCENE_DIRS := ["res://scenes", "res://ui", "res://debug"]
const ITEMS := {}


func run(t: Node) -> void:
	for path in _scene_files(SCENE_DIRS):
		var root := (load(path) as PackedScene).instantiate()
		for scroll in root.find_children("*", "ScrollContainer", true, false):
			var blockers := _blockers(scroll.get_children())
			t.check(blockers.is_empty(), "%s 의 %s 가 끌기를 삼키지 않는다 (STOP: %s)"
				% [path.get_file(), scroll.name, ", ".join(blockers)])
		root.free()

	for label in ITEMS:
		var item: Control = (load(ITEMS[label]) as PackedScene).instantiate()
		var blockers := _blockers([item])
		t.check(blockers.is_empty(), "%s 가 끌기를 삼키지 않는다 (STOP: %s)" % [label, ", ".join(blockers)])
		item.free()


func _blockers(roots: Array) -> PackedStringArray:
	var found := PackedStringArray()
	for root in roots:
		for node in [root] + root.find_children("*", "Control", true, false):
			var c := node as Control
			if c == null or c is BaseButton:
				continue
			if c.mouse_filter == Control.MOUSE_FILTER_STOP:
				found.append(String(c.name))
	return found


func _scene_files(dirs: Array) -> PackedStringArray:
	var files := PackedStringArray()
	for dir in dirs:
		for name in DirAccess.get_files_at(dir):
			if name.ends_with(".tscn"):
				files.append(dir.path_join(name))
		for sub in DirAccess.get_directories_at(dir):
			files.append_array(_scene_files([dir.path_join(sub)]))
	return files
