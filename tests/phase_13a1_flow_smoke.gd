extends "res://tests/phase_13a_flow_smoke.gd"
## Real production GameFlow/input only. No item/HP/position/stat injection.
var case_name: String = "MOJIN"
var clip_tick: int = 0
var clip_count: int = 0
func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	RenderingServer.force_draw();root.get_texture().get_image().save_png("res://logs/13a1_%s_%s.png"%[case_name,label])
func record() -> void:
	if not recording or DisplayServer.get_name()=="headless":return
	clip_tick+=1
	if clip_tick%8==0:
		capture("frame_%04d"%clip_count);clip_count+=1
func open_flow(id: StringName, seed_value: int) -> void:
	flow=preload("res://scenes/main/game_flow.tscn").instantiate();flow.profile_store=MuseumProfileStore.in_memory();flow.campaign_seed_override=52;flow.forced_night_seed=seed_value
	root.add_child(flow);await frames(5);recording=true
	await depart(id)
	check(session.initial_profession_id==id and session.profession_state.active_id==id,"Actual selection snapshot activates "+str(id))
	capture("initial")
func choose_class(id: StringName) -> void:
	key(KEY_G);await frames(3)
	for button in session.world.profession_panel.choices.get_children():
		if button.text.contains(ProfessionRegistry.display_name(id)):
			capture("choose_"+str(id));await click(button.get_global_rect().get_center());await frames(3);return
	check(false,"Requested collected class exists "+str(id))
func enter_combat(driver) -> bool:
	var world: RoomController=session.world
	var queue:Array[StringName]=[world.current_id]
	var parents:Dictionary={world.current_id:&""}
	var goal:StringName=&""
	while not queue.is_empty():
		var id:StringName=queue.pop_front()
		if world.layout.rooms[id].room_type==RoomDefinition.Type.COMBAT and world.states[id].status==RoomState.Status.UNVISITED:goal=id;break
		for other in world.layout.rooms[id].neighbors.values():
			if not parents.has(other):parents[other]=id;queue.append(other)
	if goal==&"":return false
	var route:Array[StringName]=[];var cursor:=goal
	while cursor!=world.current_id:route.push_front(cursor);cursor=parents[cursor]
	for next_id in route:
		var side:int=world.layout.rooms[world.current_id].neighbors.find_key(next_id)
		var direction:Vector2=[Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT][side]
		var door:Vector2=Room.ROOM_RECT.get_center()+direction*Vector2(576,224)
		if not await driver.walk(door-direction*40):return false
		driver.steer(direction)
		for i in range(120):
			await driver.tick()
			if world.current_id==next_id:break
		driver.release();await frames(3)
		if world.current_room.remaining_count()>0:return true
	return false
func deliberate_damage(driver, count: int=2) -> void:
	var runtime: ProfessionRuntime=session.world.profession_runtime
	for i in range(1800):
		for actor in session.world.current_room.damage_targets():
			if is_instance_valid(actor) and actor is Enemy and not actor.health.is_dead:
				driver.steer((actor.position-session.world.player.position).normalized());break
		await driver.tick()
		if runtime.damage_events.size()>=count or session.run_ended:break
	driver.release()
func deferred_capture(label: String) -> void:
	await frames(1);capture(label)
