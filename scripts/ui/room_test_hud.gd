class_name RoomTestHUD
extends CanvasLayer
## 测试展示与操作请求。HUD 不改房间状态或直接生成敌人。

signal damage_requested
signal restart_requested
signal quit_requested

@onready var damage_button: Button = $Root/DamageButton
@onready var minimap: RoomMinimap = $Root/Minimap


func _ready() -> void:
	damage_button.pressed.connect(func() -> void: damage_requested.emit())
	$Root/RestartButton.pressed.connect(func() -> void: restart_requested.emit())
	$Root/QuitButton.pressed.connect(func() -> void: quit_requested.emit())


func show_hp(current_hp: float, max_hp: float) -> void:
	$Root/HP.text = "生命 %.0f / %.0f" % [current_hp, max_hp]
	$Root/HP.modulate = Color("ff8277") if current_hp <= max_hp * 0.25 else Color.WHITE


func show_room(definition: RoomDefinition, state: RoomState, remaining: int) -> void:
	$Root/RoomInfo.text = "%s  |  %s" % [definition.title, state.get_label()]
	$Root/Enemies.text = "存活敌人 %d" % remaining


func show_map(definitions: Array[RoomDefinition], states: Dictionary[StringName, RoomState], current_id: StringName) -> void:
	minimap.update_map(definitions, states, current_id)
	var cleared_count: int = 0
	for state in states.values():
		if state.status == RoomState.Status.CLEARED:
			cleared_count += 1
	$Root/Progress.text = "已清场 %d / %d  ·  走入绿色门切换房间" % [cleared_count, states.size()]
	if cleared_count == states.size():
		$Root/Progress.text = "五间房已全部清场  ·  可自由重访，按 R 重新测试"


func show_death() -> void:
	$Root/Death.text = "你已倒下\n按 R 重新开始五房测试"
	damage_button.disabled = true
