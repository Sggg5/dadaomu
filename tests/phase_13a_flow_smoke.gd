extends "res://tests/phase_11a_smoke.gd"
var recording: bool = false
var frame_tick: int = 0
var record_count: int = 0
func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://logs/13a_" + label + ".png")
func record() -> void:
	if not recording or DisplayServer.get_name() == "headless": return
	frame_tick += 1
	if frame_tick % 30 == 0 and record_count < 500:
		capture("flow_%03d" % record_count); record_count += 1
func depart(faction: StringName) -> void:
	var day = preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await day.walk_to(Vector2(940,450)); await day.walk_to(Vector2(940,210)); await day.walk_to(flow.museum.board.position+Vector2(-40,20))
	key(KEY_E); await frames(3); await choose_region(&"JINBEI"); await choose_row(0)
	await click(flow.museum.expedition_map.profession_choice.buttons[faction].get_global_rect().get_center())
	check(flow.museum.expedition_map.profession_choice.selected_id==faction,"Real ground class selection " + str(faction))
	capture("choose_" + str(faction))
	await click(flow.museum.expedition_map.confirm_button.get_global_rect().get_center()); await frames(6)
	session = flow.dungeon
func run() -> void:
	root.size=Vector2i(1280,720); root.content_scale_size=Vector2i(1280,720); root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
	physics_frame.connect(record)
	flow=preload("res://scenes/main/game_flow.tscn").instantiate(); flow.profile_store=MuseumProfileStore.in_memory(); flow.campaign_seed_override=52
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--campaign="): flow.campaign_seed_override = arg.trim_prefix("--campaign=").to_int()
		if arg.begins_with("--run-seed="): flow.forced_night_seed = arg.trim_prefix("--run-seed=").to_int()
	root.add_child(flow); await frames(5)
	recording=true
	await depart(&"MOJIN")
	check(flow.active_expedition.initial_profession_id==&"MOJIN" and session.initial_profession_id==&"MOJIN","Class survives GameFlow copied snapshot and Session")
	var state := session.profession_state
	check(state.tokens()==[&"MOJIN"] and state.active_id==&"MOJIN" and session.world.player.profession_wall_multiplier==1.0,"Initial Mojin token genuinely active in normal tomb")
	check(not state.tokens().has(&"BANSHAN") and session.world.player.antiques.items().is_empty(),"No discovered token or free antiques initially")
	var world := session.world
	var signature: String = world.layout.signature()
	var corpse_room: StringName = world.profession_corpses.assigned.keys()[0]
	var found_faction: StringName = world.profession_corpses.assigned[corpse_room]
	check(corpse_room!=&"","Normal floor contains one reachable second-faction predecessor")
	var driver=preload("res://tests/integration_input_driver.gd").new(self,world)
	driver.collect_rewards = true
	check(await driver.visit(corpse_room),"Real weapon/Door reaches and clears predecessor room")
	var corpse=world.current_room.get_node("ProfessionCorpse")
	check(await driver.walk(corpse.position+Vector2(30,0)),"Real walk reaches corpse interaction range")
	capture("before_search"); key(KEY_E); await frames(3)
	check(state.has_token(found_faction) and state.active_id==&"MOJIN" and state.identities().size()==1,"Actual E searches identity and token without automatic equip")
	capture("after_search")
	world.profession_panel.panel.hide()
	# Use a real existing wall-mark room to exercise the Mojin consumption ledger.
	var marked_room: StringName = &""
	for id in world.exploration.wall_marks:
		if not world.exploration.wall_marks[id].is_empty(): marked_room=id; break
	check(marked_room!=&"" and await driver.visit(marked_room),"Actual normal exploration reaches a wall-mark room")
	key(KEY_Q); await frames(3)
	check(state.used(&"MOJIN:CLUE:F1")==1,"Real Q spends this floor effective Mojin clue once")
	key(KEY_G); await frames(2)
	var choice: Button
	for button in world.profession_panel.choices.get_children():
		if button.text.contains(ProfessionRegistry.display_name(found_faction)): choice=button
	check(choice!=null,"Collected second faction appears in independent token UI")
	await click(choice.get_global_rect().get_center()); await frames(2)
	check(state.active_id==found_faction and world.player.antiques.capacity==10,"Real UI switch disables Mojin Q and installs collected Xieling capacity")
	key(KEY_Q); await frames(2)
	check(state.active_id==found_faction and state.used(&"MOJIN:CLUE:F1")==1,"Passive new faction cannot consume or reset Mojin clue")
	capture("second_faction_active")
	key(KEY_G); await frames(2)
	for button in world.profession_panel.choices.get_children():
		if button.text.contains("摸金校尉"): choice=button
	await click(choice.get_global_rect().get_center()); await frames(2)
	check(state.active_id==&"MOJIN" and state.used(&"MOJIN:CLUE:F1")==1 and world.player.profession_wall_multiplier==1.0,"Switch back restores Mojin ability but not this-floor consumed use")
	key(KEY_Q); await frames(2); check(state.used(&"MOJIN:CLUE:F1")==1,"Repeated ability after re-equip cannot replenish ledger")
	capture("mojin_used_preserved")
	check(world.layout.signature()==signature,"Profession exploration leaves normal topology signature unchanged")
	check(await driver.visit(world.layout.relic_id),"Actual item room builds earned relics before deeper combat")
	var first_boss_reached: bool = await driver.visit(world.layout.boss_id)
	check(first_boss_reached,"Normal weapon defeats first-floor Boss")
	if not first_boss_reached:
		print("[Phase13A real flow] %d checks, %d failures"%[checks,failures]); quit(1); return
	var exit=world.current_room.get_node("ExpeditionExit")
	check(await driver.walk(exit.position+Vector2(24,0)),"Actual walk to floor exit")
	key(KEY_E); await frames(7)
	check(session.floor_number==2 and session.profession_state==state and state.has_token(found_faction) and state.used(&"MOJIN:CLUE:F1")==1 and state.clues.has(1),"Real floor transition preserves tokens, class, first-floor ledger and clue")
	capture("floor2_preserved")
	key(KEY_Q); await frames(3)
	check(state.used(&"MOJIN:CLUE:F2")==1 and state.used(&"MOJIN:CLUE:F1")==1,"Actual second floor has separate clue allowance and retains spent first-floor use")
	driver=preload("res://tests/integration_input_driver.gd").new(self,session.world)
	driver.collect_rewards = true
	check(await driver.visit(session.world.layout.relic_id),"Actual Floor2 item room improves earned Build")
	var reached: bool = await driver.visit(session.world.layout.boss_id)
	check(reached,"Normal Floor2 Boss clears for real extraction")
	if not reached:
		print("[Phase13A real flow] %d checks, %d failures"%[checks,failures]); quit(1); return
	exit=session.world.current_room.get_node("ExpeditionExit")
	check(await driver.walk(exit.position+Vector2(24,0)),"Actual walk to extraction")
	key(KEY_F); await frames(5)
	check(session.run_ended and state.tokens().is_empty() and state.consumption_ledger().is_empty(),"Real extraction ends and clears profession run state")
	key(KEY_E); await frames(7)
	check(flow.museum!=null and flow.active_expedition==null,"Returns normal museum with no retained expedition choice")
	await depart(&"NONE")
	check(session.profession_state.tokens().is_empty() and session.profession_state.active_id==&"NONE","Actual next departure can choose no faction and gets no previous token")
	# Genuine death: walk through the actual START Door, then stop firing/dodging.
	driver=preload("res://tests/integration_input_driver.gd").new(self,session.world)
	world=session.world
	var previous: StringName = &""
	for step in range(10):
		if world.current_room.remaining_count()>0: break
		var neighbors: Dictionary = world.layout.rooms[world.current_id].neighbors
		var side: int = neighbors.keys()[0]
		for candidate_side in neighbors:
			var candidate_id: StringName = neighbors[candidate_side]
			if candidate_id != previous: side=candidate_side
			if world.layout.rooms[candidate_id].room_type==RoomDefinition.Type.COMBAT:
				side=candidate_side; break
		var destination: StringName = neighbors[side]
		var direction: Vector2 = [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT][side]
		var door: Vector2 = Room.ROOM_RECT.get_center()+direction*Vector2(576,224)
		check(await driver.walk(door-direction*40),"Next run walks to actual open Door")
		previous=world.current_id
		driver.steer(direction)
		for i in range(120):
			await driver.tick()
			if world.current_id==destination: break
		driver.release()
		check(world.current_id==destination,"Actual next-run Door traversal")
	check(world.current_room.remaining_count()>0,"Real next-run Doors reach live combat")
	for i in range(12000):
		var victims := world.current_room.damage_targets()
		for actor in victims:
			if is_instance_valid(actor) and actor is Enemy and not actor.health.is_dead:
				driver.steer((actor.position-world.player.position).normalized()); break
		await driver.tick()
		if session.run_ended: break
	driver.release()
	capture("actual_combat_death")
	check(session.run_ended and session.profession_state.tokens().is_empty(),"Death clears profession state through actual Session death lifecycle")
	recording=false
	print("[Phase13A real flow] %d checks, %d failures"%[checks,failures]); quit(0 if failures==0 else 1)
