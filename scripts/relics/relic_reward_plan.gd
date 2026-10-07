class_name RelicRewardPlan
extends RefCounted
## Run级预分配，跳过/拾取顺序不消费RNG，所有来源无重复。
var assigned: Dictionary[StringName, RelicDefinition] = {}
static func build(seed_value: int, floor_count: int, pool: RelicPool) -> RelicRewardPlan:
	var plan := RelicRewardPlan.new()
	var ordered: Array[RelicDefinition] = pool.relics.duplicate()
	ordered.sort_custom(func(a: RelicDefinition,b: RelicDefinition) -> bool: return str(a.id)<str(b.id))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ (pool.reward_version*7919)
	for i in range(ordered.size()-1,0,-1):
		var j := rng.randi_range(0,i)
		var previous := ordered[i]
		ordered[i]=ordered[j]
		ordered[j]=previous
	var sources: Array[StringName] = []
	for floor in range(1,floor_count+1):
		sources.append(StringName("F%d:ITEM" % floor))
		sources.append(StringName("F%d:BOSS" % floor))
	for count in [4,12,24]: sources.append(StringName("MILESTONE:%d" % count))
	assert(sources.size() <= ordered.size(), "Reward pool must cover all unique sources")
	for i in range(sources.size()): plan.assigned[sources[i]]=ordered[i]
	return plan
