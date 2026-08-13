extends CanvasLayer
## 설정 오버레이. 메인 메뉴와 일시정지 메뉴 양쪽에서 그대로 재사용한다.
##
## 값을 직접 들고 있지 않는다 — 읽기도 쓰기도 Settings를 통한다.
## 일시정지 메뉴(layer 50) 위에 떠야 하므로 layer 60.

signal closed

## 슬라이더 노드 이름 → Settings 볼륨 키
const SLIDERS := {
	"MasterSlider": "master",
	"MusicSlider": "music",
	"SfxSlider": "sfx",
}

## 언어 버튼 노드 이름 → locale
const LANGUAGE_BUTTONS := {
	"LangEn": "en",
	"LangKo": "ko",
	"LangJa": "ja",
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for node_name in SLIDERS:
		var key: String = SLIDERS[node_name]
		var slider := get_node("%%%s" % node_name) as HSlider
		slider.value = Settings.get_volume(key)
		slider.value_changed.connect(
			func(value: float) -> void: Settings.set_volume(key, value)
		)

	for node_name in LANGUAGE_BUTTONS:
		var locale: String = LANGUAGE_BUTTONS[node_name]
		var button := get_node("%%%s" % node_name) as Button
		button.pressed.connect(func() -> void: Settings.set_locale(locale))

	%CloseButton.pressed.connect(closed.emit)
	EventBus.language_changed.connect(_on_language_changed)
	_update_language_buttons()
	%CloseButton.grab_focus()


func _notification(what: int) -> void:
	# 설정이 열려 있으면 뒤로가기는 설정만 닫는다.
	# (아래 씬들은 _settings_menu가 살아있는 동안 뒤로가기를 무시한다.)
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		closed.emit()


func _on_language_changed(_locale: String) -> void:
	_update_language_buttons()


## 현재 언어 버튼은 비활성으로 표시한다.
func _update_language_buttons() -> void:
	var current := Settings.get_locale()
	for node_name in LANGUAGE_BUTTONS:
		var button := get_node("%%%s" % node_name) as Button
		button.disabled = LANGUAGE_BUTTONS[node_name] == current
