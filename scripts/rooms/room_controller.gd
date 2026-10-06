class_name RoomController
extends Node2D
## 固定地图装配与切换。持有唯一玩家、五个状态及当前房间，不负责局部清场判定。
## 门请求后立即冻结输入，再延迟卸载房间，避免在物理查询中删除碰撞体。

signal room_changed(room_id: StringName)

const ROOM_SCENE: PackedScene = preload("res://scenes/rooms/room.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/player/projectile.tscn")
const CONNECTIONS: Dictionary = {
	&"center": {Door.Direction.NORTH: &"north", Door.Direction.EAST: &"east", Door.Direction.SOUTH: &"south", Door.Direction.WEST: &"west"},
	&"north": {Door.Direction.SOUTH: &"center"},
	&"east": {Door.Direction.WEST: &"center"},
	&"south": {Door.Direction.NORTH: &"center"},
	&"west": {Door.Direction.EAST: &"center"},
}

@export var definitions: Array[RoomDefinition] = []

@onready var player: Player = $Player
@onready var hud: RoomTestHUD = $HUD

var states: Dictionary[StringName, RoomState] = {}
var current_room: Room
var current_id: StringName
var transitioning: bool = false
var _definitions_by_id: Dictionary[StringName, RoomDefinition] = {}
var _restarting: bool = false


func _ready() -> void:
	for definition in definitions:
		assert(definition != null and definition.room_type == RoomDefinition.Type.COMBAT, "Only combat room definitions are supported")
		assert(CONNECTIONS.has(definition.room_id) and not _definitions_by_id.has(definition.room_id), "Room IDs must match fixed map and be unique")
		assert(definition.enemy_scene != null, "Room requires enemy scene")
		_definitions_by_id[definition.room_id] = definition
		states[definition.room_id] = RoomState.new()
	assert(states.size() == CONNECTIONS.size(), "Fixed map requires five room definitions")
	player.weapon.attack_requested.connect(_spawn_projectile)
	player.health.changed.connect(hud.show_hp)
	player.died.connect(_on_player_died)
	hud.damage_requested.connect(apply_test_damage)
	hud.restart_requested.connect(restart)
	hud.quit_requested.connect(_quit)
	hud.show_hp(player.health.current_hp, player.health.max_hp)
	_switch_room(&"center", -1)
	print("[大盗墓时代] Phase 2 fixed five-room test ready")


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
	get_tree().call_deferred("reload_current_scene")


func _quit() -> void:
	get_tree().quit()


func request_traversal(side: int) -> bool:
	if transitioning or _restarting or player.health.is_dead or current_room == null:
		return false
	if current_room.room_state.status != RoomState.Status.CLEARED:
		return false
	var neighbors: Dictionary = CONNECTIONS[current_id]
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
	for side in CONNECTIONS[target_id]:
		sides.append(side)
	current_room.configure(_definitions_by_id[target_id], states[target_id], sides)
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
	hud.show_room(current_room.definition, current_room.room_state, current_room.enemy_spawner.get_remaining())
	hud.show_map(definitions, states, current_id)


func _on_player_died() -> void:
	player.set_controls_enabled(false)
	current_room.discard_projectiles()
	hud.show_death()
