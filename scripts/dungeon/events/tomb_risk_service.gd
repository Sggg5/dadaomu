class_name TombRiskService
extends RefCounted
## 每层独立事件账本。先锁结果，再由局部内容节点执行伤害/波次/拾取。
const VERSION: int = 1
const POOL: AntiquePool = preload("res://data/antiques/formal_pool.tres")
var run_seed: int
var floor_number: int
var regional_profile:SiteLootProfile
var reward_profile: AntiqueRewardProfile
var results: Dictionary[StringName, TombRiskResult] = {}

func _init(seed_value: int = 0, floor_value: int = 1) -> void:
	run_seed = seed_value
	floor_number = floor_value

func key(room_id: StringName, event_id: StringName) -> StringName:
	return StringName("%s/%s" % [room_id, event_id])

func preview(room_id: StringName, event: TombRiskEvent) -> TombRiskResult:
	var result := TombRiskResult.new()
	result.event_id = event.id
	if event.kind != TombRiskEvent.Kind.COFFIN:
		result.outcome = TombRiskResult.Outcome.ANTIQUE
		return result
	var rng := RandomNumberGenerator.new()
	rng.seed = AntiquePool.stable_score(run_seed, floor_number, room_id, event.id, VERSION)
	var total: int = 0
	for weight in event.weights: total += maxi(0, weight)
	assert(total > 0 and event.weights.size() == 4)
	var roll := rng.randi_range(0, total - 1)
	for index in range(4):
		roll -= maxi(0, event.weights[index])
		if roll < 0:
			result.outcome = index as TombRiskResult.Outcome
			break
	return result

func resolve(room_id: StringName, event: TombRiskEvent) -> TombRiskResult:
	var source := key(room_id, event.id)
	if results.has(source): return null
	var result := preview(room_id, event)
	result.resolved = true
	if result.outcome == TombRiskResult.Outcome.ANTIQUE or (result.outcome == TombRiskResult.Outcome.AMBUSH and event.ambush_reward):
		result.antique_ids.append(reward(room_id, event).id)
	results[source] = result
	return result

func reward(room_id: StringName, event: TombRiskEvent) -> AntiqueDefinition:
	if regional_profile!=null:return regional_profile.pick(run_seed,floor_number,room_id,StringName("risk_reward:%s"%event.id),reward_profile,event.high_value_reward)
	if not event.high_value_reward:
		var source := StringName("risk_reward:%s" % event.id)
		return POOL.pick_profiled(run_seed, floor_number, room_id, source, reward_profile) if reward_profile != null else POOL.pick(run_seed, floor_number, room_id, source)
	# 轻量高价值机会：稀有池独立抽取，并不保证TREASURE。
	var candidates: Array[AntiqueDefinition] = []
	for item in POOL.antiques:
		if item.rarity >= AntiqueDefinition.Rarity.RARE: candidates.append(item)
	candidates.sort_custom(func(a: AntiqueDefinition, b: AntiqueDefinition) -> bool: return str(a.id) < str(b.id))
	var rng := RandomNumberGenerator.new()
	rng.seed = AntiquePool.stable_score(run_seed, floor_number, room_id, StringName("high_reward:%s" % event.id), VERSION)
	return candidates[rng.randi_range(0, candidates.size() - 1)]

func definition(id:StringName)->AntiqueDefinition:
	return regional_profile.approved_pool.find_by_id(id) if regional_profile!=null else POOL.find_by_id(id)
