class_name RoomTestHUD
extends CanvasLayer
## 测试展示与操作请求。HUD 不改房间状态或直接生成敌人。

signal damage_requested
signal restart_requested
signal quit_requested
signal new_seed_requested

@onready var damage_button: Button = $Root/DamageButton
@onready var minimap: RoomMinimap = $Root/Minimap


func _ready() -> void:
	var depth_label := Label.new()
	depth_label.name = "EncounterDepth"
	depth_label.position = Vector2(800, 108)
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


func show_room(room: DungeonRoom, state: RoomState, remaining: int) -> void:
	$Root/EncounterDepth.text = "深度：%d · 威胁：Tier %d" % [room.distance_from_start, EncounterDifficulty.from_depth(room.distance_from_start).tier]
	var type_label: String = ["战斗", "古董占位", "商人", "机关", "秘密", "Boss占位", "出生房"][room.room_type]
	$Root/RoomInfo.text = "%s · %s  |  %s" % [room.definition.title, type_label, state.get_label()]
	$Root/RoomInfo.tooltip_text = str(room.room_id)
	$Root/Enemies.text = "存活敌人 %d" % remaining


func show_map(layout: DungeonLayout, states: Dictionary[StringName, RoomState], current_id: StringName) -> void:
	minimap.update_map(layout, states, current_id)
	$Root/Seed.text = "Seed: %d" % layout.seed_value
	var cleared_count: int = 0
	for state in states.values():
		if state.status == RoomState.Status.CLEARED:
			cleared_count += 1
	$Root/Progress.text = "已清场 %d / %d  ·  走入绿色门切换房间" % [cleared_count, states.size()]
	if cleared_count == states.size():
		$Root/Progress.text = "全图已清场  ·  可自由重访，R 同图重开 / N 新地宫"


func show_death() -> void:
	$Root/Death.text = "你已倒下\nR 同 Seed 重开 / N 新地宫"
	$Root/Progress.text = "本次测试结束 · 重开会重置所有房间状态"
	damage_button.disabled = true
