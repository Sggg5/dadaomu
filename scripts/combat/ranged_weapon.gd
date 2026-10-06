class_name RangedWeapon
extends Node
## 仅负责基础远程攻击和冷却；场景拥有弹丸并负责创建/清理。

signal attack_requested(request: AttackRequest)

var cooldown_remaining: float = 0.0
var attack_modifier: Callable


func _physics_process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)


func try_attack(origin: Vector2, direction: Vector2, stats: PlayerStats) -> bool:
	if cooldown_remaining > 0.0 or direction.is_zero_approx():
		return false
	var request := AttackRequest.new()
	request.origin = origin
	request.direction = direction.normalized()
	request.damage = stats.attack_damage
	request.speed = stats.projectile_speed
	request.lifetime = stats.projectile_lifetime
	cooldown_remaining = 1.0 / maxf(stats.attack_speed, 0.1)
	var requests: Array[AttackRequest] = [request]
	if attack_modifier.is_valid():
		requests = attack_modifier.call(request)
	for modified in requests:
		attack_requested.emit(modified)
	return true
