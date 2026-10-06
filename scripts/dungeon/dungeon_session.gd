class_name DungeonSession
extends Node2D
## 新Run重置所有状态；下一层更换World并保留Run奖励。
const WORLD_SCENE: PackedScene = preload("res://scenes/main/room_test.tscn")
const DEFAULT_CONFIG: DungeonConfig = preload("res://data/tombs/default_dungeon_config.tres")
const BOSS_DATA: BossDefinition = preload("res://data/enemies/jinbei_warlord_corpse.tres")
@export var config: DungeonConfig = DEFAULT_CONFIG
@export var seed_value: int = 192034
var run_seed: int
var floor_number: int = 1
var current_floor_seed: int
var world: RoomController
var rewards: RelicRewardService
var _changing: bool = false
var _seed_rng := RandomNumberGenerator.new()


func _ready() -> void:
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


func _assemble_world(layout: DungeonLayout) -> void:
	world = WORLD_SCENE.instantiate() as RoomController
	world.layout = layout
	world.rewards = rewards
	world.floor_number = floor_number
	world.floor_offset = (floor_number - 1) * 3
	world.boss_definition = BOSS_DATA if floor_number == 1 else null
	world.restart_requested.connect(_restart_current)
	world.floor_exit_requested.connect(request_next_floor)
	add_child(world)
	world.hud.new_seed_requested.connect(regenerate)


func next_floor_layout() -> DungeonLayout:
	var first := DungeonGenerator.generate(run_seed, config)
	for attempt in range(16):
		var candidate_seed := (run_seed ^ (2 * 104729)) + attempt * 7919
		var layout := DungeonGenerator.generate(candidate_seed, config)
		if layout != null and layout.spatial_signature() != first.spatial_signature(): return layout
	return null


func request_next_floor() -> bool:
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
	_drop_world()
	floor_number = 2
	current_floor_seed = layout.seed_value
	_assemble_world(layout)
	carry.apply(world.player)
	_changing = false
