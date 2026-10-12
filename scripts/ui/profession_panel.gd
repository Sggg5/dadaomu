extends CanvasLayer
## G manages independent run tokens, Q uses the currently equipped DRAFT ability.
var runtime: ProfessionRuntime
var panel: Panel
var info: RichTextLabel
var choices: VBoxContainer
var hud_line: Label
func _ready() -> void:
	layer = 32
	hud_line = Label.new(); hud_line.position = Vector2(790,20); hud_line.size = Vector2(450,28)
	hud_line.add_theme_font_size_override("font_size",15); hud_line.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(hud_line)
	panel = Panel.new(); panel.position = Vector2(290,110); panel.size = Vector2(700,485); add_child(panel)
	var style := StyleBoxFlat.new(); style.bg_color = Color("292c26"); style.border_color = Color("bba77c"); style.set_border_width_all(3); panel.add_theme_stylebox_override("panel",style)
	info = RichTextLabel.new(); info.position = Vector2(24,16); info.size = Vector2(650,175); info.add_theme_font_size_override("normal_font_size",18); panel.add_child(info)
	choices = VBoxContainer.new(); choices.position = Vector2(24,200); choices.size = Vector2(650,220); panel.add_child(choices)
	var close := Button.new(); close.text = "稍后切换 / 关闭 [G / Esc]"; close.position = Vector2(24,435); close.size = Vector2(650,36); close.pressed.connect(panel.hide); panel.add_child(close)
	panel.hide()
func open_offer(_id: StringName = &"NONE") -> void:
	if not runtime.available(): runtime.notice = "战斗、危险结算或切场中不能切换"; return
	for child in choices.get_children(): choices.remove_child(child); child.queue_free()
	for id in runtime.state.tokens() + [&"NONE"]:
		var button := Button.new(); button.text = "装备 " + ProfessionRegistry.display_name(id) + " · " + ProfessionRegistry.token_name(id)
		button.custom_minimum_size.y = 36
		button.pressed.connect(func() -> void:
			if runtime.equip(id): panel.hide())
		choices.add_child(button)
	panel.show()
func _process(_delta: float) -> void:
	var id := runtime.state.active_id
	var definition := ProfessionRegistry.definition(id)
	var ability: StringName = StringName(definition.get("ability", ""))
	var left: int = 1-runtime.state.used(runtime.clue_key()) if id==&"MOJIN" else 0
	var detail := "线索余%d"%left if id==&"MOJIN" else ("命中%d/4·强%d%s"%[runtime.state.banshan_hits,runtime.state.used(&"BANSHAN:EMPOWER"),"·待用" if runtime.state.banshan_ready else ""] if id==&"BANSHAN" else ("安全房" if not runtime.is_combat_room() else "重访无减免" if not runtime.first_visit else "首伤已用" if runtime.state.damaged_rooms.has(runtime.current_key) else "首伤待用") if id==&"FAQIU" else "容量10格" if id==&"XIELING" else "无能力")
	var keys := "G信物 Q线索" if id==&"MOJIN" else "G信物·自动"
	hud_line.text = "%s · %s · %s%s" % [ProfessionRegistry.display_name(id),keys,detail," · 超载80%禁拾" if runtime.world.player.antiques.used_slots() > runtime.world.player.antiques.capacity else (" · 满载95%" if id==&"XIELING" and runtime.world.player.antiques.used_slots()>8 else "")]
	info.text = "本局信物簿 · DRAFT\n当前：%s\n%s\n\n%s\n身份记录：%d · 已消耗次数不会因切换重置" % [ProfessionRegistry.display_name(id),definition.get("description","未装备任何信物"),runtime.notice,runtime.state.identities().size()]
	for identity in runtime.state.identities().values():
		info.text += "\n%s · F%s · %s（游戏虚构身份）" % [identity.get("name","未记录"),identity.get("floor","?"),identity.get("room_id","?")]
	for floor_id in runtime.state.clues: info.text += "\nF%s已用线索：%s" % [floor_id,runtime.state.clues[floor_id].text]
	if id==&"BANSHAN": info.text += "\n有效武器命中：%d/4 · %s · 已用强化%d次" % [runtime.state.banshan_hits,"下次强化25%" if runtime.state.banshan_ready else "积蓄中",runtime.state.used(&"BANSHAN:EMPOWER")]
	if id==&"FAQIU": info.text += "\n本房首伤：" + ("可减免30%" if runtime.first_visit and runtime.is_combat_room() and not runtime.state.damaged_rooms.has(runtime.current_key) else "已结算/重访/非战斗房")
	if panel.visible and not runtime.available(): panel.hide()
func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.physical_keycode == KEY_G:
		if panel.visible: panel.hide()
		else: open_offer()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_Q:
		runtime.use_ability(); get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_ESCAPE and panel.visible:
		panel.hide(); get_viewport().set_input_as_handled()
