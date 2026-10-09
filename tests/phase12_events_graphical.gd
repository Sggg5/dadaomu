extends "res://tests/phase_11a_smoke.gd"
func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://docs/screenshots/phase_12/%d_%s.png" % [ArtRenderSettings.mode,label])
func run() -> void:
	flow = preload("res://scenes/main/game_flow.tscn").instantiate()
	flow.profile_store = MuseumProfileStore.in_memory(); flow.campaign_seed_override = 52
	root.add_child(flow); await frames(5)
	var day = preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await day.walk_to(Vector2(940,450)); await day.walk_to(Vector2(940,210)); await day.walk_to(flow.museum.board.position+Vector2(-40,20))
	key(KEY_E); await frames(3); await choose_region(&"JINBEI"); await choose_row(0)
	await click(flow.museum.expedition_map.confirm_button.get_global_rect().get_center()); await frames(6)
	session = flow.dungeon
	var world := session.world
	var driver = preload("res://tests/integration_input_driver.gd").new(self,world)
	var found: bool = false
	for id in world.layout.rooms:
		if world.layout.rooms[id].room_type == RoomDefinition.Type.TRAP or (world.exploration != null and world.exploration.events.has(id) and world.layout.rooms[id].room_type != RoomDefinition.Type.SECRET):
			check(await driver.visit(id),"Input-only real graph/weapon/Door reaches risk room")
			check(world.current_room.risk_content != null,"Real risk-event content instantiated")
			capture("event_room"); found = true; break
	check(found,"Real generated expedition contains event-room screenshot")
	var texture := ArtAssetCatalog.texture("actors")
	ArtAssetCatalog._textures["actors"] = null; await frames(3); capture("missing_actor_fallback")
	check(not world.player.art_visual.visible,"Actual graphical missing-atlas fallback")
	ArtAssetCatalog._textures["actors"] = texture
	driver.release(); flow.queue_free(); await frames(4)
	print("[Phase12 events graphical] %d checks, %d failures" % [checks,failures]); quit(0 if failures == 0 else 1)
