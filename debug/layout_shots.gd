extends Node
## 지원 화면비·세이프 에어리어별로 `SceneManager.SCENES` 의 화면을 찍는다 (데스크톱 실행).
## iOS 시뮬레이터는 Godot 4.7.1 템플릿이 x86_64 전용이라 Apple Silicon 에서 못 쓴다 — 그 대용이다.
##
##   "$GODOT" --path . res://debug/layout_shots.tscn -- --out=/절대/경로
##
## 화면 크기는 화면비만 의미가 있다 (stretch=canvas_items/expand, 폭 720 고정).
## 세이프 에어리어는 데스크톱에서 오지 않으므로 `SafeAreaContainer` 여백을 직접 넣는다.
## 진짜 세이브를 건드리지 않게 별도 세이브 경로를 쓴다 — 화면에 보일 샘플 데이터는
## `_prepare_save()` 에 채운다.

## 이름, 논리 해상도(pt/dp), 위·아래 세이프 에어리어(pt/dp). 상태 표시줄은 숨김 기준.
const DEVICES := [
	["iphone_se_4.7in", Vector2i(375, 667), 0, 0],
	["iphone_8plus_5.5in", Vector2i(414, 736), 0, 0],
	["iphone_x_11pro_mini", Vector2i(375, 812), 50, 34],
	["iphone_12_13_14_16e", Vector2i(390, 844), 47, 34],
	["iphone_14pro_15_16", Vector2i(393, 852), 59, 34],
	["iphone_16pro_17", Vector2i(402, 874), 62, 34],
	["iphone_16_17promax", Vector2i(440, 956), 62, 34],
	# Android 인셋은 기기마다 다르다 — 펀치홀 상단 + 제스처 바 하단의 대략값.
	["android_20x9", Vector2i(360, 800), 32, 24],
	["android_pixel6", Vector2i(412, 915), 32, 24],
]
const SKIP_SCENES := ["boot"]
const SAVE_PATH := "user://layout_shots.json"
## 창 크기 = pt × 이 값. 맥 화면보다 커지면 OS 가 줄여 화면비가 틀어진다.
const WINDOW_SCALE := 0.75
const SAFE_AREA_SCRIPT := preload("res://ui/components/safe_area_container.gd")

var _out := ""
var _original_save := ""


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	if _out == "":
		push_error("--out=<디렉터리> 가 필요하다")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	# 릴리스에 없는 것은 숨긴다 — 디버그 버튼.
	if DebugTools._panel != null:
		DebugTools._panel.visible = false
	_original_save = SaveManager.save_path
	SaveManager.save_path = SAVE_PATH
	SaveManager.wipe()
	_prepare_save()
	await _run()


## 화면에 보일 샘플 데이터 (코인·최고점·닉네임 등). 빈 화면만 찍으면 긴 숫자·이름에서
## 넘치는 레이아웃을 못 본다. 게임을 얹으면 여기를 채운다.
func _prepare_save() -> void:
	pass


func _run() -> void:
	for device in DEVICES:
		var points: Vector2i = device[1]
		DisplayServer.window_set_size(Vector2i(Vector2(points) * WINDOW_SCALE))
		await _frames(5)
		var actual := DisplayServer.window_get_size()
		var want := float(points.y) / points.x
		var got := float(actual.y) / actual.x
		if absf(want - got) > 0.01:
			push_error("%s: 창 화면비가 틀어졌다 (%s)" % [device[0], actual])
		var vp_per_pt := get_viewport().get_visible_rect().size.x / points.x
		var insets := Vector2i(roundi(device[2] * vp_per_pt), roundi(device[3] * vp_per_pt))
		for id in SceneManager.SCENES:
			if id not in SKIP_SCENES:
				await _shoot(device[0], id, insets)
	SaveManager.wipe()
	SaveManager.save_path = _original_save
	print("[layout_shots] 끝 — ", _out)
	get_tree().quit()


func _shoot(device: String, id: String, insets: Vector2i) -> void:
	var node: Node = load(SceneManager.SCENES[id]).instantiate()
	add_child(node)
	_apply_insets(node, insets)
	# iOS 는 종료 버튼을 숨긴다 (main_menu.gd). 데스크톱에서는 보여서 하단 줄이 넓어진다.
	var quit := node.get_node_or_null("%QuitButton")
	if quit != null:
		quit.visible = false
	await _frames(20)
	var image := get_viewport().get_texture().get_image()
	image.save_png("%s/%s__%s.png" % [_out, device, id])
	get_tree().paused = false
	node.free()
	await _frames(2)


## 데스크톱에는 세이프 에어리어가 없다 — 기기 여백을 SafeAreaContainer 에 직접 더한다.
func _apply_insets(root: Node, insets: Vector2i) -> void:
	for node in root.find_children("*", "MarginContainer", true, false):
		if node.get_script() == SAFE_AREA_SCRIPT:
			var base: int = node.extra_margin
			node.add_theme_constant_override("margin_top", base + insets.x)
			node.add_theme_constant_override("margin_bottom", base + insets.y)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
