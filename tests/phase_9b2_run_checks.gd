extends RefCounted
var test:SceneTree
func _init(context:SceneTree)->void:test=context
func run()->void:
	var flow:=preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
	flow.tomb=preload("res://tests/fixtures/pre_threat_tomb.tres")
	flow.profiled_relic_rewards=false
	flow.profile_store=MuseumProfileStore.in_memory()
	flow.campaign_seed_override=52
	flow.forced_night_seed=33
	test.root.add_child(flow)
	test.current_scene=flow
	await test.frames(3)
	await preload("res://tests/phase_8a_flow_checks.gd").new(test,flow).night()
	var session:=flow.dungeon
	var boss_rewards:=0
	for number in range(1,6):
		var driver=preload("res://tests/density_fight_driver.gd").new(test)
		driver.avoid_optional_rooms=true
		driver.picked.assign(session.world.player.relics.inventory.ids())
		var world:=session.world
		await driver.visit(world.layout.relic_id)
		test.check(world.current_room.enemy_spawner.get_remaining()==0 and world.current_room.room_state.status==RoomState.Status.CLEARED,"Actual relic room safe and freely leaveable")
		var combats:Array[StringName]=[]
		for id in world.layout.ordered_ids():
			if world.layout.rooms[id].room_type==RoomDefinition.Type.COMBAT:combats.append(id)
		for id in combats:await driver.visit(id)
		await driver.visit(world.layout.antique_id)
		var cargo=preload("res://tests/phase_7b_run_driver.gd").new(test)
		for id in [world.layout.antique_id,world.antique_loot.selected_rooms[0]]:
			await driver.visit(id)
			var source:StringName=&"antique_room" if id==world.layout.antique_id else &"combat_cache"
			await cargo.take_current({"room":id,"source":source,"definition":world._pick_antique(id,source)})
		await driver.visit(world.layout.boss_id)
		var before:=world.player.relics.inventory.ids().size()
		await driver.boss_fight()
		boss_rewards+=1
		test.check(world.player.relics.inventory.ids().size()==before+1,"Every Boss including final gives one real relic")
		var rest:=world.current_room.get_node_or_null("RestPoint") as RestPoint
		if rest!=null:
			world.player.position=rest.position+Vector2(24,0)
			test.key(KEY_E)
			await test.frames(2)
		print("[9B.2 live] F%d rooms=%d HP=%.2f relics=%d combat=%d cargo=%d" % [number,world.layout.rooms.size(),world.player.health.current_hp,world.player.relics.inventory.ids().size(),session.rewards.combat_clears,world.player.antiques.total_value()])
		test.capture("floor_%d_build" % number)
		var exit:=world.current_room.get_node("RunExit" if number==5 else "ExpeditionExit") as Node2D
		world.player.position=exit.position+Vector2(24,0)
		test.key(KEY_E)
		await test.frames(5)
	test.check(session.run_ended and session.bosses_defeated==5 and session.complete_screen.result.floors_cleared==5 and boss_rewards==5,"Complete five-floor flow now clears five real Bosses")
	test.check(session.world.player.relics.inventory.ids().size()==13 and session.rewards.rewards_given==3,"Full exploration earns thirteen unique formal relics with five Boss rewards")
	test.key(KEY_E)
	await test.frames(5)
	test.check(flow.current_day==2 and flow.dungeon==null,"Five Boss run returns to real Day2 Museum")
	flow.queue_free()
	await test.frames(3)
