extends RefCounted
## ObjectPool 대여/반납/재사용 + `_pool_reset()` 규약.
##
## 풀은 RefCounted라 지역 변수가 사라질 때 대기 인스턴스를 같이 free한다 —
## 각 케이스마다 풀을 새로 만들면 누수 없이 정리된다.
## 대여한 채로 끝나는 노드만 테스트가 직접 free한다.


## 반납 때 _pool_reset()이 불렸는지 세는 테스트용 노드.
class Probe extends Node:
	var reset_count := 0

	func _pool_reset() -> void:
		reset_count += 1


var _scene: PackedScene


func run(t: Node) -> void:
	_scene = _make_probe_scene()

	_test_acquire_creates(t)
	_test_reuses_released(t)
	_test_calls_pool_reset(t)
	_test_release_detaches(t)
	_test_prewarm(t)
	_test_double_release_rejected(t)
	_test_clear(t)


## Probe 스크립트를 붙인 노드를 PackedScene으로 굽는다.
func _make_probe_scene() -> PackedScene:
	var node := Node.new()
	node.set_script(Probe)
	var scene := PackedScene.new()
	scene.pack(node)
	node.free()
	return scene


func _test_acquire_creates(t: Node) -> void:
	var pool := ObjectPool.new(_scene)
	t.eq(pool.idle_count(), 0, "빈 풀의 대기 수는 0")

	var node := pool.acquire()
	t.check(node is Probe, "acquire가 scene 인스턴스를 만든다")
	t.check(node.get_parent() == null, "대여한 노드는 트리 밖 — 붙이는 건 호출자 몫")
	node.free()


func _test_reuses_released(t: Node) -> void:
	var pool := ObjectPool.new(_scene)
	var first := pool.acquire()
	pool.release(first)
	t.eq(pool.idle_count(), 1, "반납하면 대기열에 들어간다")

	var second := pool.acquire()
	t.check(first == second, "대기 중인 인스턴스를 재사용한다")
	t.eq(pool.idle_count(), 0, "대여하면 대기열에서 빠진다")
	second.free()


func _test_calls_pool_reset(t: Node) -> void:
	var pool := ObjectPool.new(_scene)
	var probe := pool.acquire() as Probe
	t.eq(probe.reset_count, 0, "대여 시점에는 _pool_reset()을 부르지 않는다")

	pool.release(probe)
	t.eq(probe.reset_count, 1, "반납할 때 _pool_reset()을 불러준다")


func _test_release_detaches(t: Node) -> void:
	var pool := ObjectPool.new(_scene)
	var node := pool.acquire()
	t.add_child(node)
	t.check(node.get_parent() == t, "트리에 붙인 상태")

	pool.release(node)
	t.check(node.get_parent() == null, "반납하면 부모에서 떼어낸다")


func _test_prewarm(t: Node) -> void:
	var pool := ObjectPool.new(_scene, 3)
	t.eq(pool.idle_count(), 3, "initial_size만큼 미리 만들어 둔다")

	pool.prewarm(2)
	t.eq(pool.idle_count(), 5, "prewarm으로 더 채울 수 있다")


func _test_double_release_rejected(t: Node) -> void:
	var pool := ObjectPool.new(_scene)
	var node := pool.acquire()
	pool.release(node)
	pool.release(node)  # 같은 노드를 두 곳에 빌려주면 안 된다 (push_error 예상)
	t.eq(pool.idle_count(), 1, "중복 반납은 대기열에 두 번 들어가지 않는다")


func _test_clear(t: Node) -> void:
	var pool := ObjectPool.new(_scene, 2)
	var borrowed := pool.acquire()
	var returned := pool.acquire()
	pool.release(returned)

	pool.clear()
	t.eq(pool.idle_count(), 0, "clear 후 대기 수는 0")
	t.check(not is_instance_valid(returned), "clear가 대기 인스턴스를 free한다")
	t.check(is_instance_valid(borrowed), "대여 중인 노드는 clear가 건드리지 않는다")
	borrowed.free()
