extends MarginContainer
## 노치·홈 인디케이터를 피해 자식 UI를 배치한다.
##
## stretch가 걸린 프로젝트에서 DisplayServer의 safe area는 실제 화면 픽셀
## 기준이라, 뷰포트 좌표로 환산해야 한다.
##
## 데스크톱에서는 safe area가 창이 아니라 화면 전체 기준이라 의미가 없다 —
## extra_margin만 적용한다.

## safe area 위에 추가로 주는 여백(뷰포트 픽셀).
@export var extra_margin: int = 16


func _ready() -> void:
	get_window().size_changed.connect(_apply)
	_apply()


func _apply() -> void:
	var insets := Vector4i(extra_margin, extra_margin, extra_margin, extra_margin)
	if OS.has_feature("mobile"):
		insets += _display_insets()

	add_theme_constant_override("margin_left", insets.x)
	add_theme_constant_override("margin_top", insets.y)
	add_theme_constant_override("margin_right", insets.z)
	add_theme_constant_override("margin_bottom", insets.w)


func _display_insets() -> Vector4i:
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return Vector4i.ZERO

	var safe := DisplayServer.get_display_safe_area()
	var scale := get_viewport_rect().size / window_size
	return Vector4i(
		roundi(safe.position.x * scale.x),
		roundi(safe.position.y * scale.y),
		roundi((window_size.x - safe.end.x) * scale.x),
		roundi((window_size.y - safe.end.y) * scale.y)
	)
