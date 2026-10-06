class_name RoomMinimap
extends Control
## 小地图只展示只读定义与状态，不控制房间转换。

var _definitions: Array[RoomDefinition] = []
var _states: Dictionary[StringName, RoomState] = {}
var _current_id: StringName


func update_map(definitions: Array[RoomDefinition], states: Dictionary[StringName, RoomState], current_id: StringName) -> void:
	_definitions = definitions
	_states = states
	_current_id = current_id
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	for first in _definitions:
		for second in _definitions:
			var delta := first.map_position - second.map_position
			if absi(delta.x) + absi(delta.y) == 1:
				draw_line(center + Vector2(first.map_position) * 30, center + Vector2(second.map_position) * 30, Color("69716e"), 2.0)
	for definition in _definitions:
		var state := _states[definition.room_id]
		var color := Color("4a515b")
		if state.status == RoomState.Status.ACTIVE:
			color = Color("c87e57")
		elif state.status == RoomState.Status.CLEARED:
			color = Color("4b9e7d")
		var rect := Rect2(center + Vector2(definition.map_position) * 30 - Vector2(10, 10), Vector2(20, 20))
		draw_rect(rect, color)
		if definition.room_id == _current_id:
			draw_rect(rect.grow(2), Color("f6d78d"), false, 2.0)
