class_name AttackContext
extends RefCounted
## 一次武器输入的请求批次；只修改快照，不修改共享 PlayerStats。
var requests: Array[AttackRequest] = []


func _init(base: AttackRequest) -> void:
	requests.append(base.copy())
