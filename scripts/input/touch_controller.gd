class_name TouchController
extends Node
## 한 손가락 제스처를 signal로 바꿔주는 컴포넌트 노드. autoload가 아니다 —
## 터치 입력이 필요한 게임 씬에 자식으로 넣고 signal을 연결해 쓴다.
##
## `_unhandled_input`으로 받으므로 UI(일시정지 버튼 등)가 먼저 이벤트를 가져간다.
## 이벤트를 소비하지는 않는다 — 컴포넌트가 마음대로 입력을 삼키면 안 되기 때문.
## 소비가 필요하면 signal을 받는 쪽에서 `get_viewport().set_input_as_handled()`를 부른다.
##
## 첫 손가락만 추적한다. 그 손가락을 뗄 때까지 다른 손가락은 무시한다.
## project.godot의 `emulate_touch_from_mouse=true` 덕분에 에디터에서 마우스로 테스트된다.

## 탭 — 데드존 안에서 롱프레스 시간보다 짧게 눌렀다 뗐을 때.
signal tap(position: Vector2)

## 롱프레스 — 데드존 안에서 `long_press_time`만큼 누르고 있을 때. 떼기 전에 발신된다.
signal long_press(position: Vector2)

## 드래그 — 데드존을 벗어난 뒤 손가락이 움직이는 동안 매 이벤트마다.
signal drag(position: Vector2, relative: Vector2)

## 스와이프 — 손가락을 뗄 때 시작점에서 `swipe_min_distance` 이상 떨어져 있으면.
## direction은 상하좌우 단위 벡터 중 하나(Vector2.LEFT/RIGHT/UP/DOWN).
signal swipe(direction: Vector2)

## 롱프레스로 인정할 누르고 있는 시간(초).
@export_range(0.1, 3.0, 0.05) var long_press_time := 0.5

## 스와이프로 인정할 최소 이동 거리(px). 뷰포트 좌표 기준.
@export_range(10.0, 500.0, 5.0) var swipe_min_distance := 120.0

## 이 거리(px)를 벗어나야 드래그로 전환한다. 손 떨림으로 탭이 깨지는 것을 막는다.
@export_range(0.0, 100.0, 1.0) var drag_deadzone := 16.0

## 추적 중인 손가락 index. -1이면 눌린 손가락 없음.
var _touch_index := -1
var _start_position := Vector2.ZERO
var _current_position := Vector2.ZERO
var _elapsed := 0.0
var _dragging := false
var _long_pressed := false


func _ready() -> void:
	# 손가락이 닿아 있는 동안에만 시간을 잰다.
	set_process(false)


func _process(delta: float) -> void:
	if _long_pressed or _dragging:
		return

	_elapsed += delta
	if _elapsed >= long_press_time:
		_long_pressed = true
		long_press.emit(_current_position)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin(event)
		else:
			_end(event)
	elif event is InputEventScreenDrag:
		_move(event)


func _begin(event: InputEventScreenTouch) -> void:
	if _touch_index != -1:
		return  # 이미 다른 손가락을 추적 중.

	_touch_index = event.index
	_start_position = event.position
	_current_position = event.position
	_elapsed = 0.0
	_dragging = false
	_long_pressed = false
	set_process(true)


func _move(event: InputEventScreenDrag) -> void:
	if event.index != _touch_index:
		return

	_current_position = event.position
	if not _dragging:
		if _start_position.distance_to(event.position) <= drag_deadzone:
			return
		_dragging = true  # 드래그로 확정되면 롱프레스는 더 이상 재지 않는다.

	drag.emit(event.position, event.relative)


func _end(event: InputEventScreenTouch) -> void:
	if event.index != _touch_index:
		return

	# 롱프레스가 이미 나갔으면 탭도 스와이프도 아니다.
	# (오래 끈 드래그는 스와이프로 치지 않는다는 판정도 여기서 같이 걸린다.)
	if not _long_pressed:
		var travel := event.position - _start_position
		if travel.length() >= swipe_min_distance:
			swipe.emit(_cardinal(travel))
		elif not _dragging:
			tap.emit(event.position)

	_touch_index = -1
	set_process(false)


## 이동 벡터를 가장 가까운 상하좌우 단위 벡터로 스냅한다.
func _cardinal(travel: Vector2) -> Vector2:
	if absf(travel.x) >= absf(travel.y):
		return Vector2.RIGHT if travel.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if travel.y > 0.0 else Vector2.UP
