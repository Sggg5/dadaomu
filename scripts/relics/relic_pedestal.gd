class_name RelicPedestal
extends Node2D
## 当前房一次性奖励；离房未领取则丢失，不写地图/存档。
var definition: RelicDefinition
var player: Player
var claimed: bool = false
var room_state: RoomState
var source_id: StringName
var label: Label


static func safe_position(room: Room) -> Vector2:
	var center := Room.ROOM_RECT.get_center()
	for offset in [Vector2.ZERO, Vector2(0,-112), Vector2(160,0), Vector2(0,112), Vector2(-160,0)]:
		var point: Vector2 = center + offset
		if Room.ROOM_RECT.grow(-40).has_point(point) and room.obstacles().all(func(rect: Rect2) -> bool: return not rect.grow(40).has_point(point)):
			return point
	return room.get_entry_position(room.doors.keys()[0])


func _ready() -> void:
	label = Label.new()
	label.position = Vector2(-220, 25)
	label.size = Vector2(440, 70)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)


func _process(_delta: float) -> void:
	label.text = "%s\n%s\n%s" % [definition.display_name, definition.description, "[E] 拾取" if can_pickup() else "靠近后按 E 拾取"]
	queue_redraw()


func can_pickup() -> bool:
	return not claimed and is_instance_valid(player) and not player.health.is_dead and player.controls_enabled and player.global_position.distance_to(global_position) <= 64.0


func try_pickup() -> bool:
	if not can_pickup() or not player.relics.inventory.add(definition):
		return false
	claimed = true
	if room_state != null: room_state.claim_loot(source_id)
	queue_free()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo() and try_pickup():
		get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 18.0, Color("b19453"))
	draw_arc(Vector2.ZERO, 25.0, 0, TAU, 32, Color("ffe29b"), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(0,-12),Vector2(10,0),Vector2(0,12),Vector2(-10,0)]), Color("e8d8ad"))
