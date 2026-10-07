class_name Room
extends Node2D
## 所有普通房间共用的布局装配和战斗生命周期。
## 玩家不属于 Room；敌人与弹丸属于 Room，切换时一起释放。

signal traversal_requested(side: Door.Direction)
signal state_changed(status: RoomState.Status)
signal enemy_count_changed(count: int)
signal cleared
signal boss_started(boss: Enemy)
signal floor_exit_requested
signal run_complete_requested
signal boss_defeated
signal extraction_requested

const DOOR_SCENE: PackedScene = preload("res://scenes/rooms/door.tscn")
const ROOM_RECT := Rect2(64, 144, 1152, 448)
const WALL_THICKNESS: float = 16.0

@export var definition: RoomDefinition
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var projectiles: Node2D = $Projectiles

var room_state: RoomState
var room_type: RoomDefinition.Type = RoomDefinition.Type.COMBAT
var combat_target: Player
var difficulty: EncounterDifficulty = EncounterDifficulty.from_depth(0)
var boss_definition: BossDefinition
var boss_encounter: BossEncounter
var final_floor: bool = false
var is_terminal: bool = false
var rest_amount: int = 0
var next_floor_number: int = 2
var next_floor_name: String = ""
var antique_definition: AntiqueDefinition
var cache_definition: AntiqueDefinition
var risk_content: TombRiskContent
var route_warning_sides: Array[int] = []
var can_exit: Callable
var doors: Dictionary[int, Door] = {}
var _connected_sides: Array[int] = []
var _wall_rects: Array[Rect2] = []


func configure(data: RoomDefinition, state: RoomState, connected_sides: Array[int], type: RoomDefinition.Type = RoomDefinition.Type.COMBAT, player: Player = null, encounter: EncounterDifficulty = null) -> void:
	definition = data
	room_state = state
	room_type = type
	combat_target = player
	if encounter != null:
		difficulty = encounter
	_connected_sides = connected_sides.duplicate()


func _ready() -> void:
	assert(definition != null and room_state != null, "Room must be configured before entering tree")
	_build_geometry()
	enemy_spawner.target = combat_target
	enemy_spawner.difficulty = difficulty
	enemy_spawner.projectile_parent = projectiles
	room_state.changed.connect(_on_state_changed)
	enemy_spawner.remaining_changed.connect(func(count: int) -> void: enemy_count_changed.emit(count))
	enemy_spawner.all_defeated.connect(_on_all_defeated)


func enter() -> void:
	_set_doors_open(false)
	if room_state.status == RoomState.Status.CLEARED:
		_set_doors_open(true)
		_create_antique()
		_create_cache()
		if is_terminal: _create_terminal_exit()
		return
	if room_type not in [RoomDefinition.Type.COMBAT, RoomDefinition.Type.START, RoomDefinition.Type.BOSS, RoomDefinition.Type.ANTIQUE, RoomDefinition.Type.TRAP, RoomDefinition.Type.SECRET, RoomDefinition.Type.RELIC]:
		push_error("This room type has no entry policy yet")
		return
	room_state.activate()
	# START安全清场；ANTIQUE安全开门并放古董；正式BOSS由数据场景装配。
	if room_type in [RoomDefinition.Type.START, RoomDefinition.Type.ANTIQUE, RoomDefinition.Type.TRAP, RoomDefinition.Type.SECRET, RoomDefinition.Type.RELIC]:
		_on_all_defeated()
		_create_antique()
		return
	if room_type == RoomDefinition.Type.BOSS and boss_definition != null:
		if is_instance_valid(boss_encounter): return
		boss_encounter = BossEncounter.new()
		boss_encounter.room = self
		boss_encounter.definition = boss_definition
		boss_encounter.defeated.connect(_boss_defeated)
		boss_encounter.enemy_killed.connect(combat_target.relics.notify_enemy_killed)
		boss_encounter.remaining_changed.connect(func(count: int) -> void: enemy_count_changed.emit(count))
		add_child(boss_encounter)
		boss_encounter.start()
		boss_started.emit(boss_encounter.boss)
		return
	enemy_spawner.spawn(definition)


