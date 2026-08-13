extends RefCounted
## 버튼 클릭음 자동 연결 + "슬라이더 → SFX 버스" 경로.
##
## 소리가 실제로 났는지는 단언하지 않는다 — 헤드리스는 더미 오디오 드라이버라
## 재생 상태를 믿을 수 없다(test_audio_manager.gd와 같은 이유). 대신 클릭음이
## **SFX 버스 재생기에 실렸는지**를 본다. 거기까지 가면 볼륨은 버스가 책임진다.

const CLICK_PATH := "res://assets/audio/sfx/ui_click.ogg"
const SETTINGS_MENU_PATH := "res://scenes/overlays/settings_menu.tscn"


func run(t: Node) -> void:
	var click := load(CLICK_PATH) as AudioStream
	t.check(click != null, "클릭음 리소스 로드")
	if click == null:
		return

	_test_auto_connect(t, click)
	await _quiet(t)
	_test_silent_meta(t, click)
	await _quiet(t)
	_test_slider_drives_sfx_bus(t)


func _test_auto_connect(t: Node, click: AudioStream) -> void:
	_clear_sfx()
	var button := Button.new()
	t.get_tree().root.add_child(button)

	t.check(
		not button.pressed.get_connections().is_empty(),
		"트리에 들어온 버튼에 클릭음이 자동으로 연결된다"
	)

	button.pressed.emit()
	t.eq(_bus_playing(click), &"SFX", "클릭음이 SFX 버스 재생기에 실린다")

	t.get_tree().root.remove_child(button)
	button.free()


func _test_silent_meta(t: Node, click: AudioStream) -> void:
	_clear_sfx()
	var button := Button.new()
	button.set_meta("silent", true)
	t.get_tree().root.add_child(button)

	button.pressed.emit()
	t.eq(_bus_playing(click), &"", "silent 메타가 붙은 버튼은 소리를 내지 않는다")

	t.get_tree().root.remove_child(button)
	button.free()


## 설정 오버레이의 SFX 슬라이더가 실제 버스 볼륨까지 닿는지.
func _test_slider_drives_sfx_bus(t: Node) -> void:
	var saved := Settings.get_volume("sfx")
	var index := AudioServer.get_bus_index("SFX")

	var menu: CanvasLayer = load(SETTINGS_MENU_PATH).instantiate()
	t.get_tree().root.add_child(menu)
	var slider := menu.get_node("%SfxSlider") as HSlider
	slider.value = 0.25

	t.eq(Settings.get_volume("sfx"), 0.25, "슬라이더를 움직이면 Settings에 반영된다")
	t.check(
		is_equal_approx(AudioServer.get_bus_volume_db(index), linear_to_db(0.25)),
		"SFX 슬라이더가 SFX 버스 볼륨까지 움직인다"
	)

	t.get_tree().root.remove_child(menu)
	menu.free()
	Settings.set_volume("sfx", saved)


## click 스트림을 물고 있는 재생기의 버스. 없으면 빈 문자열.
func _bus_playing(click: AudioStream) -> StringName:
	for child in AudioManager.get_children():
		var player := child as AudioStreamPlayer
		if player != null and player.stream == click:
			return player.bus
	return &""


## 재생을 멈추고 스트림 참조를 놓은 뒤, 오디오 서버가 재생 객체를 반납할
## 시간을 준다. 프레임을 안 넘기면 종료 시점에 ogg 재생 객체가 누수로 잡힌다.
func _quiet(t: Node) -> void:
	_clear_sfx()
	await t.get_tree().process_frame
	await t.get_tree().process_frame


## 앞 케이스가 남긴 스트림이 다음 단언을 오염시키지 않게 비운다.
func _clear_sfx() -> void:
	AudioManager.stop_all_sfx()
	for child in AudioManager.get_children():
		var player := child as AudioStreamPlayer
		if player != null:
			player.stream = null
