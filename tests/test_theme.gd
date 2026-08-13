extends RefCounted
## 테마가 "로드는 됐지만 항목이 비어있는" 상태로 조용히 넘어가지 않게 막는다.
## .tres를 손으로 쓰기 때문에 오타가 나도 에러 없이 그냥 무시된다.

const THEME_PATH := "res://ui/theme/default_theme.tres"


func run(t: Node) -> void:
	t.eq(
		ProjectSettings.get_setting("gui/theme/custom", ""),
		THEME_PATH,
		"프로젝트 기본 테마로 등록됨"
	)

	var theme := load(THEME_PATH) as Theme
	t.check(theme != null, "테마 리소스 로드")
	if theme == null:
		return

	t.check(theme.default_font_size > 0, "기본 폰트 크기 지정됨")

	for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.check(
			theme.has_stylebox(style_name, "Button"),
			"Button 스타일박스 '%s' 존재" % style_name
		)

	t.check(theme.has_font_size("font_size", "Button"), "Button 폰트 크기 지정됨")
	t.check(theme.has_color("font_color", "Button"), "Button 글자색 지정됨")
	t.check(theme.has_stylebox("panel", "PanelContainer"), "PanelContainer 패널 스타일 존재")
	t.check(theme.has_stylebox("slider", "HSlider"), "HSlider 트랙 스타일 존재")

	# 그래버는 지정하지 않으면 엔진 내장 아이콘으로 그려진다 — 엔진 버전에 따라
	# 모양이 바뀌는 부분이라, 프로젝트 리소스를 가리키는지 못 박아 둔다.
	for icon_name in ["grabber", "grabber_highlight"]:
		var has_icon := theme.has_icon(icon_name, "HSlider")
		t.check(has_icon, "HSlider '%s' 아이콘 존재" % icon_name)
		var icon: Texture2D = theme.get_icon(icon_name, "HSlider") if has_icon else null
		t.check(
			icon != null and icon.resource_path.begins_with("res://assets/"),
			"HSlider '%s' 아이콘이 프로젝트 리소스다 (%s)"
				% [icon_name, "없음" if icon == null else icon.resource_path]
		)

	# 터치 타겟: 버튼 상하 여백만으로도 손가락이 누를 만한 높이가 나와야 한다.
	var normal := theme.get_stylebox("normal", "Button")
	var min_height := normal.content_margin_top + normal.content_margin_bottom
	t.check(min_height >= 48.0, "버튼 세로 여백이 터치 타겟 확보 (%.0fpx)" % min_height)
