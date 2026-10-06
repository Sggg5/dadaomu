class_name BossHealthDisplay
extends Control
var label: Label
var bar: ProgressBar


func _ready() -> void:
	position = Vector2(360, 4)
	label = Label.new()
	label.size = Vector2(610, 22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	bar = ProgressBar.new()
	bar.position = Vector2(0,24)
	bar.size = Vector2(610,14)
	bar.show_percentage = false
	add_child(bar)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()


func bind_boss(boss: WarlordBoss) -> void:
	show()
	update_hp(boss.health.current_hp, boss.health.max_hp, boss.definition.display_name)
	boss.health.changed.connect(update_hp.bind(boss.definition.display_name))
	boss.killed.connect(hide)


func update_hp(current: float, maximum: float, title: String) -> void:
	label.text = "%s · %.0f / %.0f" % [title,current,maximum]
	bar.max_value = maximum
	bar.value = current
