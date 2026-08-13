extends Control
## 최초 진입 씬. autoload 초기화가 끝날 때까지 화면을 가린다.
## 실제 메인 메뉴 전환은 Phase 3에서 SceneManager를 통해 붙인다.


func _ready() -> void:
	print("[boot] ready")
