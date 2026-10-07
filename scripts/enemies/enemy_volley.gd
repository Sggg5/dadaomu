class_name EnemyVolley
extends RefCounted
## 不追踪玩家的定向敌弹；每次弹幕最多十二发。
const SCENE: PackedScene = preload("res://scenes/enemies/enemy_projectile.tscn")
static func fire(actor: Enemy, direction: Vector2, count: int, spread: float, damage: float, speed: float, lifetime: float = 2.0) -> void:
	if not actor.can_act() or not is_instance_valid(actor.projectile_parent): return
	if actor.projectile_parent.get_child_count() >= 256: return
	for index in range(mini(count,12)):
		var request := AttackRequest.new()
		request.origin = actor.global_position
		request.direction = direction.rotated((index-(count-1)*0.5)*spread)
		request.damage = actor.scaled_damage(damage)
		request.speed = speed
		request.lifetime = lifetime
		var bullet := SCENE.instantiate() as EnemyProjectile
		actor.projectile_parent.add_child(bullet)
		bullet.setup(request)
		bullet.track_player(actor.target)
