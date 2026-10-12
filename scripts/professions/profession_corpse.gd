extends Node2D
## Nonblocking DRAFT predecessor, not an Enemy or normal item pickup.
var runtime: ProfessionRuntime
var faction_id: StringName
var source_key: StringName
var offer_equipment: Callable
var label: Label
func _ready() -> void:
	z_index = int(global_position.y)
	label = Label.new()
	label.position = Vector2(-150,-70)
	label.size = Vector2(300,64)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",16)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
func in_range() -> bool:
	return is_instance_valid(runtime) and runtime.world.player.global_position.distance_to(global_position) <= 64
func search() -> bool:
	if not in_range() or not runtime.available() or runtime.state.searched(source_key): return false
	var identity := {"faction_id":str(faction_id),"name":("执%s的无名前辈" if faction_id==&"XIELING" else "佩%s的无名前辈") % ProfessionRegistry.token_name(faction_id),"fiction":"DRAFT游戏身份记录，非真实历史人物","floor":runtime.world.floor_number,"room_id":str(runtime.world.current_id)}
	var duplicate := runtime.state.has_token(faction_id)
	if not runtime.state.search(source_key,faction_id,identity): return false
	runtime.notice = "已记录前辈身份 · " + ("重复信物不叠加" if duplicate else "获得" + ProfessionRegistry.token_name(faction_id))
	if not duplicate and offer_equipment.is_valid(): offer_equipment.call(faction_id)
	return true
func _process(_delta: float) -> void:
	label.text = ""
	if not in_range(): return
	label.text = "已搜索 · 身份记录存于本局信物簿" if runtime.state.searched(source_key) else "[E] 搜索" + ProfessionRegistry.display_name(faction_id) + "前辈遗体\n清房且安全时可搜索"
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo() and search(): get_viewport().set_input_as_handled()
func _draw() -> void:
	# Original simple cloth/bone silhouette; no collision rectangle or fake doorway.
	draw_set_transform(Vector2(0,8),0,Vector2(1,.4))
	draw_circle(Vector2.ZERO,27,Color(0,0,0,.25));draw_set_transform(Vector2.ZERO)
	var colors := {&"MOJIN":Color("776444"),&"FAQIU":Color("526c68"),&"BANSHAN":Color("717853"),&"XIELING":Color("846352")}
	draw_colored_polygon(PackedVector2Array([Vector2(-22,-5),Vector2(-8,-12),Vector2(11,-8),Vector2(19,5),Vector2(7,10),Vector2(-17,8)]),colors[faction_id])
	draw_circle(Vector2(-24,-3),7,Color("c1b497"))
	draw_line(Vector2(-8,-4),Vector2(14,6),Color("ac9c77"),3)
	draw_line(Vector2(17,3),Vector2(32,9),Color("514a3c"),5)
	draw_line(Vector2(14,6),Vector2(28,16),Color("514a3c"),5)
