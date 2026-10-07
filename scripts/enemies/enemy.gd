class_name Enemy
extends CharacterBody2D
## 共享生命、目标注入、受伤/死亡反馈和轻量墙体绕行；具体攻击属于子类。
## 不查绝对路径，不持有 RoomState 或 DungeonLayout。

signal killed

@export var definition: EnemyDefinition
@onready var health: Health = $Health

var encounter_room: Room
var movement_modifiers: Dictionary[int,float] = {}
var target: Player
var projectile_parent: Node2D
var telegraphing: bool = false
var aim_direction: Vector2 = Vector2.RIGHT
var ai_enabled: bool = true
var dying: bool = false
var difficulty: EncounterDifficulty = EncounterDifficulty.from_depth(0)
var activation_remaining: float = 0.0
var _death_remaining: float = 0.0
var _flash_remaining: float = 0.0
var _avoid_remaining: float = 0.0
var _avoid_direction: Vector2


func configure_spawn(player: Player, bullets: Node2D, data: EnemyDefinition = null, encounter: EncounterDifficulty = null) -> void:
	target = player
	projectile_parent = bullets
	if encounter != null:
		difficulty = encounter
	if data != null:
		definition = data
	if is_instance_valid(target):
		target.died.connect(stop_ai)


func _ready() -> void:
	assert(definition != null, "Enemy requires definition")
	health.died.connect(_on_died)
	health.initialize(definition.max_hp * difficulty.hp_multiplier)


func scaled_damage(base_damage: float) -> float:
	return base_damage * difficulty.damage_multiplier


func _physics_process(delta: float) -> void:
	_flash_remaining = maxf(0.0, _flash_remaining - delta)
	if dying:
		_death_remaining -= delta
		scale = Vector2.ONE * maxf(0.0, _death_remaining / definition.death_duration)
		if _death_remaining <= 0.0:
			queue_free()
	elif activation_remaining > 0.0:
		activation_remaining = maxf(0.0, activation_remaining - delta)
		velocity = Vector2.ZERO
		telegraphing = false
	elif can_act():
		var offset := target.global_position - global_position
		if not offset.is_zero_approx():
			aim_direction = offset.normalized()
		_tick_ai(delta)
	else:
		velocity = Vector2.ZERO
		telegraphing = false
	queue_redraw()


func can_act() -> bool:
	return activation_remaining <= 0.0 and ai_enabled and not dying and not health.is_dead and is_instance_valid(target) and target.is_inside_tree() and not target.health.is_dead and target.controls_enabled


func stop_ai() -> void:
	ai_enabled = false
	velocity = Vector2.ZERO
	telegraphing = false


func take_damage(amount: float) -> bool:
	if dying or not health.take_damage(amount):
		return false
	_flash_remaining = 0.12
	queue_redraw()
	return true


func _on_died() -> void:
	if dying:
		return
	dying = true
	stop_ai()
	_death_remaining = definition.death_duration
	$CollisionShape2D.set_deferred("disabled", true)
	killed.emit()
	queue_redraw()


func _tick_ai(_delta: float) -> void:
	pass


func has_line_to_target() -> bool:
	if not is_instance_valid(target):
		return false
	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 1, [get_rid()])
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func move_actor(direction: Vector2, delta: float) -> void:
	if direction.is_zero_approx():
		velocity = Vector2.ZERO
		return
	var movement := direction.normalized()
	if _avoid_remaining > 0.0:
		_avoid_remaining -= delta
		movement = _avoid_direction
	else:
		var query := PhysicsRayQueryParameters2D.create(global_position, global_position + movement * definition.obstacle_probe_distance, 1, [get_rid()])
		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var normal: Vector2 = hit["normal"]
			var tangent := normal.rotated(PI * 0.5)
			if tangent.dot(movement) < 0.0:
				tangent = -tangent
			_avoid_direction = tangent
			_avoid_remaining = definition.avoidance_hold_time
			movement = tangent
	var factor := 1.0
	for value in movement_modifiers.values(): factor = minf(factor,value)
	velocity = movement * definition.move_speed * factor
	move_and_slide()


func _draw() -> void:
	if definition == null:
		return
	var color := definition.body_color
	if dying or _flash_remaining > 0.0:
		color = Color.WHITE
	elif telegraphing:
		color = Color("ffb749")
	elif activation_remaining > 0.0:
		color = color.lightened(0.35)
	_draw_body(color)
	if definition.elite: draw_arc(Vector2.ZERO,26,0,TAU,32,Color("efd477"),3)
	if telegraphing:
		draw_arc(Vector2.ZERO, 23, 0, TAU, 24, Color("ff784f"), 2)
	if is_instance_valid(health) and not dying:
		draw_rect(Rect2(-20, -28, 40, 4), Color("343945"))
		draw_rect(Rect2(-20, -28, 40 * health.current_hp / health.max_hp, 4), Color("e6b870"))


func _draw_body(color: Color) -> void:
	draw_circle(Vector2.ZERO, 14, color)


func death_spawns() -> Array[EnemySpawnDefinition]:
	return []
## 空间占位用于出土/出生合法性，不参与攻击或难度决策。
func reserved_world_position()->Vector2:return global_position
