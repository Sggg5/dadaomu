class_name TombRiskInteractable
extends Node2D
## 同一交互的两次E：打开风险说明→确认。Tab取消；确认前不结算。
var content: TombRiskContent
var event: TombRiskEvent
var label: Label
var confirmation: CanvasLayer
var confirming: bool = false

func _ready() -> void:
	label = Label.new()
	label.position = Vector2(-95, 26)
	label.size = Vector2(190, 90)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

func in_range() -> bool:
	return content.available() and content.room.combat_target.global_position.distance_to(global_position) <= 64

func _process(_delta: float) -> void:
	var resolved := content.service.results.has(content.source(event))
	label.text = event.display_name + ("\n已探查" if resolved else ("\n[E] 检查" if in_range() else ""))
	if resolved and not content.service.results[content.source(event)].antique_ids.is_empty(): label.text = ""
	if confirming and not content.available(): close()

func _unhandled_input(input: InputEvent) -> void:
	if input.is_action_pressed("interact") and not input.is_echo() and not confirming and in_range() and not content.service.results.has(content.source(event)):
		open()
		get_viewport().set_input_as_handled()

func _input(input: InputEvent) -> void:
	if not confirming or not input is InputEventKey or not input.pressed or input.echo: return
	if input.physical_keycode == KEY_TAB:
		close()
		get_viewport().set_input_as_handled()
	elif input.physical_keycode == KEY_E:
		close()
		content.resolve(event, position)
		get_viewport().set_input_as_handled()

func open() -> void:
	if not in_range() or content.confirming: return
	confirming = true
	content.confirming = true
	content.room.combat_target.set_controls_enabled(false)
	confirmation = CanvasLayer.new()
	confirmation.layer = 40
	add_child(confirmation)
	var panel := PanelContainer.new()
	panel.position = Vector2(360, 220)
	panel.size = Vector2(560, 260)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("171c22")
	style.content_margin_left = 24
	style.content_margin_top = 24
	panel.add_theme_stylebox_override("panel", style)
	confirmation.add_child(panel)
	var text := Label.new()
	text.add_theme_font_size_override("font_size", 21)
	var warning := "里面似乎有东西。也可能惊动尸蟞、触发机关，或空无一物。"
	if event.kind == TombRiskEvent.Kind.ALTAR: warning = "取走供物：-15生命\n这份代价可能致命。"
	if event.kind == TombRiskEvent.Kind.HIDDEN_REWARD: warning = "偏殿封存的供物，仍占用随身背包。"
	text.text = "%s\n\n%s\n\n携货 %d / 8格 · 估值 %s\n[E] 确认  [Tab] 放弃" % [event.display_name, warning, content.room.combat_target.antiques.used_slots(), AntiqueDefinition.money(content.room.combat_target.antiques.total_value())]
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(text)

func close() -> void:
	confirming = false
	content.confirming = false
	if is_instance_valid(confirmation): confirmation.queue_free()
	if not content.room.combat_target.health.is_dead and content.room.can_exit.call(): content.room.combat_target.set_controls_enabled(true)

func _draw() -> void:
	var altar := event.kind == TombRiskEvent.Kind.ALTAR
	draw_rect(Rect2(-26, -18, 52, 36), Color("8f554b") if altar else Color("66645d"))
	draw_rect(Rect2(-20, -12, 40, 24), Color("aa9976"), false, 2)
	if altar: draw_circle(Vector2.ZERO, 7, Color("bc4940"))