func get_entry_position(side: int = -1) -> Vector2:
	if side < 0:
		# 安全房也会抽到障碍模板，出生点不能落进中央障碍。
		var center := ROOM_RECT.get_center()
		for offset in [Vector2.ZERO,Vector2(0,-112),Vector2(256,0),Vector2(-256,0),Vector2(0,112)]:
			var point: Vector2 = center+offset
			if definition.obstacles.all(func(rect: Rect2) -> bool: return not rect.grow(20).has_point(point)): return point
		return center
	return _door_position(side) - Vector2.UP.rotated(side * PI * 0.5) * 64.0


func _create_antique() -> void:
	if room_type != RoomDefinition.Type.ANTIQUE or antique_definition == null or room_state.is_loot_claimed(&"antique_room") or has_node("AntiquePedestal"): return
	var pedestal := AntiquePedestal.new()
	pedestal.name = "AntiquePedestal"
	pedestal.definition = antique_definition
	pedestal.player = combat_target
	pedestal.room_state = room_state
	pedestal.position = RelicPedestal.safe_position(self)
	add_child(pedestal)


func _create_cache() -> void:
	if room_type != RoomDefinition.Type.COMBAT or cache_definition == null or room_state.status != RoomState.Status.CLEARED or room_state.is_loot_claimed(&"combat_cache") or has_node("AntiqueCache"): return
	var cache := AntiqueCache.new()
	cache.name = "AntiqueCache"
	cache.definition = cache_definition
	cache.player = combat_target
	cache.room_state = room_state
	cache.position = AntiqueCache.safe_position(self)
	add_child(cache)


func discard_projectiles() -> void:
	for child in projectiles.get_children():
		child.set_physics_process(false)
		child.queue_free()


func stop_combat() -> void:
	if is_instance_valid(risk_content): risk_content.stop()
	if is_instance_valid(boss_encounter): boss_encounter.stop()
	enemy_spawner.stop_all()
	discard_projectiles()


func _boss_defeated() -> void:
	boss_defeated.emit()
	_on_all_defeated()
	_create_terminal_exit()


func _create_terminal_exit() -> void:
	if rest_amount > 0 and not final_floor and not room_state.is_loot_claimed(&"rest_point") and not has_node("RestPoint"):
		var rest := RestPoint.new()
		rest.name = "RestPoint"
		rest.player = combat_target
		rest.room_state = room_state
		rest.amount = rest_amount
		rest.can_use = can_exit
		rest.position = RestPoint.safe_position(self)
		add_child(rest)
	if final_floor:
		if has_node("RunExit"): return
		var run_exit := RunExit.new()
		run_exit.name = "RunExit"
		run_exit.player = combat_target
		run_exit.position = RelicPedestal.safe_position(self)
		run_exit.run_complete_requested.connect(func() -> void: run_complete_requested.emit())
		add_child(run_exit)
		return
	if has_node("ExpeditionExit"): return
	var exit := ExpeditionExit.new()
	exit.name = "ExpeditionExit"
	exit.can_choose = can_exit
	exit.next_floor_number = next_floor_number
	exit.next_floor_name = next_floor_name
	exit.player = combat_target
	exit.position = RelicPedestal.safe_position(self)
	exit.descend_requested.connect(func() -> void: floor_exit_requested.emit())
	exit.extract_requested.connect(func() -> void: extraction_requested.emit())
	add_child(exit)


func damage_targets() -> Array[Node2D]:
	var result: Array[Node2D] = []
	result.assign(enemy_spawner.get_children())
	if is_instance_valid(boss_encounter): result.append_array(boss_encounter.targets())
	if is_instance_valid(risk_content): result.append_array(risk_content.targets())
	return result


func remaining_count() -> int:
	return (boss_encounter.targets().size() if is_instance_valid(boss_encounter) else enemy_spawner.get_remaining()) + (risk_content.remaining() if is_instance_valid(risk_content) else 0)


func _on_all_defeated() -> void:
	if room_state.clear():
		cleared.emit()
		_create_cache()
		if is_terminal: _create_terminal_exit()


