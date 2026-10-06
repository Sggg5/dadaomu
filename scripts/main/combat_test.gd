class_name CombatTest
extends Node2D
## Phase 1 固定测试场景，负责装配与 HUD，不是 Phase 2 的房间系统。
## 重开直接重载整场景，弹丸、角色和冷却均随旧场景释放。

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/player/projectile.tscn")
const ROOM_RECT := Rect2(64.0, 112.0, 1152.0, 496.0)
const WALL_THICKNESS: float = 16.0

@export_range(1.0, 1000.0) var test_damage: float = 25.0

@onready var player: Player = $Actors/Player
@onready var projectiles: Node2D = $Projectiles
@onready var hp_label: Label = $HUD/Root/HP
@onready var stats_label: Label = $HUD/Root/Stats
@onready var target_label: Label = $HUD/Root/Targets
@onready var status_label: Label = $HUD/Root/Status
@onready var damage_button: Button = $HUD/Root/DamageButton

var remaining_targets: int = 3
var restarting: bool = false


func _ready() -> void:
	_create_walls()
	player.weapon.attack_requested.connect(_spawn_projectile)
	player.health.changed.connect(_update_hp)
	player.died.connect(_on_player_died)
	for child in $Actors.get_children():
		if child is Dummy:
			child.killed.connect(_on_dummy_killed)
	damage_button.pressed.connect(apply_test_damage)
	$HUD/Root/RestartButton.pressed.connect(restart)
	$HUD/Root/QuitButton.pressed.connect(_quit)
	_update_hp(player.health.current_hp, player.health.max_hp)
	stats_label.text = "移速 %.0f  |  伤害 %.0f  |  攻速 %.1f 次/秒  |  弹速 %.0f" % [
		player.stats.move_speed, player.stats.attack_damage,
		player.stats.attack_speed, player.stats.projectile_speed]
	damage_button.text = "测试伤害 -%.0f HP [F1]" % test_damage
	_update_targets()
	print("[大盗墓时代] Phase 1 combat test ready")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("test_damage") and not event.is_echo():
		apply_test_damage()
	elif event.is_action_pressed("restart") and not event.is_echo():
		restart()
	elif event.is_action_pressed("quit"):
		_quit()


func apply_test_damage() -> void:
	player.take_damage(test_damage)


func restart() -> void:
	if restarting:
		return
	restarting = true
	# 按钮与输入都可能在处理回调中触发，延迟释放当前场景。
	get_tree().call_deferred("reload_current_scene")


func _quit() -> void:
	get_tree().quit()


func _spawn_projectile(request: AttackRequest) -> void:
	if player.health.is_dead:
		return
	var projectile := PROJECTILE_SCENE.instantiate() as Projectile
	projectiles.add_child(projectile)
	projectile.setup(request)


func _on_player_died() -> void:
	status_label.text = "你已倒下\n按 R 或点击“重新开始”"
	damage_button.disabled = true
	# 死亡立即结束这次测试战斗，不让已发射弹丸继续击杀靶子。
	for child in projectiles.get_children():
		child.set_physics_process(false)
		child.queue_free()


func _on_dummy_killed() -> void:
	remaining_targets -= 1
	_update_targets()
	if remaining_targets == 0 and not player.health.is_dead:
		status_label.text = "三个靶子已击破\n按 F1 测试受伤，或按 R 重开"


func _update_hp(current_hp: float, max_hp: float) -> void:
	hp_label.text = "生命  %.0f / %.0f" % [current_hp, max_hp]
	hp_label.modulate = Color("ff8277") if current_hp <= max_hp * 0.25 else Color.WHITE


func _update_targets() -> void:
	target_label.text = "固定靶  %d / 3" % remaining_targets


func _create_walls() -> void:
	var walls := StaticBody2D.new()
	walls.name = "TestWalls"
	walls.collision_layer = 1
	walls.collision_mask = 0
	add_child(walls)
	var center := ROOM_RECT.get_center()
	var half := WALL_THICKNESS * 0.5
	_add_wall(walls, Vector2(center.x, ROOM_RECT.position.y - half), Vector2(ROOM_RECT.size.x + 32, WALL_THICKNESS))
	_add_wall(walls, Vector2(center.x, ROOM_RECT.end.y + half), Vector2(ROOM_RECT.size.x + 32, WALL_THICKNESS))
	_add_wall(walls, Vector2(ROOM_RECT.position.x - half, center.y), Vector2(WALL_THICKNESS, ROOM_RECT.size.y))
	_add_wall(walls, Vector2(ROOM_RECT.end.x + half, center.y), Vector2(WALL_THICKNESS, ROOM_RECT.size.y))


func _add_wall(parent: StaticBody2D, wall_position: Vector2, size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = wall_position
	parent.add_child(collider)


func _draw() -> void:
	draw_rect(ROOM_RECT.grow(WALL_THICKNESS), Color("4f4b43"))
	draw_rect(ROOM_RECT, Color("20292c"))
	for x in range(96, 1216, 48):
		draw_line(Vector2(x, 112), Vector2(x, 608), Color("293336"))
	for y in range(128, 608, 48):
		draw_line(Vector2(64, y), Vector2(1216, y), Color("293336"))
	draw_rect(ROOM_RECT, Color("9b8c68"), false, 2.0)
