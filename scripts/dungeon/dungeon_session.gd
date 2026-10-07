class_name DungeonSession
extends Node2D
## 新Run重置所有状态；下一层更换World并保留Run奖励。
const WORLD_SCENE: PackedScene = preload("res://scenes/main/room_test.tscn")
const DEFAULT_CONFIG: DungeonConfig = preload("res://data/tombs/default_dungeon_config.tres")
const WARLORD_BOSS: BossDefinition = preload("res://data/enemies/jinbei_warlord_corpse.tres")
const TOMB_BEAST: BossDefinition = preload("res://data/enemies/tomb_guardian_beast.tres")
signal result_ready(result: RunResult)
signal run_started
signal return_requested(result: RunResult)
@export var hub_mode: bool = false
@export var exploration_enabled: bool = true
# 仅结算品相的确定性元数据，绝不参与地图/掉落/战斗计算。
var collection_day: int = 1
var _returning: bool = false
@export var config: DungeonConfig = DEFAULT_CONFIG
@export var seed_value: int = 192034
var run_seed: int
var floor_number: int = 1
var current_floor_seed: int
var world: RoomController
var rewards: RelicRewardService
var run_ended: bool = false
# 旧回归入口兼容；新的结束逻辑一律使用run_ended与明确Outcome。
var run_completed: bool:
	get: return run_ended
	set(value): run_ended = value
var bosses_defeated: int = 0
var complete_screen: RunCompleteScreen
var _defeated_floors: Dictionary[int, bool] = {}
var _changing: bool = false
var _seed_rng := RandomNumberGenerator.new()


func _ready() -> void:
	# 正式GameFlow已注入当日派生Seed；子Session不能再次用Campaign CLI覆盖它。
	if not hub_mode:
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--seed=") and argument.trim_prefix("--seed=").is_valid_int():
				seed_value = argument.trim_prefix("--seed=").to_int()
	_seed_rng.randomize()
	_start_new_run(DungeonGenerator.generate(seed_value, config))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("new_dungeon") and not event.is_echo(): regenerate()


func _restart_current() -> void:
	if not _changing: _schedule_new_run(DungeonGenerator.generate(run_seed, config))


func regenerate() -> bool:
	if _changing: return false
	var original := DungeonGenerator.generate(run_seed, config)
	for attempt in range(16):
		var candidate_seed := int(_seed_rng.randi())
		if candidate_seed == run_seed: continue
		var candidate := DungeonGenerator.generate(candidate_seed, config)
		if candidate != null and candidate.spatial_signature() != original.spatial_signature():
			_schedule_new_run(candidate)
			return true
	push_warning("No different layout found in 16 attempts")
	return false


func _schedule_new_run(layout: DungeonLayout) -> void:
	if layout == null: return
	_changing = true
	world.player.set_controls_enabled(false)
	_start_new_run.call_deferred(layout)


func _drop_world() -> void:
	if is_instance_valid(world):
		world.process_mode = Node.PROCESS_MODE_DISABLED
		remove_child(world)
		world.queue_free()


func _start_new_run(layout: DungeonLayout) -> void:
	assert(layout != null)
	if is_instance_valid(complete_screen): complete_screen.queue_free()
	run_ended = false
	_returning = false
	bosses_defeated = 0
	_defeated_floors.clear()
	_drop_world()
	if is_instance_valid(rewards):
		remove_child(rewards)
		rewards.queue_free()
	run_seed = layout.seed_value
	seed_value = run_seed
	floor_number = 1
	current_floor_seed = run_seed
	rewards = RelicRewardService.new()
	rewards.configure(run_seed)
	add_child(rewards)
	_assemble_world(layout)
	_changing = false
	run_started.emit()


func _assemble_world(layout: DungeonLayout) -> void:
	world = WORLD_SCENE.instantiate() as RoomController
	world.layout = layout
	world.exploration_enabled = exploration_enabled
	world.run_seed = run_seed
	world.rewards = rewards
	world.floor_number = floor_number
	world.floor_offset = (floor_number - 1) * 3
	world.boss_definition = boss_for_floor(floor_number)
	world.final_floor = floor_number == 2
	world.boss_defeated.connect(_on_boss_defeated)
	world.run_complete_requested.connect(request_run_complete)
	world.extraction_requested.connect(request_extraction)
	world.restart_requested.connect(_restart_current)
	world.floor_exit_requested.connect(request_next_floor)
	add_child(world)
	world.player.died.connect(_on_player_died)
	world.hud.new_seed_requested.connect(regenerate)


