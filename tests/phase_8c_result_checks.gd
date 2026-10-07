extends RefCounted
## 结果边界单项可直接构造库存；真实拾取/武器/撤离路径在flow_checks。
var test: SceneTree


func _init(context: SceneTree) -> void: test = context


func run() -> void:
	for outcome in [RunResult.Outcome.EXTRACTED,RunResult.Outcome.COMPLETED,RunResult.Outcome.DEAD]:
		var flow := preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
		flow.tomb = preload("res://tests/fixtures/legacy_two_floor_tomb.tres")
		# 旧功能固定Run夹具；正式派生Seed由9A专项另外覆盖。
		flow.forced_night_seed = 192034
		flow.campaign_seed_override = 52
		flow.profile_store = MuseumProfileStore.in_memory()
		test.root.add_child(flow)
		await test.frames(3)
		flow.start_night()
		await test.frames(5)
		var session := flow.dungeon
		for index in range(2): session.world.player.antiques.add(MuseumState.POOL.find_by_id(&"tang_sancai_horse"))
		session._finish_run(outcome)
		var result := session.complete_screen.result
		test.check(result.antique_ids.size() == 2 and result.antique_conditions.size() == 2 and result.antique_conditions[0] == AntiqueCondition.generate(session.run_seed,&"tang_sancai_horse",0,1) and result.antique_conditions[1] == AntiqueCondition.generate(session.run_seed,&"tang_sancai_horse",1,1),"Each outcome snapshots conditions aligned by cargo index: "+str(outcome))
		if outcome == RunResult.Outcome.DEAD: test.check(session.world.player.antiques.items().is_empty(),"Death keeps condition snapshot while clearing actual cargo")
		test.key(KEY_E)
		await test.frames(5)
		var state := flow.museum_state
		if outcome == RunResult.Outcome.DEAD:
			test.check(state.collection.all_items().is_empty(),"DEAD condition snapshot never becomes owned antique")
		else:
			var items := state.collection.all_items()
			test.check(items.size() == 2 and not items[0].identified and not items[1].identified and items[0].condition == result.antique_conditions[0] and items[1].condition == result.antique_conditions[1],"Successful result creates independent pending items from exact snapshots: "+str(outcome))
		flow.queue_free()
		await test.frames(3)
	# UI提示/营业阶段保护，单项夹具显式建立可展出与待鉴定对象。
	var museum := preload("res://scenes/museum/museum.tscn").instantiate() as Museum
	museum.state = MuseumState.new()
	museum.config = MuseumConfig.new()
	var waiting := museum.state.collection.add(&"tang_sancai_horse",1,60)
	var shown := museum.state.collection.add(&"republic_silver_coin",1,60,true)
	museum.state.assign(&"CASE_1",shown.instance_id)
	test.root.add_child(museum)
	await test.frames(3)
	museum.business.start()
	var before := museum.state.cash
	museum.appraisal.interact()
	museum.restoration.interact()
	test.check(museum.message.text == "营业中无法进行馆藏作业" and not museum.appraisal_panel.panel.visible and not museum.restoration_panel.panel.visible and not waiting.identified and shown.condition == 60 and museum.state.cash == before,"Actual interactables reject OPEN work with explicit prompt and no transaction")
	museum.queue_free()
	await test.frames(3)
