class_name BossRunPlan
extends RefCounted
## 开局全局预分配；只读取Run/Floor/Pool/version，路线和奖励不消费此流。
const VERSION:int=1
var assigned:Dictionary[int,BossDefinition]={}
static func build(run_seed:int,tomb:TombDefinition)->BossRunPlan:
	var plan:=BossRunPlan.new()
	for floor_number in range(1,tomb.floors.size()+1):
		var pool:=tomb.floor_at(floor_number).boss_pool
		if pool==null:continue
		assert(pool.validation_error().is_empty())
		var ordered:Array[BossDefinition]=pool.bosses.duplicate()
		ordered.sort_custom(func(a:BossDefinition,b:BossDefinition)->bool:return str(a.id)<str(b.id))
		var rng:=RandomNumberGenerator.new()
		rng.seed=AntiquePool.stable_score(run_seed,floor_number,pool.id,&"BOSS_PLAN",VERSION)
		plan.assigned[floor_number]=ordered[rng.randi_range(0,ordered.size()-1)]
	return plan
func boss_for_floor(number:int)->BossDefinition:return assigned.get(number)
func signature()->String:
	var keys:Array=assigned.keys()
	keys.sort()
	var rows:Array=[]
	for number in keys:rows.append([number,str(assigned[number].id)])
	return JSON.stringify([VERSION,rows])
