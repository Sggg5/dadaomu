class_name RoomMinimap
extends Control
## 按坐标包围盒缩放，只画真实连接，不把相邻位置猜成一扇门。

var _layout: DungeonLayout
var _states: Dictionary[StringName, RoomState] = {}
var _current_id: StringName


func update_map(layout: DungeonLayout, states: Dictionary[StringName, RoomState], current_id: StringName) -> void:
	_layout = layout
	_states = states
	_current_id = current_id
	queue_redraw()


func _draw() -> void:
	if _layout == null or _layout.rooms.is_empty():
		return
	var minimum := Vector2.ZERO
	var maximum := Vector2.ZERO
	for room in _layout.rooms.values():
		minimum = minimum.min(Vector2(room.coordinate))
		maximum = maximum.max(Vector2(room.coordinate))
	var span := maximum - minimum + Vector2.ONE
	var step := minf(30.0, minf((size.x - 12) / span.x, (size.y - 12) / span.y))
	var center := (minimum + maximum) * 0.5
	var cell_size := minf(20.0, step * 0.72)
	var font_size := maxi(6, mini(14, int(cell_size * 0.85)))
	for room in _layout.rooms.values():
		var position: Vector2 = size * 0.5 + (Vector2(room.coordinate) - center) * step
		for neighbor_id in room.neighbors.values():
			if str(room.room_id) < str(neighbor_id):
				var other: Vector2 = size * 0.5 + (Vector2(_layout.rooms[neighbor_id].coordinate) - center) * step
				draw_line(position, other, Color("69716e"), 2.0)
	for room in _layout.rooms.values():
		var position: Vector2 = size * 0.5 + (Vector2(room.coordinate) - center) * step
		var state := _states[room.room_id]
		var color := Color("343b45") if state.status == RoomState.Status.UNVISITED else Color("4b9e7d")
		var rect := Rect2(position - Vector2.ONE * cell_size * 0.5, Vector2.ONE * cell_size)
		draw_rect(rect, color)
		if room.room_id == _current_id:
			draw_rect(rect.grow(2), Color("f6d78d"), false, 2.0)
		var marker: String = ""
		match room.room_type:
			RoomDefinition.Type.START: marker = "S"
			RoomDefinition.Type.BOSS: marker = "B"
			RoomDefinition.Type.ANTIQUE: marker = "A"
		if not marker.is_empty():
			var font := ThemeDB.fallback_font
			var text_size := font.get_string_size(marker, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			draw_string(font, position + Vector2(-text_size.x * 0.5, font_size * 0.35), marker, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
