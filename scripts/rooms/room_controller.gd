class_name RoomController
extends Node2D
## 消费注入的 DungeonLayout，持有唯一玩家和各房状态，不负责生成算法。
## 门请求后立即冻结输入，再延迟卸载房间，避免在物理查询中删除碰撞体。

signal room_changed(room_id: StringName)
signal restart_requested

const ROOM_SCENE: PackedScene = preload("res://scenes/rooms/room.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/player/projectile.tscn")
var layout: DungeonLayout

@onready var player: Player = $Player
@onready var hud: RoomTestHUD = $HUD

var states: Dictionary[StringName, RoomState] = {}
var current_room: Room
var current_id: StringName
var transitioning: bool = false
var _restarting: bool = false


func _ready() -> void:
	assert(layout != null and layout.rooms.has(layout.start_id), "Inject a DungeonLayout before adding RoomController")
	for room_id in layout.rooms:
		assert(layout.rooms[room_id].definition != null)
		states[room_id] = RoomState.new()
	player.weapon.attack_requested.connect(_spawn_projectile)
	player.health.changed.connect(hud.show_hp)
	player.died.connect(_on_player_died)
	hud.damage_requested.connect(apply_test_damage)
	hud.restart_requested.connect(restart)
	hud.quit_requested.connect(_quit)
	hud.show_hp(player.health.current_hp, player.health.max_hp)
	_switch_room(layout.start_id, -1)
	print("[大盗墓时代] Dungeon ready: Seed %d, %d rooms" % [layout.seed_value, layout.rooms.size()])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("test_damage") and not event.is_echo():
		apply_test_damage()
	elif event.is_action_pressed("restart") and not event.is_echo():
		restart()
	elif event.is_action_pressed("quit"):
		_quit()


func apply_test_damage() -> void:
	if not transitioning:
		player.take_damage(25.0)


func restart() -> void:
	if _restarting:
		return
	_restarting = true
	player.set_controls_enabled(false)
	if restart_requested.has_connections():
		restart_requested.emit()
	else:
		# 独立回归夹具重新注入固定图，生产入口由 Session 接管。
		get_tree().call_deferred("reload_current_scene")


func _quit() -> void:
	get_tree().quit()


func request_traversal(side: int) -> bool:
	if transitioning or _restarting or player.health.is_dead or current_room == null:
		return false
	if current_room.room_state.status != RoomState.Status.CLEARED:
		return false
	var neighbors: Dictionary[int, StringName] = layout.rooms[current_id].neighbors
	if not neighbors.has(side) or not current_room.doors[side].is_open:
		return false
	transitioning = true
	player.set_controls_enabled(false)
	_switch_room.call_deferred(neighbors[side], Door.opposite(side))
	return true


func _switch_room(target_id: StringName, entry_side: int) -> void:
	if player.health.is_dead or _restarting:
		transitioning = false
		return
	if is_instance_valid(current_room):
		current_room.process_mode = Node.PROCESS_MODE_DISABLED
		$RoomHost.remove_child(current_room)
		current_room.queue_free()
	current_id = target_id
	current_room = ROOM_SCENE.instantiate() as Room
	var sides: Array[int] = []
	var node := layout.rooms[target_id]
	for side in node.neighbors:
		sides.append(side)
	current_room.configure(node.definition, states[target_id], sides, node.room_type, player)
	current_room.traversal_requested.connect(request_traversal)
	current_room.state_changed.connect(func(_status: RoomState.Status) -> void: _refresh_hud())
	current_room.enemy_count_changed.connect(func(_count: int) -> void: _refresh_hud())
	$RoomHost.add_child(current_room)
	player.global_position = current_room.to_global(current_room.get_entry_position(entry_side))
	player.velocity = Vector2.ZERO
	current_room.enter()
	transitioning = false
	player.set_controls_enabled(true)
	_refresh_hud()
	room_changed.emit(current_id)


func _spawn_projectile(request: AttackRequest) -> void:
	if transitioning or player.health.is_dead or _restarting:
		return
	var projectile := PROJECTILE_SCENE.instantiate() as Projectile
	current_room.projectiles.add_child(projectile)
	projectile.setup(request)


func _refresh_hud() -> void:
	hud.show_room(layout.rooms[current_id], current_room.room_state, current_room.enemy_spawner.get_remaining())
	hud.show_map(layout, states, current_id)


func _on_player_died() -> void:
	player.set_controls_enabled(false)
	current_room.stop_combat()
	hud.show_death()