func next_floor_layout() -> DungeonLayout:
	var first := DungeonGenerator.generate(run_seed, config)
	for attempt in range(16):
		var candidate_seed := (run_seed ^ (2 * 104729)) + attempt * 7919
		var layout := DungeonGenerator.generate(candidate_seed, config)
		if layout != null and layout.spatial_signature() != first.spatial_signature(): return layout
	return null


func request_next_floor() -> bool:
	if run_ended: return false
	if _changing or floor_number != 1 or world.player.health.is_dead or world.current_room.room_type != RoomDefinition.Type.BOSS or world.current_room.room_state.status != RoomState.Status.CLEARED:
		return false
	var layout := next_floor_layout()
	if layout == null: return false
	var carry := RunCarryState.capture(world.player)
	_changing = true
	world.player.set_controls_enabled(false)
	_enter_next_floor.call_deferred(layout, carry)
	return true


func _enter_next_floor(layout: DungeonLayout, carry: RunCarryState) -> void:
	# E已排队但本帧死亡时，不允许旧carry把已结束Run带进下一层。
	if run_ended or world.player.health.is_dead:
		_changing = false
		return
	_drop_world()
	floor_number = 2
	current_floor_seed = layout.seed_value
	_assemble_world(layout)
	carry.apply(world.player)
	_changing = false


func boss_for_floor(floor: int) -> BossDefinition:
	match floor:
		1: return WARLORD_BOSS
		2: return TOMB_BEAST
		_: return null


func _on_boss_defeated() -> void:
	if _defeated_floors.has(floor_number): return
	_defeated_floors[floor_number] = true
	bosses_defeated += 1


func request_run_complete() -> bool:
	if run_ended or _changing or floor_number != 2 or world.player.health.is_dead or world.current_room.room_type != RoomDefinition.Type.BOSS or world.current_room.room_state.status != RoomState.Status.CLEARED or bosses_defeated != 2: return false
	return _finish_run(RunResult.Outcome.COMPLETED)


func request_extraction() -> bool:
	if run_ended or _changing or floor_number != 1 or world.player.health.is_dead or world.current_room.room_type != RoomDefinition.Type.BOSS or world.current_room.room_state.status != RoomState.Status.CLEARED or bosses_defeated != 1: return false
	return _finish_run(RunResult.Outcome.EXTRACTED)


func _on_player_died() -> void: _finish_run(RunResult.Outcome.DEAD)


func _finish_run(outcome: RunResult.Outcome) -> bool:
	if run_ended: return false
	run_ended = true
	_changing = false
	# 在库存清空前、Health死亡的遗物卸载回调继续前取纯数值/名称快照。
	var result := RunResult.new()
	result.outcome = outcome
	result.run_seed = run_seed
	result.floors_cleared = _defeated_floors.size()
	result.floor_reached = floor_number
	result.current_hp = world.player.health.current_hp
	result.max_hp = world.player.health.max_hp
	result.combat_clears = rewards.combat_clears
	result.bosses_defeated = bosses_defeated
	result.antique_value = world.player.antiques.total_value()
	for item in world.player.antiques.items():
		result.antique_ids.append(item.id)
		result.antique_names.append(item.display_name)
		result.antique_values.append(item.base_value)
		result.antique_conditions.append(AntiqueCondition.generate(run_seed,item.id,result.antique_ids.size()-1,collection_day))
	for id in world.player.relics.inventory.ids(): result.relic_names.append(world.player.relics.inventory.get_effect(id).definition.display_name)
	world.run_finished = true
	world.player.set_controls_enabled(false)
	world.current_room.stop_combat()
	rewards.stop()
	world.hud.hide_boss()
	world.antique_panel.panel.hide()
	world.get_node("RelicDebugPanel").process_mode = Node.PROCESS_MODE_DISABLED
	if outcome == RunResult.Outcome.DEAD: world.player.antiques.clear()
	complete_screen = RunCompleteScreen.new()
	complete_screen.result = result
	complete_screen.hub_mode = hub_mode
	complete_screen.return_requested.connect(_return_to_hub)
	add_child(complete_screen)
	result_ready.emit(result)
	return true


func _return_to_hub() -> void:
	if not hub_mode or not run_ended or _returning: return
	_returning = true
	return_requested.emit(complete_screen.result)
