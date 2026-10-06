class_name RunCompleteScreen
extends CanvasLayer
## 只读结算快照；内容可滚动，R/N固定显示，古董估值不入永久钱包。
var result: RunResult
var label: Label


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
	var names := "无" if result.antique_names.is_empty() else "\n".join(result.antique_names)
	label.text = "大盗墓时代\n墓穴清理完成\n\nSeed：%d\n清理墓层：%d\n剩余生命：%.1f / %.0f\n\n本局遗物：\n%s\n\n带回古董：\n%s\n古董总估值：%s\n普通战斗房清理：%d\nBoss击败：%d" % [result.run_seed,result.floors_cleared,result.current_hp,result.max_hp,"\n".join(result.relic_names),names,AntiqueDefinition.money(result.antique_value),result.combat_clears,result.bosses_defeated]
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(label)
	var actions := Label.new()
	actions.position = Vector2(210,650)
	actions.size.x = 860
	actions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	actions.add_theme_font_size_override("font_size",24)
	actions.text = "[R] 同 Seed 再来一次    [N] 新地宫"
	add_child(actions)
