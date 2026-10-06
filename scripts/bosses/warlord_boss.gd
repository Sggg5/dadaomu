class_name WarlordBoss
extends Enemy
## 确定性交替冲锋/震荡；只向Encounter请求一次召尸，不访问地图或Build。
signal summon_requested(count: int)
enum State { INTRO, DECIDE, CHARGE_WINDUP, CHARGE, SHOCKWAVE_WINDUP, SHOCKWAVE, RECOVERY }
var state: State = State.INTRO
var boss_data: BossDefinition
var phase_two: bool = false
var charge_direction: Vector2
var charges: int = 0
var shockwaves: int = 0
var _timer: float
var _charge_next: bool = true
var _charge_hit: bool = false


func _ready() -> void:
	super._ready()
	boss_data = definition as BossDefinition
	_timer = boss_data.intro_duration
	health.changed.connect(_check_phase)


func _check_phase(current: float, maximum: float) -> void:
	if not phase_two and current > 0.0 and current <= maximum * boss_data.phase_two_threshold:
		phase_two = true
		summon_requested.emit(boss_data.summon_count)


func _tick_ai(delta: float) -> void:
	_timer -= delta
	match state:
		State.INTRO:
			velocity = Vector2.ZERO
			if _timer <= 0.0: _decide()
		State.DECIDE:
			move_actor(aim_direction, delta)
			if _timer <= 0.0:
				telegraphing = true
				state = State.CHARGE_WINDUP if _charge_next else State.SHOCKWAVE_WINDUP
				_timer = boss_data.charge_windup if _charge_next else boss_data.shockwave_windup
				_charge_next = not _charge_next
		State.CHARGE_WINDUP:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				charge_direction = aim_direction
				_charge_hit = false
				charges += 1
				telegraphing = false
				state = State.CHARGE
				_timer = boss_data.charge_duration
		State.CHARGE:
			velocity = charge_direction * boss_data.charge_speed
			var collision := move_and_collide(velocity * delta)
			# 先结算实际碰撞；撞障碍时不得再走距离命中分支。
			if collision:
				if collision.get_collider() == target and not _charge_hit:
					_charge_hit = true
					target.take_damage(scaled_damage(boss_data.charge_damage))
				_recover()
			else:
				if not _charge_hit and global_position.distance_to(target.global_position) <= 50.0 and has_line_to_target():
					_charge_hit = true
					target.take_damage(scaled_damage(boss_data.charge_damage))
				if _timer <= 0.0: _recover()
		State.SHOCKWAVE_WINDUP:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				state = State.SHOCKWAVE
				telegraphing = false
		State.SHOCKWAVE:
			shockwaves += 1
			if global_position.distance_to(target.global_position) <= boss_data.shockwave_radius:
				target.take_damage(scaled_damage(boss_data.shockwave_damage))
			var pulse := CombatPulse.new()
			pulse.radius = boss_data.shockwave_radius
			pulse.position = projectile_parent.to_local(global_position)
			projectile_parent.add_child(pulse)
			_recover()
		State.RECOVERY:
			velocity = Vector2.ZERO
			if _timer <= 0.0: _decide()


func _decide() -> void:
	state = State.DECIDE
	_timer = boss_data.decision_cooldown * (boss_data.phase_two_cooldown_multiplier if phase_two else 1.0)


func _recover() -> void:
	state = State.RECOVERY
	_timer = boss_data.recovery_time
	velocity = Vector2.ZERO


func _draw_body(color: Color) -> void:
	var tint := Color("624b5b") if color == definition.body_color else color
	if state == State.CHARGE_WINDUP: tint = Color("ff5353")
	draw_colored_polygon(PackedVector2Array([Vector2(-28,-24),Vector2(28,-24),Vector2(36,30),Vector2(-36,30)]), tint)
	draw_rect(Rect2(-30,-36,60,14), Color("302d42"))
	draw_circle(Vector2(0,-29), 5, Color("d4b667"))
	draw_line(Vector2(-30,0),Vector2(-43,29),tint,10)
	draw_line(Vector2(30,0),Vector2(43,29),tint,10)
	if state == State.CHARGE_WINDUP:
		draw_line(aim_direction * 40, aim_direction * boss_data.charge_speed * boss_data.charge_duration, Color("ff5353"), 8)
	if state == State.SHOCKWAVE_WINDUP:
		var progress := clampf(1.0 - _timer / boss_data.shockwave_windup, 0.0, 1.0)
		draw_circle(Vector2.ZERO, boss_data.shockwave_radius, Color(1,0.35,0.1,0.08))
		draw_arc(Vector2.ZERO, boss_data.shockwave_radius * progress, 0, TAU, 48, Color("ffb557"), 5)
