class_name DungeonRoom
extends RefCounted
## 拓扑节点与视觉模板分离；不持有场景节点或运行时清场状态。

const OFFSETS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var room_id: StringName
var coordinate: Vector2i
var room_type: RoomDefinition.Type = RoomDefinition.Type.COMBAT
var neighbors: Dictionary[int, StringName] = {}
var distance_from_start: int = 0
var definition: RoomDefinition
