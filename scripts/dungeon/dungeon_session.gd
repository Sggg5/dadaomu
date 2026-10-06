class_name DungeonSession
extends Node2D
## 开发期入口：选择 Seed、调用生成器、装配控制器，不是 Phase 8 的 Run 系统。
## Seed 不写磁盘；重开替换控制器，房间切换仍保留控制器内唯一玩家。

const WORLD_SCENE: PackedScene = preload("res://scenes/main/room_test.tscn")
const DEFAULT_CONFIG: DungeonConfig = preload("res://data/tombs/default_dungeon_config.tres")

@export var config: DungeonConfig = DEFAULT_CONFIG
@export var seed_value: int = 192034

var world: RoomController
var rewards: RelicRewardService
var _changing: bool = false
var _seed_rng := RandomNumberGenerator.new()


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed="):
			var value := argument.trim_prefix("--seed=")
			if value.is_valid_int():
				seed_value = value.to_int()
	_seed_rng.randomize()
	var initial := DungeonGenerator.generate(seed_value, config)
	assert(initial != null, "Dungeon generation failed")
	_replace_world(initial)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("new_dungeon") and not event.is_echo():
		regenerate()


func _restart_current() -> void:
	if not _changing:
		_schedule(DungeonGenerator.generate(seed_value, config))


func regenerate() -> bool:
	if _changing:
		return false
	# 新 Seed 不必然有不同拓扑；有限尝试让 N 获得不同地图。
	for attempt in range(16):
		var candidate_seed := int(_seed_rng.randi())
		if candidate_seed == seed_value:
			continue
		var candidate := DungeonGenerator.generate(candidate_seed, config)
		if candidate != null and candidate.spatial_signature() != world.layout.spatial_signature():
			_schedule(candidate)
			return true
	push_warning("No different layout found in 16 attempts; current dungeon retained")
	return false


func _schedule(next: DungeonLayout) -> void:
	if next == null:
		return
	_changing = true
	world.player.set_controls_enabled(false)
	_replace_world.call_deferred(next)


func _replace_world(next: DungeonLayout) -> void:
	if is_instance_valid(world):
		world.process_mode = Node.PROCESS_MODE_DISABLED
		remove_child(world)
		world.queue_free()
	seed_value = next.seed_value
	if is_instance_valid(rewards):
		remove_child(rewards)
		rewards.queue_free()
	rewards = RelicRewardService.new()
	rewards.configure(seed_value)
	add_child(rewards)
	world = WORLD_SCENE.instantiate() as RoomController
	world.layout = next
	world.rewards = rewards
	world.restart_requested.connect(_restart_current)
	add_child(world)
	world.hud.new_seed_requested.connect(regenerate)
	_changing = false
