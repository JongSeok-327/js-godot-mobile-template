extends RefCounted
## Settings 영속화 + 클램핑 + locale 검증.
## AudioServer/TranslationServer는 전역이라 테스트 후 원래 값으로 되돌린다.

const SettingsScript := preload("res://autoload/settings.gd")
const TEST_PATH := "user://test_settings.cfg"

var _instances: Array[Node] = []


func run(t: Node) -> void:
	var saved_locale := TranslationServer.get_locale()
	var master_index := AudioServer.get_bus_index("Master")
	var saved_master_db := AudioServer.get_bus_volume_db(master_index)
	var saved_master_mute := AudioServer.is_bus_mute(master_index)

	_cleanup()
	_test_defaults(t)
	_test_roundtrip(t)
	_test_clamp(t)
	_test_unknown_volume_key(t)
	_test_locale_validation(t)
	_test_locale_signal(t)
	_test_applies_to_audio_server(t, master_index)
	_cleanup()

	AudioServer.set_bus_volume_db(master_index, saved_master_db)
	AudioServer.set_bus_mute(master_index, saved_master_mute)
	TranslationServer.set_locale(saved_locale)

	for instance in _instances:
		instance.free()
	_instances.clear()


func _make() -> Node:
	var settings: Node = SettingsScript.new()
	settings.config_path = TEST_PATH
	_instances.append(settings)
	return settings


func _cleanup() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)


func _test_defaults(t: Node) -> void:
	var settings := _make()
	t.check(not settings.load_settings(), "설정 파일 없으면 load_settings false")
	t.eq(settings.get_volume("master"), 1.0, "master 기본 볼륨 1.0")
	t.eq(settings.get_locale(), SettingsScript.DEFAULT_LOCALE, "기본 locale은 en")


func _test_roundtrip(t: Node) -> void:
	var settings := _make()
	settings.set_volume("music", 0.35)
	settings.set_volume("sfx", 0.5)
	settings.set_locale("ko")

	var loaded := _make()
	t.check(loaded.load_settings(), "load_settings 성공")
	t.eq(loaded.get_volume("music"), 0.35, "music 볼륨 복원")
	t.eq(loaded.get_volume("sfx"), 0.5, "sfx 볼륨 복원")
	t.eq(loaded.get_locale(), "ko", "locale 복원")
	_cleanup()


func _test_clamp(t: Node) -> void:
	var settings := _make()
	settings.set_volume("master", 3.7)
	t.eq(settings.get_volume("master"), 1.0, "1.0 초과 볼륨은 1.0으로 클램프")
	settings.set_volume("master", -2.0)
	t.eq(settings.get_volume("master"), 0.0, "음수 볼륨은 0.0으로 클램프")
	_cleanup()


func _test_unknown_volume_key(t: Node) -> void:
	var settings := _make()
	settings.set_volume("voice", 0.5)
	t.eq(settings.get_volume("voice"), 1.0, "알 수 없는 볼륨 키는 무시")
	_cleanup()


func _test_locale_validation(t: Node) -> void:
	var settings := _make()
	settings.set_locale("fr")
	t.eq(settings.get_locale(), "en", "지원하지 않는 locale은 거부")
	settings.set_locale("ja")
	t.eq(settings.get_locale(), "ja", "지원 locale은 반영")
	_cleanup()


func _test_locale_signal(t: Node) -> void:
	var received: Array[String] = []
	var handler := func(locale: String) -> void: received.append(locale)
	EventBus.language_changed.connect(handler)

	var settings := _make()
	settings.set_locale("ko")
	settings.set_locale("ko")  # 같은 값이면 다시 쏘지 않아야 한다

	EventBus.language_changed.disconnect(handler)
	t.eq(received, ["ko"] as Array[String], "언어 변경 시 1회만 language_changed 발신")
	_cleanup()


func _test_applies_to_audio_server(t: Node, master_index: int) -> void:
	var settings := _make()
	settings.set_volume("master", 0.5)
	t.check(
		is_equal_approx(AudioServer.get_bus_volume_db(master_index), linear_to_db(0.5)),
		"볼륨이 AudioServer에 즉시 반영"
	)
	settings.set_volume("master", 0.0)
	t.check(AudioServer.is_bus_mute(master_index), "볼륨 0이면 버스 mute")
	_cleanup()
