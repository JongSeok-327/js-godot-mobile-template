extends RefCounted
## 번들 폰트가 **실제로** 글리프를 공급하는지.
##
## Godot 4.7 macOS는 시스템 폰트 폴백이 있어서, 화면에 한글이 제대로 보인다는
## 것만으로는 번들 폰트가 쓰였다는 증거가 되지 않는다 — 기기마다 다른 시스템
## 폰트로 그려도 똑같이 "잘 보인다". 그래서 TextServer로 실제 셰이핑을 돌려
## 글리프를 공급한 폰트 RID가 우리가 번들한 리소스의 것인지 확인한다.
##
## 체인 순서(JP 먼저, KR 폴백)의 근거는 assets/fonts/README.md 참고.

const THEME_PATH := "res://ui/theme/default_theme.tres"
const KR_PATH := "res://assets/fonts/noto_sans_kr_regular.otf"
const JP_PATH := "res://assets/fonts/noto_sans_jp_regular.otf"

const HANGUL_GA := 0xAC00


func run(t: Node) -> void:
	var theme := load(THEME_PATH) as Theme
	var font := theme.default_font as FontVariation
	t.check(font != null, "테마 기본 폰트가 FontVariation으로 지정됨")
	if font == null:
		return

	var kr := load(KR_PATH) as FontFile
	var jp := load(JP_PATH) as FontFile

	# 1) 폰트 체인이 프로젝트 안의 파일만 가리키는지.
	t.eq(font.base_font.resource_path, JP_PATH, "기본 폰트는 번들 JP")
	t.eq(font.fallbacks.size(), 1, "폴백은 하나")
	t.eq(font.fallbacks[0].resource_path, KR_PATH, "폴백은 번들 KR")

	# 2) JP에 한글이 없다는 사실이 폴백 체인이 실제로 필요하다는 증거다.
	jp.allow_system_fallback = false
	t.check(not jp.has_char(HANGUL_GA), "JP 폰트에는 한글이 없다 — 폴백이 반드시 타야 한다")
	jp.allow_system_fallback = true

	# 3) 셰이핑 결과의 글리프 공급자가 번들 폰트인지. 시스템 폰트로 그렸다면
	#    RID가 우리 리소스의 것과 다르다.
	t.eq(_glyph_font(font, "A"), jp.get_rids()[0], "라틴 글리프는 번들 JP가 공급")
	t.eq(_glyph_font(font, "あ"), jp.get_rids()[0], "가나 글리프는 번들 JP가 공급")
	t.eq(_glyph_font(font, "가"), kr.get_rids()[0], "한글 글리프는 번들 KR 폴백이 공급")


## text의 첫 글리프를 그린 폰트 RID.
func _glyph_font(font: Font, text: String) -> RID:
	var server := TextServerManager.get_primary_interface()
	var shaped := server.create_shaped_text()
	server.shaped_text_add_string(shaped, text, font.get_rids(), 32)
	var glyphs := server.shaped_text_get_glyphs(shaped)
	var rid := RID()
	if not glyphs.is_empty():
		rid = glyphs[0]["font_rid"]
	server.free_rid(shaped)
	return rid
