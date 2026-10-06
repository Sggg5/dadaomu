class_name Room
extends Node2D
## 所有普通房间共用的布局装配和战斗生命周期。
## 玩家不属于 Room；敌人与弹丸属于 Room，切换时一起释放。

signal traversal_requested(side: Door.Direction)
signal state_changed(status: RoomState.Status)
signal enemy_count_changed(count: int)
signal cleared

const DOOR_SCENE: PackedScene = preload("res://scenes/rooms/door.tscn")
const ROOM_RECT := Rect2(64, 144, 1152, 448)
const WALL_THICKNESS: float = 16.0

@export var definition: RoomDefinition
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var projectiles: Node2D = $Projectiles

var room_state: RoomState
var doors: Dictionary[int, Door] = {}
var _connected_sides: Array[int] = []
var _wall_rects: Array[Rect2] = []


func configure(data: RoomDefinition, state: RoomState, connected_sides: Array[int]) -> void:
	definition = data
	room_state = state
	_connected_sides = connected_sides.duplicate()


func _ready() -> void:
	assert(definition != null and room_state != null, "Room must be configured before entering tree")
	_build_geometry()
	room_state.changed.connect(_on_state_changed)
	enemy_spawner.remaining_changed.connect(func(count: int) -> void: enemy_count_changed.emit(count))
	enemy_spawner.all_defeated.connect(_on_all_defeated)


func enter() -> void:
	_set_doors_open(false)
	if room_state.status == RoomState.Status.CLEARED:
		_set_doors_open(true)
		return
	if definition.room_type != RoomDefinition.Type.COMBAT:
		push_error("Phase 2 only implements ordinary combat rooms")
		return
	room_state.activate()
	enemy_spawner.spawn(definition)


func get_entry_position(side: int = -1) -> Vector2:
	if side < 0:
		return ROOM_RECT.get_center()
	return _door_position(side) - Vector2.UP.rotated(side * PI * 0.5) * 64.0


func discard_projectiles() -> void:
	for child in projectiles.get_children():
		child.set_physics_process(false)
		child.queue_free()


func _on_all_defeated() -> void:
	if room_state.clear():
		cleared.emit()


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
