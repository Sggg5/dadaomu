extends RoomController
## 原始十字图仅留在回归夹具。生产控制器消费统一注入的 Layout。

const TEMPLATES: Array[RoomDefinition] = [
	preload("res://data/rooms/test_center.tres"), preload("res://data/rooms/test_north.tres"),
	preload("res://data/rooms/test_west.tres"), preload("res://data/rooms/test_east.tres"),
	preload("res://data/rooms/test_south.tres"),
]
const CONNECTIONS: Dictionary = {
	&"center": {0: &"north", 1: &"east", 2: &"south", 3: &"west"},
	&"north": {2: &"center"}, &"east": {3: &"center"},
	&"south": {0: &"center"}, &"west": {1: &"center"},
}


func _enter_tree() -> void:
	layout = DungeonLayout.new()
	layout.start_id = &"center"
	for template in TEMPLATES:
		var room := DungeonRoom.new()
		room.room_id = template.room_id
		room.coordinate = template.map_position
		room.definition = template
		room.distance_from_start = 0 if room.room_id == &"center" else 1
		room.neighbors.assign(CONNECTIONS[room.room_id])
		layout.add_room(room)
