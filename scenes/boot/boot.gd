extends Control
## 최초 진입 씬.
##
## 런치 화면(`boot_splash/bg_color`)과 같은 색 바탕에서 곧바로 메뉴로 간다.
## **제목도 고정 대기도 두지 않는다** — 0.8초 동안 제목을 보여주던 시절엔 시작이
## 굼떠 보였다(kongkong iPhone 지적). 첫 화면 진입에서 멈칫할 만큼 무거운 리소스가
## 생기면 여기서 미리 읽는다 — 이 시간은 앱이 뜨는 시간의 일부로 보인다.


func _ready() -> void:
	# 첫 프레임이 그려진 뒤에 넘긴다 — 트리 세팅 도중에는 씬 전환이 거부된다.
	await get_tree().process_frame
	SceneManager.change_scene("main_menu")
