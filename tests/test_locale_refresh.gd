extends RefCounted
## 언어를 바꾸면 **코드가 채운 글자**도 바뀌어야 한다.
##
## 버튼 글자가 번역 키면 Godot 이 알아서 다시 번역하지만, 코드가 `tr()` 결과(이미
## 번역된 문장)를 넣은 글자는 그대로 남는다. 설정의 진동 켜짐/꺼짐이 그렇다 —
## `NOTIFICATION_TRANSLATION_CHANGED` 에서 다시 쓰지 않으면 언어를 바꿔도 고정된다.

const SettingsScene: PackedScene = preload("res://scenes/overlays/settings_menu.tscn")


func run(t: Node) -> void:
	var original_locale := TranslationServer.get_locale()

	TranslationServer.set_locale("ko")
	var settings: CanvasLayer = SettingsScene.instantiate()
	t.add_child(settings)
	await t.get_tree().process_frame

	TranslationServer.set_locale("en")
	await t.get_tree().process_frame
	var haptics_key := "SETTINGS_ON" if Settings.haptics_enabled() else "SETTINGS_OFF"
	t.eq(settings.get_node("%HapticsButton").text, TranslationServer.translate(haptics_key),
		"언어를 바꾸면 진동 켜짐/꺼짐도 바뀐다")

	settings.free()
	TranslationServer.set_locale(original_locale)
