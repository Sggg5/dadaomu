class_name ScarabEnemy
extends Enemy
## 追击 → 原地可读前摇 → 范围/墙体再判定咬击 → 恢复，伤害不是接触每帧结算。

enum State { CHASE, WINDUP, RECOVERY }
var state: State = State.CHASE
var cooldown_remaining: float = 0.0
var _timer: float = 0.0


func _tick_ai(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	match state:
		State.WINDUP:
			velocity = Vector2.ZERO
			_timer -= delta
			if _timer <= 0.0:
				telegraphing = false
				if global_position.distance_to(target.global_position) <= definition.attack_range and has_line_to_target():
					target.take_damage(definition.contact_damage)
				cooldown_remaining = definition.attack_cooldown
				_timer = definition.recovery_time
				state = State.RECOVERY
		State.RECOVERY:
			velocity = Vector2.ZERO
			_timer -= delta
			if _timer <= 0.0:
				state = State.CHASE
		State.CHASE:
			if global_position.distance_to(target.global_position) <= definition.attack_range and has_line_to_target():
				velocity = Vector2.ZERO
				if cooldown_remaining <= 0.0:
					state = State.WINDUP
					telegraphing = true
					_timer = definition.windup_time
			else:
				move_actor(aim_direction, delta)


func _draw_body(color: Color) -> void:
	draw_circle(Vector2.ZERO, 14, color)
	draw_arc(Vector2.ZERO, 14, 0, TAU, 20, Color("273327"), 2)
	for side in [-1.0, 1.0]:
		for offset in [-8.0, 0.0, 8.0]:
			draw_line(Vector2(offset, side * 10), Vector2(offset - 4, side * 19), color, 3)
	draw_line(Vector2.ZERO, aim_direction * 17, Color("35452c"), 3)
