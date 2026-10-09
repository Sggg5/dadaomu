class_name Player
extends CharacterBody2D
## 控制输入与移动；生命、武器各自持有状态。外部通过信号监听死亡。

signal died

@export var stats: PlayerStats

@onready var health: Health = $Health
@onready var weapon: RangedWeapon = $Weapon
@onready var relics: RelicRuntime = $Relics

var encounter_movement_modifiers:Dictionary[int,float]={}
var environment_speed_multiplier: float = 1.0
var aim_direction: Vector2 = Vector2.RIGHT
var invulnerability_remaining: float = 0.0
var mouse_viewport_position: Vector2 = Vector2.ZERO
var controls_enabled: bool = true
var antiques: AntiqueInventory = AntiqueInventory.new()


var art_visual: PlayerVisual

func _ready() -> void:
	art_visual = PlayerVisual.new()
	art_visual.actor = self
	add_child(art_visual)
	assert(stats != null, "Player requires PlayerStats")
	health.died.connect(_on_died)
	health.initialize(stats.max_hp)
	relics.configure(health, weapon)
	mouse_viewport_position = get_viewport().get_mouse_position()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		mouse_viewport_position = event.position


func _physics_process(delta: float) -> void:
	invulnerability_remaining = maxf(0.0, invulnerability_remaining - delta)
	if health.is_dead or not controls_enabled:
		return
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var encounter_factor:=1.0
	for value in encounter_movement_modifiers.values():encounter_factor=minf(encounter_factor,value)
	var change_rate := stats.deceleration if input_direction.is_zero_approx() else stats.acceleration
	velocity = velocity.move_toward(input_direction * stats.move_speed * encounter_factor * environment_speed_multiplier * relics.movement_multiplier(), change_rate * delta)
	move_and_slide()
	# 输入采样与物理步分离；每帧转为世界坐标，移动中仍瞄准同一鼠标位置。
	var mouse_world_position := get_canvas_transform().affine_inverse() * mouse_viewport_position
	var mouse_offset := mouse_world_position - global_position
	if not mouse_offset.is_zero_approx():
		aim_direction = mouse_offset.normalized()
	if Input.is_action_pressed("attack") and get_viewport().gui_get_hovered_control() == null:
		# 从身体中心发射，物理掩码排除玩家；避免靠墙时枪口跳到墙外。
		weapon.try_attack(global_position, aim_direction, stats)
	queue_redraw()


func take_damage(amount: float) -> bool:
	if invulnerability_remaining > 0.0 or health.is_dead:
		return false
	if not health.take_damage(relics.received_damage(amount)):
		return false
	invulnerability_remaining = stats.hurt_invulnerability
	queue_redraw()
	return true


func set_controls_enabled(value: bool) -> void:
	# 场景切换期间停止移动与攻击，但保留生命、属性和武器冷却。
	controls_enabled = value
	velocity = Vector2.ZERO
	weapon.set_physics_process(value and not health.is_dead)


func _on_died() -> void:
	velocity = Vector2.ZERO
	weapon.set_physics_process(false)
	queue_redraw()
	died.emit()


func _draw() -> void:
	if ArtRenderSettings.active() and ArtAssetCatalog.texture("actors") != null:
		draw_line(aim_direction * 10.0, aim_direction * 30.0, Color("f0dfae"), 3.0)
		return
	var color := Color("69c9c3")
	if is_instance_valid(health) and health.is_dead:
		color = Color("606775")
	elif invulnerability_remaining > 0.0:
		color = Color("ff8277")
	draw_circle(Vector2.ZERO, 16.0, color)
	draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 32, Color("cbe7da"), 2.0)
	draw_line(aim_direction * 10.0, aim_direction * 30.0, Color("f0dfae"), 6.0)
