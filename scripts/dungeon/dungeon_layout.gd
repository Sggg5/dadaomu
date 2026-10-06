class_name DungeonLayout
extends RefCounted
## 一次生成的纯结果。创建后按只读使用，RoomState 在控制器内单独维护。

const GENERATION_VERSION: int = 1

var seed_value: int = 0
var start_id: StringName = &"START"
var boss_id: StringName
var antique_id: StringName
var rooms: Dictionary[StringName, DungeonRoom] = {}
var coordinates: Dictionary[Vector2i, StringName] = {}


func add_room(room: DungeonRoom) -> void:
	assert(not rooms.has(room.room_id) and not coordinates.has(room.coordinate))
	rooms[room.room_id] = room
	coordinates[room.coordinate] = room.room_id


func connect_rooms(first_id: StringName, direction: int, second_id: StringName) -> void:
	assert(rooms[second_id].coordinate == rooms[first_id].coordinate + DungeonRoom.OFFSETS[direction])
	rooms[first_id].neighbors[direction] = second_id
	rooms[second_id].neighbors[(direction + 2) % 4] = first_id


func ordered_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(rooms.keys())
	# StringName 的默认排序不能作为跨进程的文本顺序契约，显式按字符串排序。
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return str(a) < str(b))
	return ids


func signature(include_templates: bool = true) -> String:
	# 排序后编码，不依赖字典散列/插入顺序；不包含 Seed，用于比较实际拓扑。
	var rows: Array = []
	for room_id in ordered_ids():
		var room := rooms[room_id]
		var connections: Array = []
		for direction in range(4):
			if room.neighbors.has(direction):
				connections.append([direction, str(room.neighbors[direction])])
		var row: Array = [str(room_id), room.coordinate.x, room.coordinate.y,
			room.room_type, room.distance_from_start, connections]
		if include_templates:
			row.append(str(room.definition.room_id))
			row.append(room.definition.resource_path)
		rows.append(row)
	return JSON.stringify([GENERATION_VERSION, str(start_id), str(boss_id), str(antique_id), rows])


func spatial_signature() -> String:
	# 忽略创建顺序/ID，仅比较坐标、类型与连边；N 不会仅因 ID 变化而判成新图。
	var cells: Array[Vector2i] = []
	cells.assign(coordinates.keys())
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	var rows: Array = []
	for cell in cells:
		var room := rooms[coordinates[cell]]
		var directions: Array[int] = []
		for direction in range(4):
			if room.neighbors.has(direction):
				directions.append(direction)
		rows.append([cell.x, cell.y, room.room_type, directions])
	return JSON.stringify(rows)
