extends "res://tests/phase_11a_smoke.gd"
## Formal clean new game: no money/collection/stats/teleport injections.
func capture(label:String)->void:
	if DisplayServer.get_name()=="headless" or "--capture" not in OS.get_cmdline_user_args():return
	RenderingServer.force_draw();root.get_texture().get_image().save_png("res://logs/11i_flow_%s.png"%label)
func run()->void:
	flow=preload("res://scenes/main/game_flow.tscn").instantiate()
	flow.profile_store=MuseumProfileStore.in_memory();flow.campaign_seed_override=52
	root.add_child(flow);await frames(5)
	var state:=flow.museum_state
	check(state.day_number==1 and state.cash==0 and state.collection.all_items().is_empty(),"Formal Day1 empty collection / zero cash")
	check(state.display_assignments.is_empty() and state.achievements.is_empty(),"No free exhibits or honors")
	capture("empty_start")
	var day=preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await day.walk_to(Vector2(1080,540));key(KEY_E);await frames(3)
	check(state.phase==MuseumState.Phase.MORNING and state.cash==0,"Empty museum cannot open; no ticket income")
	await day.walk_to(Vector2(940,450));await day.walk_to(Vector2(940,210));await day.walk_to(flow.museum.board.position+Vector2(-40,20))
	key(KEY_E);await frames(3);await choose_region(&"JINBEI");await choose_row(0)
	await click(flow.museum.expedition_map.confirm_button.get_global_rect().get_center());await frames(6)
	session=flow.dungeon
	check(session!=null and flow.current_phase==MuseumState.Phase.NIGHT,"Actual board/map mouse confirmation enters night")
	capture("first_tomb")
	var driver=preload("res://tests/integration_input_driver.gd").new(self,session.world)
	var reached:bool=await driver.visit(session.world.layout.antique_id)
	check(reached,"Input-only WASD/weapon/Door reaches first antique room")
	if reached:
		var pickup:=session.world.current_room.get_node_or_null("AntiquePedestal") as AntiquePedestal
		check(pickup!=null,"Real generated antique available")
		if pickup!=null:
			check(await driver.walk(pickup.position+Vector2(24,0)),"Walk to antique without teleport")
			key(KEY_E);await frames(3)
			check(not session.world.player.antiques.items().is_empty(),"Real E pickup into empty eight-slot bag")
			capture("first_loot")
		check(await driver.visit(session.world.layout.boss_id),"Input-only combat reaches and defeats first Boss")
		var exit:=session.world.current_room.get_node_or_null("ExpeditionExit") as ExpeditionExit
		if exit!=null:
			check(await driver.walk(exit.position+Vector2(24,0)),"Walk to unlocked extraction")
			key(KEY_F);await frames(5);key(KEY_E);await frames(8)
			check(flow.museum!=null and state.day_number==2 and not state.collection.all_items().is_empty(),"Actual extraction returns Day2 with earned collection")
			if flow.museum!=null and not state.collection.all_items().is_empty():
				var item:=state.collection.all_items()[0]
				await day.walk_to(Vector2(920,450));await day.walk_to(Vector2(920,230));await day.walk_to(Vector2(540,230))
				key(KEY_E);await frames(3)
				var appraisal:=flow.museum.appraisal_panel
				check(appraisal.panel.visible,"Actual E opens free identification")
				await click(appraisal.list.get_global_rect().position+appraisal.list.get_item_rect(0).get_center())
				await click(appraisal.confirm_button.get_global_rect().get_center())
				check(item.identified and state.cash==0,"Actual click identifies without money deadlock")
				capture("first_identified")
				key(KEY_TAB);await frames(3)
				await day.walk_to(Vector2(920,230));await day.walk_to(Vector2(920,380))
				var placed:=false
				for display in flow.museum.cases:
					await day.walk_to(Vector2(display.position.x,380));await day.walk_to(display.position+Vector2(0,48))
					key(KEY_E);await frames(3)
					var panel:=flow.museum.collection_panel
					if panel.panel.visible and not panel._ids.is_empty() and not panel._slot_ids.is_empty():
						await click(panel.list.get_global_rect().position+panel.list.get_item_rect(0).get_center())
						await click(panel.slot_list.get_global_rect().position+panel.slot_list.get_item_rect(0).get_center())
						await click(panel.panel.get_node("VBoxContainer/Choose").get_global_rect().get_center())
						placed=state.case_for(item.instance_id)!=&""
					key(KEY_TAB);await frames(3)
					if placed:break
				check(placed,"Real combined display UI places first earned artifact")
				capture("first_display")
				await day.walk_to(Vector2(1080,380));await day.walk_to(Vector2(1080,540))
				key(KEY_E);await frames(3)
				check(state.phase==MuseumState.Phase.OPEN,"Actual ticket desk opens with one earned artifact")
				for frame in range(6000):
					await frames(1)
					if state.phase==MuseumState.Phase.EVENING:break
				check(state.cash>0 and state.daily_reports.has(2),"Formal duration / real visitors produce first settled income")
				capture("first_income")
				var store:=MuseumProfileStore.new();store.save_path="res://logs/11i_earned_%d.json"%Time.get_ticks_usec()
				check(store.save_profile(state),"Earned-only midgame checkpoint safely isolated")
				print("[Earned checkpoint path] ",store.save_path)
				print("[Earned checkpoint] cash=",state.cash," artifacts=",state.collection.all_items().size()," day=",state.day_number)
	driver.release()
	if "--progression" in OS.get_cmdline_user_args():
		await preload("res://tests/phase_11i_progression.gd").new(self).run()
	print("[11I1] %d checks, %d failures"%[checks,failures])
	flow.queue_free();await frames(3);quit(0 if failures==0 else 1)
