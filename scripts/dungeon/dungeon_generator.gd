class_name DungeonGenerator
extends RefCounted
## 构造式树：先生成足够深的单调主路径，再随机扩展合法边。
## 只操作数据和独立 RNG，不实例化 Room，不读全局随机状态。


static func generate(seed_value: int, config: DungeonConfig) -> DungeonLayout:
	if config == null or not config.validation_error().is_empty():
		push_error("Invalid DungeonConfig")
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var layout := DungeonLayout.new()
	layout.seed_value = seed_value
	var start := DungeonRoom.new()
	start.room_id = layout.start_id
	start.coordinate = Vector2i.ZERO
	start.room_type = RoomDefinition.Type.START
	layout.add_room(start)
	var count := rng.randi_range(config.min_rooms, config.max_rooms)
	var primary := rng.randi_range(0, 3)
	var secondary := (primary + 1 + 2 * rng.randi_range(0, 1)) % 4
	var tip := start.room_id
	# 两个正交的单调方向保证无碰撞、无环，且必然达到要求深度，无需重试。
	for depth in range(config.min_terminal_distance):
		var direction := primary if rng.randi_range(0, 1) == 0 else secondary
		tip = _append_room(layout, tip, direction)
	for index in range(count - layout.rooms.size()):
		var candidates := _frontier(layout)
		# 有限格集在极值方向总能扩展；仍保留显式失败出口。
		if candidates.is_empty():
			push_error("Dungeon frontier unexpectedly empty")
			return null
		var edge: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
		_append_room(layout, edge["parent"], edge["direction"])
	_assign_special_rooms(layout, config, rng)
	for room_id in layout.ordered_ids():
		layout.rooms[room_id].definition = config.templates[rng.randi_range(0, config.templates.size() - 1)]
	return layout


static func _append_room(layout: DungeonLayout, parent_id: StringName, direction: int) -> StringName:
	var room := DungeonRoom.new()
	room.room_id = StringName("ROOM_%03d" % layout.rooms.size())
	room.coordinate = layout.rooms[parent_id].coordinate + DungeonRoom.OFFSETS[direction]
	room.distance_from_start = layout.rooms[parent_id].distance_from_start + 1
	layout.add_room(room)
	layout.connect_rooms(parent_id, direction, room.room_id)
	return room.room_id


static func _frontier(layout: DungeonLayout) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for room_id in layout.ordered_ids():
		for direction in range(4):
			var coordinate := layout.rooms[room_id].coordinate + DungeonRoom.OFFSETS[direction]
			if layout.coordinates.has(coordinate):
				continue
			var occupied_neighbors: int = 0
			for offset in DungeonRoom.OFFSETS:
				if layout.coordinates.has(coordinate + offset):
					occupied_neighbors += 1
			# 新格只邻接一个已有格，不产生环或看似相邻却没有门的接触。
			if occupied_neighbors == 1:
				candidates.append({"parent": room_id, "direction": direction})
	return candidates


static func _assign_special_rooms(layout: DungeonLayout, config: DungeonConfig, rng: RandomNumberGenerator) -> void:
	var deepest: int = -1
	var terminal_candidates: Array[StringName] = []
	for room_id in layout.ordered_ids():
		var room := layout.rooms[room_id]
		if room_id == layout.start_id or room.neighbors.size() != 1:
			continue
		if room.distance_from_start > deepest:
			deepest = room.distance_from_start
			terminal_candidates.clear()
		if room.distance_from_start == deepest:
			terminal_candidates.append(room_id)
	assert(deepest >= config.min_terminal_distance)
	layout.terminal_id = terminal_candidates[rng.randi_range(0, terminal_candidates.size() - 1)]
	if config.terminal_is_boss:
		layout.boss_id = layout.terminal_id
		layout.rooms[layout.terminal_id].room_type = RoomDefinition.Type.BOSS
	var antique_candidates: Array[StringName] = []
	for room_id in layout.ordered_ids():
		if room_id != layout.start_id and room_id != layout.terminal_id and layout.rooms[room_id].distance_from_start >= config.min_antique_distance:
			antique_candidates.append(room_id)
	assert(not antique_candidates.is_empty())
	layout.antique_id = antique_candidates[rng.randi_range(0, antique_candidates.size() - 1)]
	layout.rooms[layout.antique_id].room_type = RoomDefinition.Type.ANTIQUE
	if config.include_relic_room:
		var relic_candidates: Array[StringName] = []
		for id in layout.ordered_ids():
			if id != layout.terminal_id and layout.rooms[id].room_type == RoomDefinition.Type.COMBAT: relic_candidates.append(id)
		assert(not relic_candidates.is_empty())
		layout.relic_id = relic_candidates[rng.randi_range(0, relic_candidates.size()-1)]
		layout.rooms[layout.relic_id].room_type = RoomDefinition.Type.RELIC
