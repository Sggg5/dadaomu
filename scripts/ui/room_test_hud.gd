class_name RoomTestHUD
extends CanvasLayer
## 测试展示与操作请求。HUD 不改房间状态或直接生成敌人。

signal damage_requested
signal restart_requested
signal quit_requested
signal new_seed_requested
var boss_display: BossHealthDisplay
var antique_label: Label

@onready var damage_button: Button = $Root/DamageButton
@onready var minimap: RoomMinimap = $Root/Minimap


func _ready() -> void:
	boss_display = BossHealthDisplay.new()
	$Root.add_child(boss_display)
	antique_label = Label.new()
	antique_label.position = Vector2(580,690)
	antique_label.add_theme_font_size_override("font_size",14)
	antique_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root.add_child(antique_label)
	var depth_label := Label.new()
	depth_label.name = "EncounterDepth"
	depth_label.position = Vector2(660, 108)
	depth_label.add_theme_font_size_override("font_size", 16)
	depth_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root.add_child(depth_label)
	damage_button.pressed.connect(func() -> void: damage_requested.emit())
	$Root/RestartButton.pressed.connect(func() -> void: restart_requested.emit())
	$Root/QuitButton.pressed.connect(func() -> void: quit_requested.emit())
	$Root/NewSeedButton.pressed.connect(func() -> void: new_seed_requested.emit())


func show_hp(current_hp: float, max_hp: float) -> void:
	$Root/HP.text = "生命 %.0f / %.0f" % [current_hp, max_hp]
	$Root/HP.modulate = Color("ff8277") if current_hp <= max_hp * 0.25 else Color.WHITE


func show_antiques(inventory: AntiqueInventory) -> void:
	antique_label.text = "古董：%d / %d格  估值：%s  [Tab]背包" % [inventory.used_slots(),inventory.capacity,AntiqueDefinition.money(inventory.total_value())]


func show_room(room: DungeonRoom, state: RoomState, remaining: int) -> void:
	$Root/EncounterDepth.text = "深度：%d · 威胁：Tier %d" % [room.distance_from_start, EncounterDifficulty.from_depth(room.distance_from_start).tier]
	var type_label: String = ["战斗", "古董房", "商人", "机关", "秘密", "Boss房", "出生房"][room.room_type]
	var status_label := "伏击中 · 门已关闭" if state.status == RoomState.Status.CLEARED and remaining > 0 else state.get_label()
	$Root/RoomInfo.text = "%s · %s  |  %s" % [room.definition.title, type_label, status_label]
	$Root/RoomInfo.tooltip_text = str(room.room_id)
	$Root/Enemies.text = "存活敌人 %d" % remaining


func show_map(layout: DungeonLayout, states: Dictionary[StringName, RoomState], current_id: StringName) -> void:
	minimap.update_map(layout, states, current_id)
	$Root/Seed.text = "Seed: %d" % layout.seed_value
	var cleared_count: int = 0
	for id in layout.rooms:
		if states[id].status == RoomState.Status.CLEARED:
			cleared_count += 1
	$Root/Progress.text = "已清场 %d / %d  ·  绿色门过房" % [cleared_count, layout.rooms.size()]
	if cleared_count == layout.rooms.size():
		$Root/Progress.text = "全图已清场  ·  可自由重访"


func show_death() -> void:
	$Root/Death.text = "你已倒下\nR 同 Seed 重开 / N 新地宫"
	$Root/Progress.text = "本次测试结束 · 重开会重置所有房间状态"
	damage_button.disabled = true


func show_boss(boss: Enemy) -> void:
	$Root/Title.hide()
	boss.killed.connect($Root/Title.show)
	boss_display.bind_boss(boss)


func hide_boss() -> void:
	$Root/Title.show()
	boss_display.hide()


func show_floor(number: int, depth: int, tier: int) -> void:
	$Root/EncounterDepth.text = "墓层：%d · 深度：%d · Tier %d" % [number,depth,tier]
