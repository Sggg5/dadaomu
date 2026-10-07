class_name RunCompleteScreen
extends CanvasLayer
## 单纯展示不可变RunResult；Outcome明确决定安全带回或全部遗失，无永久经济。
var result: RunResult
var label: Label
signal return_requested
var hub_mode: bool = false


func _ready() -> void:
	layer = 50
	var panel := ColorRect.new()
	panel.color = Color(.035,.04,.05,.97)
	panel.size = Vector2(1280,720)
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(210,40)
	scroll.size = Vector2(860,575)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	label = Label.new()
	label.custom_minimum_size.x = 820
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",20)
	var title := "墓穴清理完成"
	var floors := "清理墓层：%d" % result.floors_cleared
	var cargo_title := "安全带回古董："
	var value_title := "安全带回总估值："
	if result.outcome == RunResult.Outcome.EXTRACTED:
		title = "成功撤离"
		floors = "撤离墓层：%d" % result.floor_reached
	elif result.outcome == RunResult.Outcome.DEAD:
		title = "你倒在了墓穴里"
		floors = "倒下墓层：%d" % result.floor_reached
		cargo_title = "未撤离古董全部遗失："
		value_title = "本次损失："
	var names: Array[String] = []
	for index in range(result.antique_names.size()):
		var value := result.antique_values[index] if index < result.antique_values.size() else 0
		names.append("%s    %s" % [result.antique_names[index],AntiqueDefinition.money(value)])
	var cargo := ("未携带古董" if result.outcome == RunResult.Outcome.DEAD else "无") if names.is_empty() else "\n".join(names)
	label.text = "大盗墓时代\n%s\nSeed：%d · %s\n剩余生命：%.1f / %.0f\n普通战斗房清理：%d · Boss击败：%d\n%s%s\n\n本局遗物：\n%s\n\n%s\n%s" % [title,result.run_seed,floors,result.current_hp,result.max_hp,result.combat_clears,result.bosses_defeated,value_title,AntiqueDefinition.money(result.antique_value),"\n".join(result.relic_names),cargo_title,cargo]
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(label)
	var actions := Label.new()
	actions.name = "Actions"
	actions.position = Vector2(210,650)
	actions.size.x = 860
	actions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	actions.add_theme_font_size_override("font_size",24)
	actions.text = "[E] 返回地面    [R] 同 Seed 重试    [N] 新地宫" if hub_mode else "独立地宫测试模式\n[R] 同 Seed 重试    [N] 新地宫"
	add_child(actions)


func _unhandled_input(event: InputEvent) -> void:
	if hub_mode and event.is_action_pressed("interact") and not event.is_echo():
		get_viewport().set_input_as_handled()
		return_requested.emit()
