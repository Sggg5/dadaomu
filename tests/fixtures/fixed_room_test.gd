extends RoomController
## 原始十字图仅留在回归夹具。生产控制器消费统一注入的 Layout。

const SOURCES: Array[RoomDefinition] = [
	preload("res://data/rooms/test_center.tres"), preload("res://data/rooms/test_north.tres"),
	preload("res://data/rooms/test_west.tres"), preload("res://data/rooms/test_east.tres"),
	preload("res://data/rooms/test_south.tres"),
]
const CONNECTIONS: Dictionary = {
	&"center": {0: &"north", 1: &"east", 2: &"south", 3: &"west"},
	&"north": {2: &"center"}, &"east": {3: &"center"},
	&"south": {0: &"center"}, &"west": {1: &"center"},
}
const POSITIONS: Dictionary = {
	&"center": [Vector2(760, 244), Vector2(1000, 368), Vector2(760, 492)],
	&"north": [Vector2(440, 240), Vector2(840, 240), Vector2(440, 496), Vector2(840, 496)],
	&"west": [Vector2(350, 260), Vector2(870, 490)],
	&"east": [Vector2(300, 240), Vector2(950, 230), Vector2(360, 500), Vector2(1040, 500)],
	&"south": [Vector2(440, 240), Vector2(840, 240), Vector2(480, 496), Vector2(780, 496), Vector2(1000, 368)],
}


static func make_templates() -> Array[RoomDefinition]:
	# 保留旧五房布局/数量/60 HP 靶子的回归语义，仍走唯一的统一生成器。
	var templates: Array[RoomDefinition] = []
	for source in SOURCES:
		var template := source.duplicate() as RoomDefinition
		template.spawns = []
		for position in POSITIONS[source.room_id]:
			var entry := EnemySpawnDefinition.new()
			entry.enemy_scene = preload("res://scenes/enemies/dummy.tscn")
			entry.position = position
			template.spawns.append(entry)
		templates.append(template)
	return templates


func _enter_tree() -> void:
	layout = DungeonLayout.new()
	layout.start_id = &"center"
	for template in make_templates():
		var room := DungeonRoom.new()
		room.room_id = template.room_id
		room.coordinate = template.map_position
		room.definition = template
		room.distance_from_start = 0 if room.room_id == &"center" else 1
		room.neighbors.assign(CONNECTIONS[room.room_id])
		layout.add_room(room)
