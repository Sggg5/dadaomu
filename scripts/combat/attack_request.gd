class_name AttackRequest
extends RefCounted
## 一次发射的数值快照，隔离攻击意图和世界内弹丸的创建。
## 后续武器策略可发出多条请求或另一种攻击请求，不在玩家脚本堆效果分支。

var origin: Vector2
var direction: Vector2
var damage: float
var speed: float
var lifetime: float
var pierce_count: int = 0
var projectile_scale: float = 1.0
var tags: Array[StringName] = []


func copy() -> AttackRequest:
	var result := AttackRequest.new()
	result.origin = origin
	result.direction = direction
	result.damage = damage
	result.speed = speed
	result.lifetime = lifetime
	result.pierce_count = pierce_count
	result.projectile_scale = projectile_scale
	result.tags = tags.duplicate()
	return result
