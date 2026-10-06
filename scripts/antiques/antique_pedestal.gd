class_name AntiquePedestal
extends Node2D
## 安全房一次性拾取；未领取可重访，claimed在RoomState中保留，丢弃不回补。
var definition: AntiqueDefinition
var player: Player
var room_state: RoomState
var label: Label
var failure_remaining: float = 0


func _ready() -> void:
	label = Label.new()
	label.position = Vector2(-200,26)
	label.size = Vector2(400,110)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",17)
	add_child(label)
	_refresh()


func in_range() -> bool:
	return not room_state.antique_claimed and is_instance_valid(player) and not player.health.is_dead and player.controls_enabled and player.global_position.distance_to(global_position) <= 64


func try_pickup() -> bool:
	if not in_range(): return false
	if not player.antiques.add(definition):
		failure_remaining = 2
		_refresh()
		return false
	room_state.antique_claimed = true
	queue_free()
	return true


func _process(delta: float) -> void:
	failure_remaining = maxf(0,failure_remaining-delta)
	_refresh()


func _refresh() -> void:
	label.text = "%s\n估值：%s\n占用：%d格\n%s" % [definition.display_name,AntiqueDefinition.money(definition.base_value),definition.slots,"背包空间不足" if failure_remaining > 0 else ("[E] 带走" if in_range() else "靠近后按 E 带走")]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo() and in_range():
		try_pickup()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_rect(Rect2(-22,-14,44,28),Color("567d82"))
	draw_circle(Vector2(0,-14),13,Color("efd8a2"))
	draw_arc(Vector2(0,-14),17,0,TAU,24,Color("abebe2"),2)
