extends CanvasLayer
## 개발용 디버그 패널. DebugTools가 디버그 빌드에서만 인스턴스화한다.
##
## 이 씬을 참조하는 곳은 DebugTools의 load() 한 줄뿐이다 — 어떤 씬도
## 여기를 preload하지 않아야 릴리스 preset에서 debug/*를 뺄 수 있다.
##
## 씬 위에 항상 떠 있어야 하므로 layer는 SceneManager(100)보다 높은 200이고,
## 일시정지 중에도 눌려야 하므로 PROCESS_MODE_ALWAYS다.

## 통계 갱신 주기(초). 매 프레임 갱신하면 숫자가 읽히지 않는다.
const STATS_INTERVAL := 0.5
const MEGABYTE := 1048576.0

@onready var _body: PanelContainer = %Body
@onready var _stats: Label = %Stats
## 씬이 늘면 한 줄에 다 안 들어간다 — HFlowContainer 라 다음 줄로 넘어간다.
@onready var _scene_buttons: HFlowContainer = %SceneButtons
## 치트도 여러 열로 — 한 줄에 하나씩 쌓으면 화면 위로 넘쳐 잘렸다(iPhone).
@onready var _cheat_buttons: HFlowContainer = %CheatButtons
@onready var _scroll: ScrollContainer = %Scroll
@onready var _rows: VBoxContainer = %Rows
@onready var _locale_button: Button = %LocaleButton

var _elapsed := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_body.visible = false
	set_process(false)  # 패널을 열었을 때만 통계를 갱신한다.

	%ToggleButton.pressed.connect(_on_toggle_pressed)
	%WipeButton.pressed.connect(_on_wipe_pressed)
	_locale_button.pressed.connect(_on_locale_pressed)

	# 씬 점프 버튼은 레지스트리에서 만든다 — 씬을 추가하면 자동으로 따라온다.
	for scene_id in SceneManager.SCENES:
		var button := Button.new()
		button.text = scene_id
		button.pressed.connect(SceneManager.change_scene.bind(scene_id))
		_scene_buttons.add_child(button)

	for cheat in DebugTools.get_cheats():
		_add_cheat_button(cheat["label"], cheat["callback"])
	DebugTools.cheat_registered.connect(_add_cheat_button)

	EventBus.language_changed.connect(_on_language_changed)
	_update_locale_button()
	_update_stats()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < STATS_INTERVAL:
		return
	_elapsed = 0.0
	_update_stats()


func _on_toggle_pressed() -> void:
	_body.visible = not _body.visible
	set_process(_body.visible)
	if _body.visible:
		_update_stats()
		_fit_height()


## 패널은 아래에서 위로 자란다. 화면 높이의 65% 를 넘으면 그 안에서 스크롤한다 —
## 안 그러면 위쪽 버튼이 화면(노치) 밖으로 나가 누를 수 없다.
func _fit_height() -> void:
	var limit := get_viewport().get_visible_rect().size.y * 0.65
	_scroll.custom_minimum_size.y = minf(_rows.get_combined_minimum_size().y, limit)


func _on_wipe_pressed() -> void:
	SaveManager.wipe()
	print("[debug] 세이브 초기화됨")


## en → ko → ja → en 순환.
func _on_locale_pressed() -> void:
	var locales := Settings.SUPPORTED_LOCALES
	var index := locales.find(Settings.get_locale())
	Settings.set_locale(locales[(index + 1) % locales.size()])


func _on_language_changed(_locale: String) -> void:
	_update_locale_button()


func _add_cheat_button(label: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = label
	# 버튼 위에서 끌어도 목록이 스크롤되게 — 디버그 패널이라 끌다 놓았을 때 눌리는 건 감수한다.
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.pressed.connect(callback)
	_cheat_buttons.add_child(button)


func _update_locale_button() -> void:
	_locale_button.text = "언어: %s" % Settings.get_locale()


func _update_stats() -> void:
	var memory := Performance.get_monitor(Performance.MEMORY_STATIC) / MEGABYTE
	_stats.text = "FPS %d   ·   메모리 %.1f MB" % [Engine.get_frames_per_second(), memory]
