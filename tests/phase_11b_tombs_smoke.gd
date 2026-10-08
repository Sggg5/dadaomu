extends "res://tests/phase_9b32_smoke.gd"
func capture(label:String)->void:
	if DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://logs/11b_%s.png"%label)
func run()->void:
	var paths:Array[String]=["luoyang"]
	if FileAccess.file_exists("res://data/regional/guanzhong/tomb.tres"):paths.append("guanzhong")
	for region in paths:
		var tomb:=load("res://data/regional/"+region+"/tomb.tres") as TombDefinition
		check(tomb.validation_error().is_empty() and tomb.floors.size()==2,"Regional tomb fully configured: "+region)
		for seed_value in range(20):
			for number in [1,2]:
				var layout:=TombFloorGenerator.generate(seed_value,number,tomb)
				var plan:=RoomGeometryPlan.build(seed_value,number,layout,tomb.floor_at(number).geometry_pool)
				check(layout!=null and layout.spatial_signature()==TombFloorGenerator.generate(seed_value,number,tomb).spatial_signature(),"Regional topology deterministic")
				for id in layout.ordered_ids():
					if layout.rooms[id].room_type==RoomDefinition.Type.COMBAT:
						var geometry:RoomGeometryDefinition=plan.assigned[id]
						var placement:=EnemySpawnPlacement.build(layout.rooms[id].definition,geometry)
						check(placement.error.is_empty() and placement.positions.size()==layout.rooms[id].definition.spawns.size(),"Regional encounter has legal nonoverlapping spawns")
		for seed_value in [33,52]:
			session=preload("res://scenes/main/dungeon_test.tscn").instantiate()
			session.tomb=tomb
			session.seed_value=seed_value
			root.add_child(session)
			await frames(3)
			for number in [1,2]:
				var driver=preload("res://tests/threat_fight_driver.gd").new(self)
				driver.avoid_optional_rooms=true
				var world:=session.world
				driver.picked.assign(world.player.relics.inventory.ids())
				await driver.visit(world.layout.relic_id)
				for id in world.layout.ordered_ids():
					if world.layout.rooms[id].room_type==RoomDefinition.Type.COMBAT:
						await driver.visit(id)
						capture(region+"_F"+str(number)+"_"+str(id))
				await driver.visit(world.layout.antique_id)
				var cargo=preload("res://tests/phase_7b_run_driver.gd").new(self)
				await cargo.take_current({"room":world.current_id,"source":&"antique_room","definition":world._pick_antique(world.current_id,&"antique_room")})
				await driver.visit(world.layout.boss_id)
				await driver.boss_fight()
				var exit:=world.current_room.get_node("RunExit" if number==2 else "ExpeditionExit") as Node2D
				world.player.position=exit.position+Vector2(24,0)
				key(KEY_E)
				await frames(5)
			check(session.run_ended and session.bosses_defeated==2 and session.complete_screen.result.outcome==RunResult.Outcome.COMPLETED,"Actual two-floor exploration/weapons/Boss/cargo completes: "+region)
			session.queue_free()
			await frames(4)
	print("[Regional tombs] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
