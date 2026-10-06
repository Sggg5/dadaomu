class_name TombGuardianBeast
extends Enemy
## 固定扑击→扇弹→地刺循环。落点快照/独立局部攻击，不访问地图、奖励或遗物。
const BULLET: PackedScene = preload("res://scenes/enemies/enemy_projectile.tscn")
enum State { INTRO, DECIDE, POUNCE_WINDUP, POUNCE, ROAR_WINDUP, ROAR, SPIKE_WINDUP, SPIKES, RECOVERY }
var state: State = State.INTRO
var beast_data: TombBeastDefinition
var rage: bool = false
var rage_entries: int = 0
var pounce_target: Vector2
var roar_direction: Vector2
var pounces: int = 0
var roars: int = 0
var spike_batches: int = 0
var _timer: float
var _next_skill: int = 0
var _pounce_velocity: Vector2
var _attacks: Array[WeakRef] = []


func _ready() -> void:
	super._ready()
	beast_data = definition as TombBeastDefinition
	_timer = beast_data.intro_duration
	health.changed.connect(_check_rage)


func _check_rage(current: float, maximum: float) -> void:
	if not rage and current > 0 and current <= maximum*beast_data.phase_two_threshold:
		rage = true
		rage_entries += 1


func _tick_ai(delta: float) -> void:
	_timer -= delta
	match state:
		State.INTRO:
			if _timer <= 0: _decide()
		State.DECIDE:
			move_actor(aim_direction,delta)
			if _timer <= 0: _begin_skill()
		State.POUNCE_WINDUP:
			if _timer <= 0:
				state = State.POUNCE
				telegraphing = false
				_timer = beast_data.pounce_duration
				_pounce_velocity = (pounce_target-global_position)/beast_data.pounce_duration
		State.POUNCE:
			var movement := _pounce_velocity*delta
			if movement.length() > global_position.distance_to(pounce_target): movement = pounce_target-global_position
			var collision := move_and_collide(movement)
			if collision or global_position.distance_to(pounce_target) < 1 or _timer <= 0: _land()
		State.ROAR_WINDUP:
			if _timer <= 0:
				state = State.ROAR
				roar_direction = aim_direction
		State.ROAR:
			_roar()
			_recover()
		State.SPIKE_WINDUP:
			if _timer <= 0: state = State.SPIKES
		State.SPIKES:
			_recover()
		State.RECOVERY:
			if _timer <= 0: _decide()
	queue_redraw()


func _begin_skill() -> void:
	velocity = Vector2.ZERO
	telegraphing = true
	match _next_skill:
		0:
			state = State.POUNCE_WINDUP
			pounce_target = target.global_position
			_timer = beast_data.pounce_windup
		1:
			state = State.ROAR_WINDUP
			_timer = beast_data.roar_windup
		2:
			state = State.SPIKE_WINDUP
			_timer = beast_data.spike_windup
			_spikes()
	_next_skill = (_next_skill+1)%3


func _land() -> void:
	pounces += 1
	if global_position.distance_to(target.global_position) <= beast_data.pounce_radius and has_line_to_target(): target.take_damage(scaled_damage(beast_data.pounce_damage))
	var pulse := CombatPulse.new()
	pulse.radius = beast_data.pounce_radius
	pulse.position = projectile_parent.to_local(global_position)
	projectile_parent.add_child(pulse)
	_attacks.append(weakref(pulse))
	_recover()


func _roar() -> void:
	roars += 1
	var angles: Array[int] = []
	angles.assign([-36,-24,-12,0,12,24,36] if rage else [-30,-15,0,15,30])
	for angle in angles:
		var request := AttackRequest.new()
		request.origin = global_position
		request.direction = roar_direction.rotated(deg_to_rad(angle))
		request.damage = scaled_damage(beast_data.roar_damage)
		request.speed = beast_data.roar_speed
		request.lifetime = beast_data.roar_lifetime
		var bullet := BULLET.instantiate() as EnemyProjectile
		projectile_parent.add_child(bullet)
		bullet.setup(request)
		bullet.track_player(target)
		_attacks.append(weakref(bullet))


func _spikes() -> void:
	var offsets: Array[Vector2] = []
	offsets.assign([Vector2.ZERO,Vector2(100,60),Vector2(-100,60)] if spike_batches%2 == 0 else [Vector2.ZERO,Vector2(80,-90),Vector2(-80,-90)])
	if rage: offsets.append_array([Vector2(150,0),Vector2(-150,0)])
	spike_batches += 1
	var reserved: Array[Vector2] = []
	for offset in offsets:
		var point := target.global_position+offset
		# 固定Pattern无随机；边界/障碍点用有限近邻补位，避免警告落在墙内。
		var candidates: Array[Vector2] = [point,point+Vector2(0,64),point-Vector2(0,64),point+Vector2(64,0),point-Vector2(64,0)]
		for y in range(208,538,64):
			for x in range(160,1160,64): candidates.append(Vector2(x,y))
		candidates.sort_custom(func(a: Vector2,b: Vector2) -> bool: return a.distance_squared_to(point) < b.distance_squared_to(point))
		for candidate in candidates:
			if not Room.ROOM_RECT.grow(-beast_data.spike_radius).has_point(candidate): continue
			if reserved.any(func(other: Vector2) -> bool: return other.distance_to(candidate) < 40): continue
			var ray := PhysicsPointQueryParameters2D.new()
			ray.position = candidate
			ray.collision_mask = 1
			if not get_world_2d().direct_space_state.intersect_point(ray).is_empty(): continue
			var spike := TombSpike.new()
			spike.owner_boss = self
			spike.player = target
			spike.warning = beast_data.spike_warning
			spike.visual = beast_data.spike_visual
			spike.radius = beast_data.spike_radius
			spike.damage = scaled_damage(beast_data.spike_damage)
			spike.position = projectile_parent.to_local(candidate)
			projectile_parent.add_child(spike)
			_attacks.append(weakref(spike))
			reserved.append(candidate)
			break


func _decide() -> void:
	state = State.DECIDE
	_timer = beast_data.decision_cooldown*(beast_data.phase_two_cooldown_multiplier if rage else 1)


func _recover() -> void:
	state = State.RECOVERY
	telegraphing = false
	velocity = Vector2.ZERO
	_timer = beast_data.recovery_time


func stop_ai() -> void:
	super.stop_ai()
	for reference in _attacks:
		var node = reference.get_ref()
		if is_instance_valid(node):
			node.set_physics_process(false)
			node.queue_free()
	_attacks.clear()


func _draw_body(color: Color) -> void:
	var tint := Color("748078") if color == definition.body_color else color
	draw_colored_polygon(PackedVector2Array([Vector2(-40,-18),Vector2(-24,-40),Vector2(24,-40),Vector2(40,-18),Vector2(32,30),Vector2(-32,30)]),tint)
	for sign_value in [-1,1]:
		draw_line(Vector2(sign_value*20,-28),Vector2(sign_value*38,-55),Color("c5bd92"),9)
		draw_circle(Vector2(sign_value*14,-12),5,Color("ffad60"))
	if state == State.POUNCE_WINDUP:
		draw_arc(to_local(pounce_target),beast_data.pounce_radius,0,TAU,48,Color("ffad60"),4)
	if state == State.ROAR_WINDUP:
		for angle in [-30,30]: draw_line(Vector2.ZERO,aim_direction.rotated(deg_to_rad(angle))*230,Color("ffad60"),3)
