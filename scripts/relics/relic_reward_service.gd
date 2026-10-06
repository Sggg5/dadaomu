class_name RelicRewardService
extends Node
## 一局奖励进度和独立 RNG；不执行遗物效果、不持有房间节点。
signal reward_available(definition: RelicDefinition, room_id: StringName)
const DEFAULT_POOL: RelicPool = preload("res://data/relics/formal_pool.tres")
const THRESHOLDS: Array[int] = [2, 4, 7]
var pool: RelicPool
var sequence: Array[RelicDefinition] = []
var combat_clears: int = 0
var rewards_given: int = 0
var active: bool = true
var _seen: Dictionary[StringName, bool] = {}
var _rng := RandomNumberGenerator.new()


func configure(seed_value: int, data: RelicPool = DEFAULT_POOL) -> void:
	pool = data
	assert(pool.is_valid(), "Formal reward pool must contain eight unique non-test relics")
	sequence.assign(pool.relics)
	sequence.sort_custom(func(a: RelicDefinition, b: RelicDefinition) -> bool: return str(a.id) < str(b.id))
	_rng.seed = seed_value ^ (pool.reward_version * 7919)
	for index in range(sequence.size() - 1, 0, -1):
		var chosen := _rng.randi_range(0, index)
		var previous := sequence[index]
		sequence[index] = sequence[chosen]
		sequence[chosen] = previous
	combat_clears = 0
	rewards_given = 0
	_seen.clear()
	active = true


func on_room_cleared(context: RoomClearContext) -> void:
	if not active or not context.was_combat or context.room_type != RoomDefinition.Type.COMBAT or _seen.has(context.room_id):
		return
	_seen[context.room_id] = true
	combat_clears += 1
	if combat_clears in THRESHOLDS and rewards_given < sequence.size():
		var reward := sequence[rewards_given]
		rewards_given += 1
		reward_available.emit(reward, context.room_id)


func stop() -> void:
	active = false
