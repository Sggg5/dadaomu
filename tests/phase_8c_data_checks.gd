extends RefCounted
var test: SceneTree


func _init(context: SceneTree) -> void: test = context


func run() -> void:
	var state := MuseumState.new()
	state.campaign_seed = 52 # 明确的有效v4存档夹具。
	var item := state.collection.add(&"tang_sancai_horse",1,55)
	var duplicate := state.collection.add(&"tang_sancai_horse",1,90)
	test.check(not item.identified and item.condition == 55 and duplicate.condition == 90 and item != duplicate,"Owned antique registration defaults unidentified, per-instance condition independent")
	for seed in range(100):
		var value := AntiqueCondition.generate(seed,&"tang_sancai_horse",0,1)
		test.check(value >= 55 and value <= 90 and value == AntiqueCondition.generate(seed,&"tang_sancai_horse",0,1),"Independent condition RNG bounded and reproducible seed%d" % seed)
	var varied: Dictionary = {}
	for index in range(16): varied[AntiqueCondition.generate(192034,&"tang_sancai_horse",index,1)] = true
	test.check(varied.size() > 1,"Cargo index permits independently varied conditions")
	test.check(not state.assign(&"CASE_1",item.instance_id) and state.appeal_for(item.instance_id) == 0,"Unidentified data-layer assignment refused with zero appeal")
	state.display_assignments[&"CASE_1"] = item.instance_id
	test.check(state.total_appeal() == 0,"Illicit unidentified display cannot contribute appeal")
	state.display_assignments.clear()
	var saves: int = 0
	var store := MuseumProfileStore.in_memory()
	var save_callback := func() -> void: store.save_profile(state)
	state.changed.connect(save_callback)
	saves = store.save_count
	test.check(state.identify(item.instance_id) and item.identified and state.cash == 0 and store.save_count == saves+1,"Morning appraisal free and emits single save transaction")
	test.check(not state.identify(item.instance_id) and state.cash == 0 and store.save_count == saves+1,"Duplicate identification idempotently refused without save")
	test.check(state.assign(&"CASE_1",item.instance_id) and state.total_appeal() == 28,"55 condition rounds horse50 appeal to28")
	state.phase = MuseumState.Phase.OPEN
	test.check(not state.identify(duplicate.instance_id) and not state.repair(item.instance_id) and not duplicate.identified and item.condition == 55,"OPEN data layer forbids appraisal and repair")
	state.phase = MuseumState.Phase.NIGHT
	test.check(not state.identify(duplicate.instance_id) and not state.repair(item.instance_id),"NIGHT also refuses ground work")
	state.phase = MuseumState.Phase.EVENING
	test.check(state.identify(duplicate.instance_id),"Evening identification allowed")
	item.condition = 62
	test.check(state.restoration_cost(item.instance_id) == 240,"RARE condition62 costs ceil38/10 times60=240")
	var fragment := state.collection.add(&"guardian_fragment",1,55,true)
	test.check(state.restoration_cost(fragment.instance_id) == 500,"TREASURE condition55 restoration costs500")
	for row in [[&"republic_silver_coin",20],[&"han_jade_disc",40],[&"tang_sancai_horse",60],[&"gold_thread_jade",100]]:
		var owned := state.collection.add(row[0],1,99,true)
		test.check(state.restoration_cost(owned.instance_id) == row[1],"Rarity unit cost "+str(row[0]))
	state.cash = 239
	var before := store.encode(state)
	saves = store.save_count
	test.check(not state.repair(item.instance_id) and store.encode(state) == before and store.save_count == saves,"Insufficient funds no cash/condition/appeal/save mutation")
	state.cash = 350
	test.check(state.repair(item.instance_id) and state.cash == 110 and item.condition == 100 and state.total_appeal() == 50 and duplicate.condition == 90,"Repair exact240 atomically to100 updates displayed appeal, duplicate unaffected")
	saves = store.save_count
	test.check(not state.repair(item.instance_id) and state.cash == 110 and store.save_count == saves and state.restoration_cost(item.instance_id) == 0,"Rapid repeated repair cannot charge twice")
	test.check(MuseumState.POOL.find_by_id(&"tang_sancai_horse").exhibit_appeal == 50,"Shared definition base appeal stays50")
	var coin := state.collection.add(&"republic_silver_coin",1,0,true)
	test.check(state.appeal_for(coin.instance_id) == 1,"Legal0 condition still yields minimum1 effective appeal")
	# 实际Visitor选择按集中公式加权，固定独立种子逐一比对累积区间。
	state.assign(&"CASE_2",duplicate.instance_id)
	var cases: Array[DisplayCase] = []
	for id in [&"CASE_1",&"CASE_2"]:
		var exhibit := DisplayCase.new()
		exhibit.state = state
		exhibit.case_id = id
		cases.append(exhibit)
	var visitor := MuseumVisitor.new()
	visitor.cases = cases
	for seed in range(40):
		var reference := RandomNumberGenerator.new()
		reference.seed = seed
		reference.randi_range(1,79) # Hall selection consumes its own draw.
		var roll := reference.randi_range(1,79)
		visitor.rng.seed = seed
		test.check(visitor.choose_exhibit() == cases[0 if roll <= 50 else 1],"Visitor uses50/29 duplicate-adjusted weights after Hall selection seed%d" % seed)
	visitor.free()
	for exhibit in cases: exhibit.free()
	state.changed.disconnect(save_callback)
