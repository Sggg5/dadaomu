extends "res://tests/phase_11a_smoke.gd"
func run()->void:
	flow=preload("res://scenes/main/game_flow.tscn").instantiate()
	flow.profile_store=MuseumProfileStore.in_memory()
	flow.forced_night_seed=52
	flow.museum_config=MuseumConfig.new()
	flow.museum_config.open_duration=5
	flow.museum_config.visitor_speed=1200
	flow.museum_config.view_duration=.1
	flow.profile_store._memory=flow.profile_store.encode(preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(50))
	root.add_child(flow)
	await frames(3)
	var daytime=preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await daytime.walk_to(Vector2(1080,540))
	key(KEY_E)
	await frames(500)
	check(flow.current_phase==MuseumState.Phase.EVENING and flow.museum_state.daily_reports.size()==1,"GameFlow actual opening closes and auto-persists one report")
	var before_cash:=flow.museum_state.cash
	var plans:=flow.museum_state.exhibition_plans.duplicate()
	var assignments:=flow.museum_state.display_assignments.duplicate()
	await daytime.walk_to(Vector2(940,450))
	await daytime.walk_to(Vector2(940,210))
	await daytime.walk_to(flow.museum.board.position+Vector2(-40,20))
	key(KEY_E)
	await frames(3)
	await choose_region(&"LUOYANG")
	await choose_row(0)
	await click(flow.museum.expedition_map.confirm_button.get_global_rect().get_center())
	await frames(5)
	session=flow.dungeon
	check(session!=null and session.site_loot_profile!=null,"Actual map still enters regional tomb after themed business")
	var driver=preload("res://tests/threat_fight_driver.gd").new(self)
	driver.avoid_optional_rooms=true
	var world:=session.world
	await driver.visit(world.layout.relic_id)
	for id in world.layout.ordered_ids():
		if world.layout.rooms[id].room_type==RoomDefinition.Type.COMBAT:await driver.visit(id)
	await driver.visit(world.layout.antique_id)
	var cargo=preload("res://tests/phase_7b_run_driver.gd").new(self)
	var definition:=world._pick_antique(world.current_id,&"antique_room")
	await cargo.take_current({"room":world.current_id,"source":&"antique_room","definition":definition})
	check(world.player.antiques.items().has(definition),"Real regional E pickup remains available")
	await driver.visit(world.layout.boss_id)
	await driver.boss_fight()
	var exit:=world.current_room.get_node("ExpeditionExit") as Node2D
	world.player.position=exit.position+Vector2(24,0)
	key(KEY_F)
	await frames(5)
	check(session.run_ended,"Actual Boss exit extraction finishes Run")
	key(KEY_E)
	await frames(5)
	check(flow.current_day==2 and flow.dungeon==null and flow.museum_state.collection.all_items().size()>50,"Actual cargo returns to Day2 museum")
	check(flow.museum_state.cash==before_cash and flow.museum_state.exhibition_plans==plans and flow.museum_state.display_assignments==assignments and flow.museum_state.daily_reports.size()==1,"Returning keeps topics and historical report without repeated income or rearrangement")
	var reloaded:=flow.profile_store.load_profile()
	check(not flow.profile_store.write_blocked and reloaded.exhibition_plans==plans and reloaded.daily_reports.size()==1,"V6 GameFlow return auto-save reads management and regional cargo")
	flow.queue_free()
	flow=null
	session=null
	driver=null
	daytime=null
	cargo=null
	await frames(5)
	print("[11D flow] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
