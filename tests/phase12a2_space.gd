extends "res://tests/phase_11a_smoke.gd"
## Actual memory GameFlow, map, doors and weapons. No gameplay value injection.
func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://docs/screenshots/phase_12a2/"+label+".png")
	if label=="input_combat" and session!=null and session.world.current_room.room_type==RoomDefinition.Type.BOSS:
		root.get_texture().get_image().save_png("res://docs/screenshots/phase_12a2/boss_battle.png")
func colliders(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children():
		if child is CollisionShape2D: result.append([child.position,str(child.shape),child.disabled])
		result.append_array(colliders(child))
	return result
func pause_enemies(node: Node, pause: bool) -> void:
	if node is Enemy: node.set_physics_process(not pause)
	for child in node.get_children(): pause_enemies(child,pause)
func run() -> void:
	ArtRenderSettings.initialized=true; ArtRenderSettings.mode=1
	flow=preload("res://scenes/main/game_flow.tscn").instantiate()
	flow.profile_store=MuseumProfileStore.in_memory(); flow.campaign_seed_override=52
	root.add_child(flow); await frames(5)
	var day=preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await day.walk_to(Vector2(940,450)); await day.walk_to(Vector2(940,210)); await day.walk_to(flow.museum.board.position+Vector2(-40,20))
	key(KEY_E); await frames(3); await choose_region(&"JINBEI"); await choose_row(0)
	await click(flow.museum.expedition_map.confirm_button.get_global_rect().get_center()); await frames(6)
	session=flow.dungeon
	var world:=session.world
	check(session.run_seed==522269330,"Fixed actual Jinbei seed")
	var signature:=world.layout.signature()
	var driver=preload("res://tests/integration_input_driver.gd").new(self,world)
	driver.collect_rewards=true
	var start:=world.current_room
	await driver.walk(start._door_position(start.doors.keys()[0])); await frames(10); driver.release()
	check(world.current_room.room_type==RoomDefinition.Type.COMBAT,"Actual Door enters standard Combat")
	var room:=world.current_room
	var visual:=room.art_visual
	var before:=colliders(room)
	pause_enemies(room,true)
	visual.use_old_space=true; await frames(3); capture("combat_before")
	visual.use_old_space=false; await frames(3); capture("combat_basic")
	ArtRenderSettings.mode=2; await frames(3); capture("combat_enhanced")
	check(world.hud.get_node("Root/Seed").position.y==72,"Actual compact header clears raised north wall")
	check(colliders(room)==before,"Structural illustration leaves collision bodies/shapes unchanged")
	check(visual.space_surfaces.size()==room._wall_rects.size()+1,"One surface per original rectangle plus floor")
	var kinds: Dictionary={}
	for surface in visual.space_surfaces:
		if surface is TombSpacePiece:
			check(surface.footprint in room._wall_rects,"Every structural surface has an original collision footprint")
			if surface.kind!="wall": kinds[surface.kind]=true
	check(kinds.size()>=2 or room.obstacles().size()<2,"Different obstacle roles avoid four cloned crates")
	visual.region_space_enabled=false
	check(not visual.jinbei_space(),"Regional override excludes motif-free Boss arenas")
	visual.region_space_enabled=true
	check(visual.space_floor.z_index<0,"Contact/wear layer stays below combat telegraphs")
	for mode in range(3):
		ArtRenderSettings.mode=mode; await frames(3)
		check(colliders(room)==before,"Mode "+str(mode)+" preserves collisions")
		check(visual.visible==(mode!=0),"Fallback visibility mode "+str(mode))
	ArtRenderSettings.mode=2
	var warning := BossTelegraph.new(); room.add_child(warning); warning.set_physics_process(false)
	await frames(2)
	check(warning.z_index==1100,"Actual native telegraph stays above raised geometry")
	check(warning.warning==.8 and warning.damage==12,"Warning priority does not change timing/damage")
	ArtRenderSettings.mode=0; await frames(2)
	check(warning.z_index==300,"Legacy restores original warning Z")
	check(world.hud.get_node("Root/Seed").position.y==106,"Legacy restores original HUD layout")
	warning.queue_free(); await frames(2); ArtRenderSettings.mode=2
	pause_enemies(room,false)
	check(await driver.fight(),"Real weapon clears first combat in reconstructed space")
	check(await driver.walk(Vector2(400,178)),"Real movement along north wall")
	driver.release(); await frames(3); capture("player_wall")
	if not room.obstacles().is_empty():
		var r: Rect2=room.obstacles()[0]
		check(await driver.walk(Vector2(r.end.x+40,r.get_center().y)),"Real movement beside coffin collision footprint")
		driver.release(); await frames(3); capture("player_coffin")
	var side: int=room.doors.keys()[0]
	check(await driver.walk(room.get_entry_position(side)),"Door approach remains reachable")
	driver.release(); await frames(3); capture("player_door")
	var antique: StringName=&""; var event: StringName=&""; var boss: StringName=&""
	for id in world.layout.rooms:
		var type: int=world.layout.rooms[id].room_type
		if type==RoomDefinition.Type.ANTIQUE: antique=id
		if type==RoomDefinition.Type.BOSS: boss=id
		if world.exploration.events.has(id) and type!=RoomDefinition.Type.SECRET: event=id
	check(not antique.is_empty() and not event.is_empty() and not boss.is_empty(),"Actual graph provides all four sample types")
	check(await driver.visit(event),"Real Door/weapon journey reaches event room")
	capture("event_room")
	check(await driver.visit(antique),"Real Door journey reaches Antique room")
	capture("antique_room")
	check(world.current_room.remaining_count()==0,"Antique stays safe/open")
	check(await driver.visit(boss),"Actual combat journey defeats Boss in original arena")
	capture("boss_room")
	check(world.layout.signature()==signature,"Visual reconstruction leaves topology and definitions unchanged")
	check(world.player.stats.max_hp==80 and world.player.antiques.capacity==8,"HP/bag frozen")
	check(MuseumProfileStore.VERSION==10,"Profile stays10")
	driver.release(); flow.queue_free(); await frames(4)
	print("[Phase12A2 space] %d checks, %d failures" % [checks,failures]); quit(0 if failures==0 else 1)
