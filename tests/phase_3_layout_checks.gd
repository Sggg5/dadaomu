extends RefCounted
## 独立 BFS 重算最短距离，不信任生成器写入的 distance_from_start。


static func inspect(layout: DungeonLayout, config: DungeonConfig) -> Dictionary[String, bool]:
	var checks: Dictionary[String, bool] = {}
	checks["count_8_to_12"] = layout.rooms.size() >= 8 and layout.rooms.size() <= 12
	checks["unique_coordinates"] = layout.coordinates.size() == layout.rooms.size()
	checks["reciprocal_cardinal_connections"] = true
	checks["template_reference"] = true
	var types: Dictionary[int, int] = {}
	var occupied: Dictionary[Vector2i, bool] = {}
	var edge_count: int = 0
	var offsets: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	for room_id in layout.rooms:
		var room := layout.rooms[room_id]
		checks["unique_coordinates"] = checks["unique_coordinates"] and not occupied.has(room.coordinate) and layout.coordinates.get(room.coordinate) == room_id
		occupied[room.coordinate] = true
		types[room.room_type] = types.get(room.room_type, 0) + 1
		checks["template_reference"] = checks["template_reference"] and room.room_id == room_id and room.definition in config.templates
		for direction in room.neighbors:
			edge_count += 1
			var neighbor_id := room.neighbors[direction]
			if direction < 0 or direction > 3 or not layout.rooms.has(neighbor_id):
				checks["reciprocal_cardinal_connections"] = false
				continue
			var neighbor := layout.rooms[neighbor_id]
			checks["reciprocal_cardinal_connections"] = checks["reciprocal_cardinal_connections"] and neighbor.neighbors.get((direction + 2) % 4) == room_id and neighbor.coordinate == room.coordinate + offsets[direction]
	checks["one_START"] = types.get(RoomDefinition.Type.START, 0) == 1 and layout.start_id == &"START" and layout.rooms[layout.start_id].coordinate == Vector2i.ZERO and layout.rooms[layout.start_id].room_type == RoomDefinition.Type.START
	checks["one_BOSS"] = types.get(RoomDefinition.Type.BOSS, 0) == 1 and layout.rooms[layout.boss_id].room_type == RoomDefinition.Type.BOSS
	checks["one_ANTIQUE"] = types.get(RoomDefinition.Type.ANTIQUE, 0) == 1 and layout.rooms[layout.antique_id].room_type == RoomDefinition.Type.ANTIQUE
	checks["remaining_COMBAT"] = types.get(RoomDefinition.Type.COMBAT, 0) == layout.rooms.size() - 3
	var distances: Dictionary[StringName, int] = {layout.start_id: 0}
	var queue: Array[StringName] = [layout.start_id]
	var index: int = 0
	while index < queue.size():
		var room_id := queue[index]
		index += 1
		for neighbor_id in layout.rooms[room_id].neighbors.values():
			if not distances.has(neighbor_id) and layout.rooms.has(neighbor_id):
				distances[neighbor_id] = distances[room_id] + 1
				queue.append(neighbor_id)
	checks["all_reachable"] = distances.size() == layout.rooms.size()
	checks["tree_without_cycles"] = edge_count == 2 * (layout.rooms.size() - 1) and checks["all_reachable"]
	checks["boss_depth_at_least_5"] = distances.get(layout.boss_id, -1) >= config.min_boss_distance
	checks["boss_deepest_leaf"] = layout.rooms[layout.boss_id].neighbors.size() == 1 and distances.get(layout.boss_id, -1) == distances.values().max()
	checks["antique_depth_at_least_2"] = distances.get(layout.antique_id, -1) >= config.min_antique_distance and layout.antique_id != layout.start_id and layout.antique_id != layout.boss_id
	checks["cached_distances_match_BFS"] = true
	for room_id in layout.rooms:
		checks["cached_distances_match_BFS"] = checks["cached_distances_match_BFS"] and layout.rooms[room_id].distance_from_start == distances.get(room_id, -1)
	return checks