func _on_state_changed(value: RoomState.Status) -> void:
	_set_doors_open(value == RoomState.Status.CLEARED)
	state_changed.emit(value)


func _set_doors_open(value: bool) -> void:
	for door in doors.values():
		door.set_open(value)


func _door_position(side: int) -> Vector2:
	var center := ROOM_RECT.get_center()
	match side:
		Door.Direction.NORTH: return Vector2(center.x, ROOM_RECT.position.y)
		Door.Direction.EAST: return Vector2(ROOM_RECT.end.x, center.y)
		Door.Direction.SOUTH: return Vector2(center.x, ROOM_RECT.end.y)
		_: return Vector2(ROOM_RECT.position.x, center.y)


func _build_geometry() -> void:
	var walls := StaticBody2D.new()
	walls.name = "Walls"
	walls.collision_layer = 1
	walls.collision_mask = 0
	add_child(walls)
	for side in range(4):
		_build_edge(walls, side, side in _connected_sides)
		if side in _connected_sides:
			var door := DOOR_SCENE.instantiate() as Door
			door.side = side as Door.Direction
			door.position = _door_position(side)
			door.rotation = side * PI * 0.5
			door.traversal_requested.connect(func(value: Door.Direction) -> void: traversal_requested.emit(value))
			$Doors.add_child(door)
			doors[side] = door
	for rect in definition.obstacles:
		_add_block(walls, rect)
	queue_redraw()


func _build_edge(walls: StaticBody2D, side: int, has_door: bool) -> void:
	var horizontal := side == Door.Direction.NORTH or side == Door.Direction.SOUTH
	var length := ROOM_RECT.size.x if horizontal else ROOM_RECT.size.y
	var outward := Vector2.UP.rotated(side * PI * 0.5)
	var edge_center := _door_position(side) + outward * WALL_THICKNESS * 0.5
	var axis := Vector2.RIGHT if horizontal else Vector2.DOWN
	if not has_door:
		var size := Vector2(length, WALL_THICKNESS) if horizontal else Vector2(WALL_THICKNESS, length)
		_add_block(walls, Rect2(edge_center - size * 0.5, size))
		return
	var segment := (length - Door.WIDTH) * 0.5
	var size := Vector2(segment, WALL_THICKNESS) if horizontal else Vector2(WALL_THICKNESS, segment)
	for sign_value in [-1.0, 1.0]:
		var center: Vector2 = edge_center + axis * sign_value * (Door.WIDTH + segment) * 0.5
		_add_block(walls, Rect2(center - size * 0.5, size))


func _add_block(walls: StaticBody2D, rect: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = rect.get_center()
	walls.add_child(collider)
	_wall_rects.append(rect)


func _draw() -> void:
	if definition == null:
		return
	draw_rect(ROOM_RECT, definition.floor_color)
	for x in range(64, 1216, 48):
		draw_line(Vector2(x, 144), Vector2(x, 592), Color(1, 1, 1, 0.035))
	for y in range(144, 592, 48):
		draw_line(Vector2(64, y), Vector2(1216, y), Color(1, 1, 1, 0.035))
	for rect in _wall_rects:
		draw_rect(rect, Color("4f4b43"))
		draw_rect(rect, Color("9b8c68"), false, 2.0)
	for side in route_warning_sides:
		var point := get_entry_position(side)
		draw_circle(point + Vector2(22, 0), 8, Color("78382f"))
		draw_line(point + Vector2(-30, 10), point + Vector2(25, -8), Color("a35b4c"), 3)
	if room_type == RoomDefinition.Type.TRAP:
		# 只作风险路线环境表达：断裂棺木、擦痕和机关孔，不引入额外伤害机制。
		for offset in [Vector2.ZERO, Vector2(22, 18), Vector2(-18, 26)]:
			draw_line(Vector2(740, 330) + offset, Vector2(790, 348) + offset, Color("675349"), 5)
		for x in range(480, 720, 48):
			draw_circle(Vector2(x, 164), 3, Color("101416"))
		draw_line(Vector2(760, 360), Vector2(840, 390), Color("6b352e"), 3)
