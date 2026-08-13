extends RefCounted
## 버스 레이아웃이 실제로 로드됐는지 + AudioManager 풀 구성 검증.
##
## 재생 자체는 헤드리스 더미 오디오 드라이버에 의존하므로 단언하지 않는다.
## 여기서 잡고 싶은 건 "버스 이름이 어긋나 Settings의 볼륨이 아무 데도 안 걸리는" 상황.

const AudioManagerScript := preload("res://autoload/audio_manager.gd")


func run(t: Node) -> void:
	_test_bus_layout(t)
	_test_pool(t)


func _test_bus_layout(t: Node) -> void:
	t.check(AudioServer.get_bus_index("Master") == 0, "Master 버스는 0번")
	t.check(AudioServer.get_bus_index("Music") >= 0, "Music 버스 존재")
	t.check(AudioServer.get_bus_index("SFX") >= 0, "SFX 버스 존재")
	t.eq(
		AudioServer.get_bus_send(AudioServer.get_bus_index("Music")),
		&"Master",
		"Music은 Master로 전송"
	)
	t.eq(
		AudioServer.get_bus_send(AudioServer.get_bus_index("SFX")),
		&"Master",
		"SFX는 Master로 전송"
	)

	# Settings의 볼륨 키가 실제 버스 이름과 어긋나면 볼륨 조절이 조용히 죽는다.
	for key in Settings.VOLUME_BUSES:
		t.check(
			AudioServer.get_bus_index(Settings.VOLUME_BUSES[key]) >= 0,
			"Settings 볼륨 키 '%s' → 실제 버스 존재" % key
		)


func _test_pool(t: Node) -> void:
	var manager: Node = AudioManagerScript.new()
	# _ready()가 재생기를 만들기 때문에 트리에 한 번 넣어야 한다.
	t.get_tree().root.add_child(manager)

	var music := 0
	var sfx := 0
	var other := 0
	for child in manager.get_children():
		var player := child as AudioStreamPlayer
		if player == null:
			other += 1
		elif player.bus == AudioManagerScript.MUSIC_BUS:
			music += 1
		elif player.bus == AudioManagerScript.SFX_BUS:
			sfx += 1
		else:
			other += 1

	t.eq(music, 2, "Music 버스 재생기 2개 (크로스페이드용)")
	t.eq(sfx, AudioManagerScript.SFX_POOL_SIZE, "SFX 버스 재생기 8개")
	t.eq(other, 0, "예상 밖의 자식 노드 없음")
	t.eq(
		manager.process_mode,
		Node.PROCESS_MODE_ALWAYS,
		"일시정지 중에도 동작 (PROCESS_MODE_ALWAYS)"
	)

	t.get_tree().root.remove_child(manager)
	manager.free()