func passive_case(id: StringName) -> void:
	await open_flow(id,192034)
	var world:RoomController=session.world
	var runtime:ProfessionRuntime=world.profession_runtime
	var driver=preload("res://tests/integration_input_driver.gd").new(self,world)
	key(KEY_G);await frames(3);capture("ability_description");key(KEY_G);await frames(3)
	if id==&"BANSHAN":
		check(world.player.profession_movement_multiplier==1.08,"Actual Banshan movement bonus installed")
		driver.steer(Vector2.RIGHT)
		var observed_speed:float=0
		for i in range(25):await driver.tick();observed_speed=maxf(observed_speed,world.player.velocity.length())
		driver.release()
		check(is_equal_approx(observed_speed,world.player.stats.move_speed*1.08),"Real input reaches exactly 108 percent baseline speed")
	check(await enter_combat(driver),"Actual Doors enter first ordinary combat")
	var room_id:=world.current_id
	if id==&"FAQIU":
		await deliberate_damage(driver)
		check(runtime.damage_events.size()>=2 and not world.player.health.is_dead,"Real enemies produce two nonfatal damage events")
		if runtime.damage_events.size()>=2:
			var first:Dictionary=runtime.damage_events[0];var second:Dictionary=runtime.damage_events[1]
			check(is_equal_approx(first.actual,first.input*.7) and second.factor==1.0 and is_equal_approx(second.actual,second.input),"Real first incoming hit reduced30 percent, second unmodified")
			print("[Actual FAQIU] ",runtime.damage_events)
		capture("first_damage");check(await driver.fight(),"Real weapon clears hurt-tested room")
		check(await driver.visit(world.layout.start_id) and await driver.visit(room_id),"True Door revisit without respawning enemies")
		check(not runtime.first_visit and runtime.received_damage(10)==10,"Revisit cannot regain reduction")
		capture("revisited")
	else:
		var observed:Array=[]
		var ready_captured:Array=[false]
		var on_hit:Callable=func(_ctx):
			if session.profession_state.banshan_ready and not ready_captured[0]:
				ready_captured[0]=true;deferred_capture.call_deferred("four_hits_ready")
		var on_spawn:Callable=func(projectile):
			if bool(projectile.get_meta(ProfessionRuntime.EMPOWERED,false)):
				observed.append(projectile.damage);deferred_capture.call_deferred("enhanced_attack")
		world.player.relics.projectile_hit.connect(on_hit);world.player.relics.projectile_spawned.connect(on_spawn)
		check(await driver.fight(),"Real Banshan movement/aim/weapon clears room")
		check(ready_captured[0] and not observed.is_empty() and is_equal_approx(observed[0],world.player.stats.attack_damage*1.25),"Actual four-hit preparation and25 percent enhanced physical projectile")
		check(session.profession_state.used(&"BANSHAN:EMPOWER")>=1,"Actual fired enhancement recorded in expedition ledger")
		print("[Actual BANSHAN] enhanced=",observed," uses=",session.profession_state.used(&"BANSHAN:EMPOWER"))
		world.player.relics.projectile_hit.disconnect(on_hit);world.player.relics.projectile_spawned.disconnect(on_spawn)
		capture("combat_complete")
	driver.release();recording=false;flow.queue_free();await frames(4)
func visit_retry(driver, destination: StringName) -> bool:
	for attempt in range(3):
		if await driver.visit(destination): return true
		print("[Input route interruption] room=",session.world.current_id," goal=",destination," hp=",session.world.player.health.current_hp)
		if session.world.player.health.is_dead:return false
		driver.release();await frames(5)
	return false
func pickup_antique(driver) -> bool:
	if not await visit_retry(driver,session.world.layout.antique_id):return false
	var pickup=session.world.current_room.get_node_or_null("AntiquePedestal")
	if pickup==null:return false
	if not await driver.walk(pickup.position+Vector2(24,0)):return false
	var source: StringName = pickup.source_id
	key(KEY_E);await frames(3);return session.world.current_room.room_state.is_loot_claimed(source)
