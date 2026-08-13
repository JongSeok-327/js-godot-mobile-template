extends CanvasLayer
## 페이드 전환이 붙은 씬 전환기.
##
## 씬 경로는 SCENES 레지스트리에만 존재한다 — 게임 코드는 문자열 ID만 쓴다.
## 경로를 여기저기 하드코딩하면 파일 하나 옮길 때마다 전수 검색을 해야 한다.
##
## 페이드는 AnimationPlayer 대신 Tween으로 처리한다. 알파 하나를 움직이는 데
## .tscn에 애니메이션 리소스를 손으로 적어 넣을 이유가 없다.

## 씬 ID → 경로. 새 씬을 추가하면 여기에 등록한다.
const SCENES := {
	"boot": "res://scenes/boot/boot.tscn",
	"main_menu": "res://scenes/main_menu/main_menu.tscn",
	"game": "res://scenes/game/game.tscn",
}

const FADE_TIME := 0.3

var current_scene_id := ""

var _changing := false

@onready var _fade: ColorRect = $Fade


func _ready() -> void:
	# 일시정지 중에도 전환이 돌아야 한다 (일시정지 메뉴 → 메인 메뉴 등).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade.visible = false
	_fade.color.a = 0.0


func change_scene(scene_id: String) -> void:
	if _changing:
		push_warning("[scene] 전환 중이라 '%s' 요청을 무시한다" % scene_id)
		return
	if not SCENES.has(scene_id):
		push_error("[scene] 등록되지 않은 씬 ID: %s" % scene_id)
		return

	_changing = true
	EventBus.scene_change_started.emit(scene_id)

	# 보이는 동안 ColorRect가 아래 씬의 입력을 막는다(mouse_filter 기본 STOP).
	_fade.visible = true
	await _fade_to(1.0)

	# 일시정지 상태 그대로 넘기면 새 씬이 멈춘 채로 뜬다 — 고전적인 stuck-pause 버그.
	get_tree().paused = false

	var err := get_tree().change_scene_to_file(SCENES[scene_id])
	if err != OK:
		push_error("[scene] 씬 전환 실패 (%s): %d" % [scene_id, err])
	else:
		current_scene_id = scene_id

	# change_scene_to_file은 지연 실행이다. 한 프레임은 교체, 다음 프레임은
	# 새 씬의 _ready가 끝나기를 기다린다. 그래야 페이드 인 첫 프레임이 안 튄다.
	await get_tree().process_frame
	await get_tree().process_frame

	await _fade_to(0.0)
	_fade.visible = false

	_changing = false
	EventBus.scene_change_finished.emit(scene_id)


func reload_current() -> void:
	if current_scene_id.is_empty():
		push_error("[scene] 현재 씬 ID를 모른다 — change_scene을 거치지 않은 씬")
		return
	change_scene(current_scene_id)


func is_changing() -> bool:
	return _changing


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await tween.finished
