extends Node
## 음악 크로스페이드 + SFX 재생.
##
## 노드 전체가 PROCESS_MODE_ALWAYS다 — 일시정지 중에도 배경음악이 끊기지 않아야
## 하고, 일시정지 메뉴의 버튼 효과음도 나야 하기 때문. (자식들은 상속받는다.)
##
## 볼륨은 여기서 직접 만지지 않는다. 버스(Music/SFX) 볼륨은 Settings 담당.

const SFX_POOL_SIZE := 8
const DEFAULT_CROSSFADE := 1.0
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

## 사실상 무음. linear_to_db(0)은 -inf라 트윈 대상으로 쓸 수 없다.
const SILENT_DB := -60.0

var _music_players: Array[AudioStreamPlayer] = []
var _active_music := 0
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx := 0
var _fade_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# 크로스페이드를 하려면 재생기가 2개 필요하다 (나가는 곡 / 들어오는 곡).
	for i in 2:
		_music_players.append(_add_player(MUSIC_BUS))
	for i in SFX_POOL_SIZE:
		_sfx_players.append(_add_player(SFX_BUS))


## stream이 null이면 stop_music과 같다. 같은 곡을 다시 넘기면 무시한다.
func play_music(stream: AudioStream, crossfade := DEFAULT_CROSSFADE) -> void:
	if stream == null:
		stop_music(crossfade)
		return

	var outgoing := _music_players[_active_music]
	if outgoing.stream == stream and outgoing.playing:
		return

	_active_music = 1 - _active_music
	var incoming := _music_players[_active_music]
	incoming.stream = stream
	incoming.volume_db = SILENT_DB if crossfade > 0.0 else 0.0
	incoming.play()

	_kill_fade()
	if crossfade <= 0.0:
		incoming.volume_db = 0.0
		outgoing.stop()
		return

	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_property(incoming, "volume_db", 0.0, crossfade)
	if outgoing.playing:
		_fade_tween.tween_property(outgoing, "volume_db", SILENT_DB, crossfade)
		_fade_tween.tween_callback(outgoing.stop).set_delay(crossfade)


func stop_music(fade_time := DEFAULT_CROSSFADE) -> void:
	_kill_fade()
	var player := _music_players[_active_music]
	if not player.playing:
		return
	if fade_time <= 0.0:
		player.stop()
		return
	_fade_tween = create_tween()
	_fade_tween.tween_property(player, "volume_db", SILENT_DB, fade_time)
	_fade_tween.tween_callback(player.stop)


func is_music_playing() -> bool:
	return _music_players[_active_music].playing


## 비어있는 슬롯을 우선 쓰고, 전부 차 있으면 가장 오래된 슬롯을 뺏는다.
func play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return

	var count := _sfx_players.size()
	for offset in count:
		var index := (_next_sfx + offset) % count
		var player := _sfx_players[index]
		if not player.playing:
			_play_on(player, stream, index)
			return

	_play_on(_sfx_players[_next_sfx], stream, _next_sfx)


func stop_all_sfx() -> void:
	for player in _sfx_players:
		player.stop()


func _add_player(bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	add_child(player)
	return player


func _play_on(player: AudioStreamPlayer, stream: AudioStream, index: int) -> void:
	_next_sfx = (index + 1) % _sfx_players.size()
	player.stream = stream
	player.play()


func _kill_fade() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
