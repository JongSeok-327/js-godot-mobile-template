extends RefCounted
## SceneManager 레지스트리 무결성 + 잘못된 요청 방어.
##
## 실제 씬 전환은 테스트하지 않는다 — 전환하면 테스트 러너 씬 자체가 날아간다.
## 대신 "레지스트리에 적힌 경로가 실재하는가"를 본다. 씬을 옮기거나 이름을
## 바꿨을 때 런타임에서야 터지는 걸 여기서 잡는다.


func run(t: Node) -> void:
	_test_registry_paths(t)
	_test_unknown_id(t)
	_test_reload_without_current(t)
	_test_overlay_setup(t)


func _test_registry_paths(t: Node) -> void:
	var scenes: Dictionary = SceneManager.SCENES
	t.check(not scenes.is_empty(), "SCENES 레지스트리가 비어있지 않음")

	for scene_id in scenes:
		var path: String = scenes[scene_id]
		t.check(ResourceLoader.exists(path), "'%s' 경로 존재: %s" % [scene_id, path])
		# macOS는 대소문자를 무시하지만 Android는 구분한다.
		t.eq(path, path.to_lower(), "'%s' 경로가 소문자" % scene_id)


func _test_unknown_id(t: Node) -> void:
	var before := SceneManager.current_scene_id
	SceneManager.change_scene("존재하지_않는_씬")
	t.eq(SceneManager.current_scene_id, before, "등록되지 않은 ID는 전환하지 않음")
	t.check(not SceneManager.is_changing(), "실패한 요청이 전환 상태를 잠그지 않음")


func _test_reload_without_current(t: Node) -> void:
	var before := SceneManager.current_scene_id
	if before.is_empty():
		SceneManager.reload_current()
		t.check(not SceneManager.is_changing(), "현재 씬 ID가 없으면 reload는 무시")
	else:
		t.check(true, "reload 사전조건 없음 (현재 씬 ID 존재)")


func _test_overlay_setup(t: Node) -> void:
	t.eq(SceneManager.layer, 100, "페이드 레이어가 게임 UI 위(100)")
	t.eq(
		SceneManager.process_mode,
		Node.PROCESS_MODE_ALWAYS,
		"일시정지 중에도 전환 가능"
	)
	var fade := SceneManager.get_node_or_null("Fade") as ColorRect
	t.check(fade != null, "Fade ColorRect 존재")
	if fade != null:
		t.check(not fade.visible, "평소에는 숨겨져 입력을 막지 않음")
