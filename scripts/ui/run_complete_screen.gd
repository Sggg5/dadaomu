class_name RunCompleteScreen
extends CanvasLayer
## 单纯展示RunResult，R/N仍由Session与Controller处理。
var result: RunResult
var label: Label


func _ready() -> void:
	layer = 50
	var panel := ColorRect.new()
	panel.color = Color(.035,.04,.05,.97)
	panel.size = Vector2(1280,720)
	add_child(panel)
	label = Label.new()
	label.position = Vector2(260,80)
	label.size = Vector2(760,560)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",24)
	label.text = "大盗墓时代\n墓穴清理完成\n\nSeed：%d\n清理墓层：%d\n剩余生命：%.1f / %.0f\n\n本局遗物：\n%s\n\n普通战斗房清理：%d\nBoss击败：%d\n\n[R] 同 Seed 再来一次    [N] 新地宫" % [result.run_seed,result.floors_cleared,result.current_hp,result.max_hp,"\n".join(result.relic_names),result.combat_clears,result.bosses_defeated]
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
