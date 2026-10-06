class_name BanditShooter
extends Enemy
## 距离带移动和可读瞄准前摇；发射时快照方向，之后弹丸不再追踪目标。

const BULLET_SCENE: PackedScene = preload("res://scenes/enemies/enemy_projectile.tscn")
enum State { MOVE, AIM, RECOVERY }

@onready var ranged: RangedEnemyDefinition = definition as RangedEnemyDefinition
var state: State = State.MOVE
var cooldown_remaining: float = 0.0
var shots_fired: int = 0
var last_shot_direction: Vector2
var _timer: float = 0.0


func _tick_ai(delta: float) -> void:
	assert(ranged != null, "Shooter requires ranged definition")
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	var distance := global_position.distance_to(target.global_position)
	match state:
		State.AIM:
			velocity = Vector2.ZERO
			_timer -= delta
			if _timer <= 0.0:
				telegraphing = false
				if distance >= ranged.minimum_fire_distance and distance <= ranged.attack_range and has_line_to_target():
					_fire()
				cooldown_remaining = ranged.attack_cooldown
				_timer = ranged.recovery_time
				state = State.RECOVERY
		State.RECOVERY:
			velocity = Vector2.ZERO
			_timer -= delta
			if _timer <= 0:
				state = State.MOVE
		State.MOVE:
			var movement := Vector2.ZERO
			if distance > ranged.preferred_distance + ranged.distance_tolerance or not has_line_to_target():
				movement = aim_direction
			elif distance < ranged.preferred_distance - ranged.distance_tolerance:
				movement = -aim_direction
			move_actor(movement, delta)
			if distance >= maxf(ranged.minimum_fire_distance, ranged.preferred_distance - ranged.distance_tolerance) and distance <= minf(ranged.attack_range, ranged.preferred_distance + ranged.distance_tolerance) and cooldown_remaining <= 0 and has_line_to_target():
				state = State.AIM
				telegraphing = true
				_timer = ranged.windup_time
				velocity = Vector2.ZERO


func _fire() -> void:
	if not can_act() or not is_instance_valid(projectile_parent):
		return
	var request := AttackRequest.new()
	request.origin = global_position
	request.direction = (target.global_position - global_position).normalized()
	request.damage = scaled_damage(ranged.projectile_damage)
	request.speed = ranged.projectile_speed
	request.lifetime = ranged.projectile_lifetime
	var bullet := BULLET_SCENE.instantiate() as EnemyProjectile
	projectile_parent.add_child(bullet)
	bullet.setup(request)
	bullet.track_player(target)
	last_shot_direction = request.direction
	shots_fired += 1


func _draw_body(color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(0, -16), Vector2(14, -6), Vector2(12, 14), Vector2(-12, 14), Vector2(-14, -6)]), color)
	draw_line(Vector2(-14, -8), Vector2(14, -8), Color("543629"), 4)
	draw_line(Vector2.ZERO, aim_direction * 24, Color("e6d0aa"), 5)
	if telegraphing and is_instance_valid(target):
		draw_line(aim_direction * 24, to_local(target.global_position), Color(1, 0.35, 0.2, 0.45), 1.5)