func xieling_case() -> void:
	var seed_value:=19
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):seed_value=arg.trim_prefix("--seed=").to_int()
	await open_flow(&"XIELING",seed_value)
	var driver
	for floor_index in range(1,3):
		var world:RoomController=session.world
		driver=preload("res://tests/profession_input_driver.gd").new(self,world);driver.collect_rewards=true
		var item_reached: bool = await visit_retry(driver,world.layout.relic_id)
		check(item_reached,"Actual item-room relic strengthens Build")
		if not item_reached:return
		var antique_reached: bool = await pickup_antique(driver)
		check(antique_reached,"Actual E acquires floor antique")
		if not antique_reached:return
		var cache_reached: bool = await visit_retry(driver,world.antique_loot.selected_rooms[0])
		check(cache_reached,"Actual clear/E acquires floor cache")
		if not cache_reached:return
		if floor_index==1:
			for id in world.layout.ordered_ids():
				if world.layout.rooms[id].room_type==RoomDefinition.Type.COMBAT and id!=world.layout.terminal_id:
					var cleared: bool = await visit_retry(driver,id)
					check(cleared,"Earn milestone Build by actual first-floor exploration")
					if not cleared:return
		var reached:bool=await visit_retry(driver,world.layout.boss_id)
		check(reached,"Real weapon defeats Xieling floor%d Boss"%floor_index)
		if not reached:return
		if floor_index==1:
			var exit=world.current_room.get_node("ExpeditionExit")
			check(await driver.walk(exit.position+Vector2(24,0)),"Walk to real first floor exit")
			key(KEY_E);await frames(6)
			check(session.floor_number==2 and session.profession_state.active_id==&"XIELING","Actual first cross-layer keeps class and artifacts")
	var profession_state := session.profession_state
	var inventory:AntiqueInventory=session.world.player.antiques
	var ids:Array=[]
	for item in inventory.items():ids.append(item.id)
	var value:=inventory.total_value()
	check(inventory.used_slots()==10 and inventory.capacity==10,"Four actual sourced pickups exactly fill10 slots")
	capture("ten_slots")
	await choose_class(&"NONE")
	check(inventory.used_slots()==10 and inventory.total_value()==value and inventory.capacity==8 and not inventory.can_add(RoomController.ANTIQUE_POOL.find_by_id(&"republic_silver_coin")) and session.world.player.encounter_movement_modifiers[ProfessionRuntime.OVERLOAD_KEY]==.8,"Actual UI unload keeps10 slots/value and applies80 percent overload with pickup restriction")
	capture("overload")
	var exit=session.world.current_room.get_node("ExpeditionExit")
	check(await driver.walk(exit.position+Vector2(24,0)),"Real walk to chosen exit with overload")
	if case_name=="XIELING_DEATH":
		key(KEY_E);await frames(6)
		var new_ids:Array=[]
		for item in session.world.player.antiques.items():new_ids.append(item.id)
		check(session.floor_number==3 and new_ids==ids and session.world.player.antiques.total_value()==value and session.world.player.antiques.used_slots()==10 and session.world.player.antiques.capacity==8,"Actual overloaded10-slot carry to third floor has no lost items")
		capture("overloaded_floor3")
		await choose_class(&"XIELING")
		check(session.world.player.antiques.capacity==10 and session.world.player.encounter_movement_modifiers[ProfessionRuntime.OVERLOAD_KEY]==.95,"Actual re-equip returns normal10-slot loading")
		driver=preload("res://tests/profession_input_driver.gd").new(self,session.world)
		check(await enter_combat(driver),"True third-floor Door enters lethal combat")
		await deliberate_damage(driver,100)
		check(session.run_ended and session.world.player.antiques.items().is_empty() and session.profession_state.tokens().is_empty(),"Real enemy death clears carried antiques and faction state via original loss rules")
		capture("actual_death")
	else:
		key(KEY_F);await frames(5)
		check(session.run_ended and flow.current_dungeon_result.antique_value==value,"Actual extraction result preserves full10-slot value")
		key(KEY_E);await frames(7)
		var returned:Array=[]
		for item in flow.museum_state.collection.all_items():returned.append(item.definition_id)
		check(returned==ids and flow.museum_state.collection.all_items().size()==4 and profession_state.tokens().is_empty(),"All four independently owned artifacts return to museum and tokens clear")
		capture("returned_collection")
	driver.release();recording=false
func run() -> void:
	root.size=Vector2i(1280,720);root.content_scale_size=Vector2i(1280,720);root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--case="):case_name=arg.trim_prefix("--case=")
	if case_name=="MOJIN":
		await super.run();print("[Phase13A1 clip MOJIN] frames=%d"%clip_count);return
	physics_frame.connect(record)
	if case_name in ["FAQIU","BANSHAN"]:await passive_case(StringName(case_name))
	else:await xieling_case()
	print("[Phase13A1 actual %s] %d checks, %d failures clip_frames=%d"%[case_name,checks,failures,clip_count]);quit(0 if failures==0 else 1)
