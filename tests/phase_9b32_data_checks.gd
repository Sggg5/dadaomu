extends RefCounted
var test:SceneTree
const TOMB:TombDefinition=preload("res://data/tombs/default_tomb.tres")
func _init(context:SceneTree)->void:test=context
func run()->void:
	var frequencies:Array=[]
	for i in range(5):frequencies.append({})
	var routes:Dictionary={}
	var different:=0
	for seed_value in range(1000):
		var plan:=BossRunPlan.build(seed_value,TOMB)
		test.check(plan.signature()==BossRunPlan.build(seed_value,TOMB).signature(),"Boss plan deterministic")
		routes[plan.signature()]=true
		different+=int(plan.signature()!=BossRunPlan.build(seed_value+1,TOMB).signature())
		for number in range(1,6):
			var id:=plan.boss_for_floor(number).id
			frequencies[number-1][id]=frequencies[number-1].get(id,0)+1
	test.check(routes.size()==32 and different>900,"All32 routes and most consecutive Seeds differ")
	for floor_stats in frequencies:test.check(floor_stats.size()==2 and floor_stats.values().all(func(count:int)->bool:return count>=400 and count<=600),"Each Boss appears40/60")
	var broken:=BossPoolDefinition.new()
	test.check(not broken.validation_error().is_empty(),"Pool rejects empty ID/entries")
	broken.id=&"test"
	test.check(not broken.validation_error().is_empty(),"Pool rejects empty entries")
	broken.bosses.assign([TOMB.floor_at(1).boss_pool.bosses[0],TOMB.floor_at(1).boss_pool.bosses[0]])
	test.check(not broken.validation_error().is_empty(),"Pool rejects duplicate IDs")
	var invalid:=BossDefinition.new()
	invalid.id=&"invalid"
	broken.bosses.assign([invalid])
	test.check(not broken.validation_error().is_empty(),"Pool rejects missing scene")
	var ids:Dictionary={}
	for number in range(1,6):
		var pool:=TOMB.floor_at(number).boss_pool
		test.check(pool.validation_error().is_empty() and pool.bosses.size()==2,"Production floor has exactly two valid candidates")
		for definition in pool.bosses:ids[definition.id]=true
	test.check(ids.size()==10,"Ten distinct production Bosses")
	var session:=preload("res://scenes/main/dungeon_test.tscn").instantiate() as DungeonSession
	session.seed_value=33
	test.root.add_child(session)
	test.session=session
	test.current_scene=session
	await test.frames(3)
	var signature:=session.boss_plan.signature()
	var reward_signature:=session.rewards.plan.signature()
	var map:=session.floor_layout(1).signature()
	session.rewards.plan.choices(&"F1:ITEM")
	test.check(session.boss_plan.signature()==signature,"Skipped item/reward lookup cannot consume Boss plan")
	test.key(KEY_R)
	await test.frames(5)
	test.check(session.boss_plan.signature()==signature and session.rewards.plan.signature()==reward_signature and session.floor_layout(1).signature()==map,"R reproduces Bosses, independent relics and map")
	var altered:=TombDefinition.new()
	altered.id=TOMB.id
	altered.display_name=TOMB.display_name
	for number in range(1,6):
		var floor_data:=TOMB.floor_at(number).duplicate() as TombFloorDefinition
		var pool:=BossPoolDefinition.new()
		pool.id=StringName("independent_%d"%number)
		var candidates:=TOMB.floor_at(number).boss_pool.bosses
		pool.bosses.assign([candidates[1] if candidates[0].id==session.boss_for_floor(number).id else candidates[0]])
		floor_data.boss_pool=pool
		altered.floors.append(floor_data)
	session.tomb=altered
	test.key(KEY_R)
	await test.frames(5)
	test.check(session.boss_plan.signature()!=signature and session.rewards.plan.signature()==reward_signature and session.floor_layout(1).signature()==map,"Changed Boss pools cannot perturb relic plan or map Seed")
	session.tomb=TOMB
	test.key(KEY_N)
	await test.frames(5)
	test.check(session.boss_plan.signature()==BossRunPlan.build(session.run_seed,TOMB).signature(),"Real N output equals deterministic new-seed production plan")
	test.check(session.boss_plan.assigned.size()==5 and session.run_seed!=33,"N creates complete plan before entering any Boss")
	session.queue_free()
	await test.frames(3)
	var file:=FileAccess.open("res://logs/phase_9b32_boss_routes.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"floor_counts":frequencies,"routes":routes.size(),"adjacent_seeds_different":different},"  "))
	print("[Boss plans] ",frequencies," routes=",routes.size()," different=",different)
