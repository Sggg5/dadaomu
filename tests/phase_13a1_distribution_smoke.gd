extends "res://tests/phase_5b_smoke.gd"
func run() -> void:
	var tomb := SiteRegistry.load_default().site(&"DEFAULT_TOMB").tomb_definition
	var later := 0
	var missing_full_set := 0
	var first_counts: Dictionary = {}
	var histogram: Dictionary = {}
	for seed_value in range(100):
		var boss := BossRunPlan.build(seed_value,tomb).signature()
		var relic := RelicRewardPlan.build(seed_value,5,RelicRewardService.PRODUCTION_POOL).signature()
		var acquired: Dictionary = {}
		var count := 0
		for floor_number in range(1,6):
			var layout := TombFloorGenerator.generate(seed_value,floor_number,tomb)
			var topology := layout.signature()
			var geometry := RoomGeometryPlan.build(seed_value,floor_number,layout,tomb.floor_at(floor_number).geometry_pool).signature()
			var antique := RoomController.ANTIQUE_POOL.pick_profiled(seed_value,floor_number,layout.antique_id,&"antique_room",tomb.floor_at(floor_number).antique_reward_profile).id
			var plan := ProfessionCorpsePlan.build(seed_value,floor_number,layout)
			check(plan.assigned.size()==1 if floor_number==1 else plan.assigned.size()<=1,"Guaranteed one first floor / max one later Seed%d F%d"%[seed_value,floor_number])
			check(plan.assigned==ProfessionCorpsePlan.build(seed_value,floor_number,layout).assigned,"Reproducible independent corpse selection")
			for room_id in plan.assigned:
				check(layout.rooms[room_id].room_type==RoomDefinition.Type.COMBAT and room_id!=layout.terminal_id,"Corpse assigned only to ordinary combat")
				acquired[plan.assigned[room_id]]=true;count+=1
				if floor_number==1:first_counts[plan.assigned[room_id]]=int(first_counts.get(plan.assigned[room_id],0))+1
				else:later+=1
			check(topology==layout.signature() and geometry==RoomGeometryPlan.build(seed_value,floor_number,layout,tomb.floor_at(floor_number).geometry_pool).signature(),"Corpse generation preserves topology/geometry")
			check(antique==RoomController.ANTIQUE_POOL.pick_profiled(seed_value,floor_number,layout.antique_id,&"antique_room",tomb.floor_at(floor_number).antique_reward_profile).id,"Original formal antique stream preserved")
		check(boss==BossRunPlan.build(seed_value,tomb).signature() and relic==RelicRewardPlan.build(seed_value,5,RelicRewardService.PRODUCTION_POOL).signature(),"Boss and random relic sequence preserved")
		histogram[count]=int(histogram.get(count,0))+1
		if acquired.size()<4:missing_full_set+=1
	check(missing_full_set>0 and first_counts.size()==4,"No full-four guarantee; all factions sampled across Seeds")
	check(later>0 and later<400,"Later floors include absent corpses and spawned corpses")
	var layout := TombFloorGenerator.generate(52,2,tomb)
	check(ProfessionCorpsePlan.build(52,2,layout,{"later_floor_chance":0,"max_per_floor":1}).assigned.is_empty(),"Config probability zero suppresses later corpses")
	check(ProfessionCorpsePlan.build(52,2,layout,{"later_floor_chance":1,"max_per_floor":1}).assigned.size()==1,"Config probability one produces exactly one later corpse")
	check(ProfessionCorpsePlan.build(52,1,TombFloorGenerator.generate(52,1,tomb),{"later_floor_chance":0,"max_per_floor":0}).assigned.size()==1,"First floor guarantee cannot be disabled by later-floor settings")
	print("[Corpse distribution] later=%d/400 first=%s run_counts=%s missing_full_four=%d/100"%[later,str(first_counts),str(histogram),missing_full_set])
	print("[Phase13A1 distribution] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
