class_name AttackRequest
extends RefCounted
## 一次发射的数值快照，隔离攻击意图和世界内弹丸的创建。
## 后续武器策略可发出多条请求或另一种攻击请求，不在玩家脚本堆效果分支。

var origin: Vector2
var direction: Vector2
var damage: float
var speed: float
var lifetime: float


func copy() -> AttackRequest:
	var result := AttackRequest.new()
	result.origin = origin
	result.direction = direction
	result.damage = damage
	result.speed = speed
	result.lifetime = lifetime
	return result
