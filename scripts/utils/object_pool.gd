class_name ObjectPool
extends RefCounted
## PackedScene 인스턴스를 재사용하는 풀. autoload도 노드도 아니다 —
## 풀이 필요한 쪽에서 `ObjectPool.new(scene, 32)`로 만들어 멤버로 들고 있는다.
##
## 총알·이펙트처럼 자주 생겼다 사라지는 노드를 매번 instantiate/queue_free 하면
## 그때마다 메모리 할당과 `_ready()`가 다시 돈다. 풀은 그걸 재활용으로 바꾼다.
##
## **대여한 노드는 트리 밖에 있다** — 호출자가 `add_child()`로 붙인다.
## 반납하면 풀이 부모에서 떼어내고, 노드가 `_pool_reset()`을 구현했으면 불러준다.
## 위치·속도·타이머·visible 같은 상태 초기화는 그 안에서 하면 된다:
##
## [codeblock]
## func _pool_reset() -> void:
##     velocity = Vector2.ZERO
##     _lifetime = 0.0
## [/codeblock]
##
## 물리 콜백(body_entered 등) 안에서는 트리 조작이 막힌다 —
## 그럴 때는 `pool.release.call_deferred(node)`.
##
## 풀이 해제될 때 대기 중인 인스턴스도 같이 free된다. 대여 중인 노드는
## 풀이 추적하지 않으므로 호출자 책임이다.

## 반납된 노드가 구현하고 있으면 호출해주는 메서드 이름.
const RESET_METHOD := &"_pool_reset"

var _scene: PackedScene
## 대기 중(반납된) 인스턴스. 대여 중인 노드는 여기 없다.
var _idle: Array[Node] = []


func _init(scene: PackedScene, initial_size: int = 0) -> void:
	_scene = scene
	prewarm(initial_size)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# clear()를 부르지 않고 같은 일을 여기서 다시 한다 — PREDELETE 시점에는
		# 멤버 접근은 되지만 자기 메서드 호출이 "null instance"로 깨진다(4.7 확인).
		for node in _idle:
			if NodeUtils.is_alive(node):
				node.free()
		_idle.clear()


## 미리 만들어 둔다. 첫 사용에서 프레임이 튀는 것을 막는다.
func prewarm(count: int) -> void:
	for i in count:
		var node := _instantiate()
		if node == null:
			return
		_idle.append(node)


## 대기 중인 게 있으면 재사용하고 없으면 새로 만든다.
## 반환된 노드는 트리 밖이다 — 호출자가 add_child 해야 한다.
func acquire() -> Node:
	if _idle.is_empty():
		return _instantiate()
	return _idle.pop_back()


## 부모에서 떼어내고 `_pool_reset()`을 부른 뒤 대기열에 넣는다.
func release(node: Node) -> void:
	if not NodeUtils.is_alive(node):
		return
	if _idle.has(node):
		# 두 번 반납하면 같은 노드를 두 곳에 빌려주게 된다 — 추적이 매우 어려운 버그.
		push_error("[object_pool] 이미 반납된 노드를 또 반납했다: %s" % node)
		return

	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	if node.has_method(RESET_METHOD):
		node.call(RESET_METHOD)
	_idle.append(node)


## 대기 중인 인스턴스를 전부 free한다. 대여 중인 노드는 건드리지 않는다.
func clear() -> void:
	for node in _idle:
		if NodeUtils.is_alive(node):
			node.free()  # 트리 밖이라 즉시 free해도 안전하다.
	_idle.clear()


func idle_count() -> int:
	return _idle.size()


func _instantiate() -> Node:
	if _scene == null:
		push_error("[object_pool] scene이 null이라 인스턴스를 만들 수 없다")
		return null
	return _scene.instantiate()
