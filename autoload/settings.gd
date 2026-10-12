extends Node
## 사용자 설정(볼륨/언어). `user://settings.cfg`.
##
## 세이브 데이터(SaveManager)와 **파일을 분리한다** — 진행 상황을 초기화해도
## 볼륨·언어 설정은 남아야 하기 때문. 설정은 바뀔 때마다 즉시 저장한다.

const DEFAULT_CONFIG_PATH := "user://settings.cfg"
const SECTION_AUDIO := "audio"
const SECTION_LOCALE := "locale"
const SECTION_HAPTICS := "haptics"

const DEFAULT_LOCALE := "en"
const SUPPORTED_LOCALES: Array[String] = ["en", "ko", "ja"]

## 볼륨 키 → 오디오 버스 이름. 버스 레이아웃은 assets/audio/default_bus_layout.tres.
const VOLUME_BUSES := {
	"master": "Master",
	"music": "Music",
	"sfx": "SFX",
}

## 테스트에서 실제 설정을 건드리지 않도록 경로를 갈아끼울 수 있게 둔다.
var config_path := DEFAULT_CONFIG_PATH

var _volumes := {"master": 1.0, "music": 0.8, "sfx": 1.0}
var _locale := DEFAULT_LOCALE
## 진동. **기본 켜짐** — 게임필의 일부라 처음부터 느껴져야 하고,
## 거슬리는 사람만 끄면 된다.
var _haptics := true


func _ready() -> void:
	load_settings()
	apply_all()


func get_volume(key: String) -> float:
	return _volumes.get(key, 1.0)


## value는 0.0~1.0 선형 볼륨. 즉시 AudioServer에 반영하고 저장한다.
func set_volume(key: String, value: float) -> void:
	if not VOLUME_BUSES.has(key):
		push_error("[settings] 알 수 없는 볼륨 키: %s" % key)
		return
	_volumes[key] = clampf(value, 0.0, 1.0)
	_apply_volume(key)
	save_settings()


func haptics_enabled() -> bool:
	return _haptics


func set_haptics(enabled: bool) -> void:
	if _haptics == enabled:
		return
	_haptics = enabled
	save_settings()


## 짧은 진동. 설정이 꺼져 있거나 진동이 없는 플랫폼(에디터·데스크톱)에서는
## 아무 일도 하지 않는다.
##
## `Input.vibrate_handheld` 는 Android/iOS 에서만 동작하고 다른 플랫폼에서는
## 조용히 무시된다. 그래도 설정 검사는 여기서 한 번에 해두는 편이 낫다 —
## 호출하는 쪽마다 조건을 적으면 언젠가 한 곳이 빠진다.
func vibrate(duration_ms := 40, amplitude := -1.0) -> void:
	if not _haptics:
		return
	Input.vibrate_handheld(duration_ms, amplitude)


func get_locale() -> String:
	return _locale


func set_locale(locale: String) -> void:
	if locale not in SUPPORTED_LOCALES:
		push_error("[settings] 지원하지 않는 locale: %s" % locale)
		return
	if locale == _locale:
		return
	_locale = locale
	TranslationServer.set_locale(locale)
	save_settings()
	EventBus.language_changed.emit(locale)


## 메모리 상태를 AudioServer/TranslationServer에 밀어넣는다.
func apply_all() -> void:
	for key in VOLUME_BUSES:
		_apply_volume(key)
	TranslationServer.set_locale(_locale)


## 파일이 없거나 깨졌으면 기본값을 유지한 채 false를 반환한다.
func load_settings() -> bool:
	var config := ConfigFile.new()
	if config.load(config_path) != OK:
		return false

	for key in VOLUME_BUSES:
		var raw: float = float(config.get_value(SECTION_AUDIO, key, _volumes[key]))
		_volumes[key] = clampf(raw, 0.0, 1.0)

	var loaded_locale := str(config.get_value(SECTION_LOCALE, "current", _locale))
	if loaded_locale in SUPPORTED_LOCALES:
		_locale = loaded_locale

	_haptics = bool(config.get_value(SECTION_HAPTICS, "enabled", _haptics))
	return true


func save_settings() -> bool:
	var config := ConfigFile.new()
	for key in VOLUME_BUSES:
		config.set_value(SECTION_AUDIO, key, _volumes[key])
	config.set_value(SECTION_LOCALE, "current", _locale)
	config.set_value(SECTION_HAPTICS, "enabled", _haptics)

	var err := config.save(config_path)
	if err != OK:
		push_error("[settings] 저장 실패 (%s): %d" % [config_path, err])
		return false
	return true


func _apply_volume(key: String) -> void:
	var index := AudioServer.get_bus_index(VOLUME_BUSES[key])
	if index < 0:
		return  # 버스 레이아웃에 없는 버스는 조용히 건너뛴다.
	var value: float = _volumes[key]
	AudioServer.set_bus_mute(index, is_zero_approx(value))
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))
