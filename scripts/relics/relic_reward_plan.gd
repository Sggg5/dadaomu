class_name RelicRewardPlan
extends RefCounted
## Run级预分配，跳过/拾取顺序不消费RNG，所有来源无重复。
var assigned: Dictionary[StringName, RelicDefinition] = {}
static func build_uniform(seed_value: int, floor_count: int, pool: RelicPool) -> RelicRewardPlan:
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

const VERSION: int = 3
const ITEM: RelicRewardProfile = preload("res://data/relics/reward_profiles/item.tres")
const BOSS: RelicRewardProfile = preload("res://data/relics/reward_profiles/boss.tres")
const MILESTONE: RelicRewardProfile = preload("res://data/relics/reward_profiles/milestone.tres")
const ARCHETYPES: Array[StringName] = [&"PROJECTILE",&"EXPLOSION",&"DOT",&"KILL_TRIGGER",&"CLOSE_RANGE",&"MIXED"]
var archetype: StringName = &"MIXED"
var propensity: int = 1 # only development statistics; never a gameplay difficulty label
var desired_cores: int = 3

static func build(seed_value: int,floor_count: int,pool: RelicPool) -> RelicRewardPlan:
	var plan:=RelicRewardPlan.new()
	var rng:=RandomNumberGenerator.new()
	rng.seed=AntiquePool.stable_score(seed_value,0,&"RUN",&"RELIC_STRUCTURE",VERSION)
	plan.archetype=ARCHETYPES[rng.randi_range(0,5)]
	var roll:=rng.randi_range(0,99)
	plan.propensity=0 if roll<18 else (1 if roll<65 else (2 if roll<93 else 3))
	plan.desired_cores=rng.randi_range(2+plan.propensity,3+plan.propensity)
	var remaining:Array[RelicDefinition]=pool.relics.duplicate()
	remaining.sort_custom(func(a:RelicDefinition,b:RelicDefinition)->bool:return str(a.id)<str(b.id))
	var sources:Array[StringName]=[]
	for floor in range(1,floor_count+1):
		sources.append(StringName("F%d:ITEM" % floor))
		sources.append(StringName("F%d:BOSS" % floor))
	for count in [4,12,24]:sources.append(StringName("MILESTONE:%d" % count))
	assert(remaining.size()>=sources.size())
	var available_cores:=0
	for item in remaining:
		if item.design_role==RelicDefinition.DesignRole.CORE:available_cores+=1
	var minimum_cores:=mini(2,available_cores)
	var core_count:=0
	for index in range(sources.size()):
		var source:=sources[index]
		var profile:=ITEM if str(source).ends_with(":ITEM") else (BOSS if str(source).ends_with(":BOSS") else MILESTONE)
		var force_core:=core_count<minimum_cores and sources.size()-index<=minimum_cores-core_count
		rng.seed=AntiquePool.stable_score(seed_value,0,source,&"RELIC_SOURCE",VERSION)
		var groups: Array[int]=[0,0,0,0]
		for item in remaining:groups[item.design_role]+=1
		var weights:Array[float]=[]
		var total:=0.0
		for item in remaining:
			var weight:float=profile.role_weights[item.design_role]/maxi(1,groups[item.design_role])
			if item.design_role==RelicDefinition.DesignRole.CORE:
				weight*=[0.7,1.0,1.4,2.0][plan.propensity]
				weight*=1.6 if core_count<plan.desired_cores else 0.6 # soft preference, never a upper cap
			if force_core and item.design_role!=RelicDefinition.DesignRole.CORE:weight=0
			if plan.archetype!=&"MIXED" and item.archetype_tags.has(plan.archetype):weight*=1.35
			weights.append(weight)
			total+=weight
		var draw:=rng.randf()*total
		var chosen:=0
		for i in range(remaining.size()):
			if weights[i]<=0:continue
			chosen=i
			draw-=weights[i]
			if draw<0:break
		var item:RelicDefinition=remaining[chosen]
		plan.assigned[source]=item
		core_count+=int(item.design_role==RelicDefinition.DesignRole.CORE)
		remaining.remove_at(chosen)
	return plan

func signature() -> String:
	var sources:Array=assigned.keys()
	sources.sort_custom(func(a:Variant,b:Variant)->bool:return str(a)<str(b))
	var rows:Array=[]
	for source in sources:rows.append([str(source),str(assigned[source].id)])
	return JSON.stringify([VERSION,str(archetype),rows])

func choices(source:StringName)->Array[RelicDefinition]:
	# 预留互斥二选一；当前生产每source仅一件，不增加奖励总数。
	var result:Array[RelicDefinition]=[]
	if assigned.has(source):result.append(assigned[source])
	return result
