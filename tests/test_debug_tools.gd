extends RefCounted
## 치트 등록 규약 + "디버그 빌드에서만 패널" 조건.
##
## 릴리스 빌드는 헤드리스로 재현할 수 없다(테스트 자체가 디버그 빌드로 돈다).
## 여기서는 디버그 쪽 분기만 확인하고, 릴리스 분기는 OS.is_debug_build() 가드
## 한 줄에 맡긴다.


func run(t: Node) -> void:
	t.check(OS.is_debug_build(), "테스트는 디버그 빌드로 돈다 — 패널 조건의 전제")
	t.check(DebugTools.has_panel(), "디버그 빌드에서는 패널이 붙어 있다")

	var fired: Array[String] = []
	var before := DebugTools.get_cheats().size()
	DebugTools.register_cheat("테스트 치트", func() -> void: fired.append("눌림"))

	t.eq(DebugTools.get_cheats().size(), before + 1, "치트가 목록에 등록된다")

	var cheat: Dictionary = DebugTools.get_cheats().back()
	t.eq(cheat["label"], "테스트 치트", "라벨이 그대로 보존된다")

	cheat["callback"].call()
	t.eq(fired, ["눌림"] as Array[String], "등록한 콜백이 호출된다")
