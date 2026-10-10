extends "res://tests/phase_11a_smoke.gd"
## Real regional map entry; direct Boss assembly is a visual boundary fixture only.
func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://docs/screenshots/phase_12a2/"+label+".png")
func run() -> void:
	ArtRenderSettings.initialized=true; ArtRenderSettings.mode=2
	for site_id in [&"LUOYANG_EAST",&"GUANZHONG_MOUND"]:
		flow=preload("res://scenes/main/game_flow.tscn").instantiate()
		flow.profile_store=MuseumProfileStore.in_memory(); flow.campaign_seed_override=52
		root.add_child(flow); await frames(5)
		var day=preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
		await day.walk_to(Vector2(940,450)); await day.walk_to(Vector2(940,210)); await day.walk_to(flow.museum.board.position+Vector2(-40,20))
		key(KEY_E); await frames(3); await choose_region(flow.site_registry.site(site_id).region_id); await choose_row(0)
		await click(flow.museum.expedition_map.confirm_button.get_global_rect().get_center()); await frames(6)
		session=flow.dungeon
		check(session.site_loot_profile.id!=&"FORMAL_DEFAULT","Real regional site profile "+str(site_id))
		var world:=session.world
		check(not world.current_room.art_visual.jinbei_space(),"Regional START excludes Jinbei structures")
		var driver=preload("res://tests/integration_input_driver.gd").new(self,world)
		var start:=world.current_room
		await driver.walk(start._door_position(start.doors.keys()[0])); await frames(8); driver.release()
		check(not world.current_room.art_visual.jinbei_space(),"Real Door preserves regional room style")
		capture(str(site_id)+"_combat_unchanged")
		# No claim of a weapon journey for this single assembly edge case.
		world._switch_room(world.layout.boss_id,-1); await frames(4)
		check(world.current_room.room_type==RoomDefinition.Type.BOSS,"Actual Boss scene fixture")
		check(not world.current_room.art_visual.jinbei_space() and world.current_room.art_visual.space_surfaces.is_empty(),"Motif-free regional arena excludes new Jinbei walls/props")
		check(world.hud.get_node("Root/Seed").position.y==106,"Regional original header preserved")
		capture(str(site_id)+"_arena_unchanged")
		flow.queue_free(); await frames(4)
	print("[Phase12A2 regional] %d checks, %d failures"%[checks,failures]); quit(0 if failures==0 else 1)
