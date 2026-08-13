class_name NodeUtils
extends RefCounted
## 노드 관련 static 헬퍼 모음. 인스턴스를 만들지 않는다 — `NodeUtils.is_alive(n)`처럼 쓴다.
##
## Godot이 안 주는 것만 넣는다. 한 줄로 되는 건 넣지 않는다.


## 아직 살아 있고 이번 프레임 끝에 사라질 예정도 아닌지.
##
## `is_instance_valid()`만으로는 부족하다 — queue_free()된 노드도 그 프레임
## 끝까지는 valid로 나오기 때문. 콜백이 한 프레임 늦게 도착하는 상황에서
## 이미 버려진 노드를 건드리는 사고가 여기서 걸린다.
static func is_alive(node: Node) -> bool:
	return is_instance_valid(node) and not node.is_queued_for_deletion()


## 자식을 전부 지운다. 목록 UI를 다시 그릴 때처럼.
##
## queue_free()만 하면 실제 삭제는 프레임 끝이라 바로 뒤에서 get_child_count()를
## 재면 아직 옛날 자식이 잡힌다. 트리에서 먼저 떼어내야 그 함정을 피한다.
static func clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
