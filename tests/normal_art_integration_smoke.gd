extends "res://tests/phase_11a_smoke.gd"
## Real production entry and unchanged production GeometryPlan; no lab injection.
var recording: bool = false
var capture_ticks: int = 0
var capture_frames: int = 0
func screenshot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://logs/normal_art_" + label + ".png")
func record_frame() -> void:
	if not recording or DisplayServer.get_name() == "headless": return
	capture_ticks += 1
	if capture_ticks % 6 == 0 and capture_frames < 100:
		screenshot("battle_%03d" % capture_frames)
		capture_frames += 1
func run() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	physics_frame.connect(record_frame)
	ArtRenderSettings.initialized = true
	ArtRenderSettings.mode = 2
	flow = preload("res://scenes/main/game_flow.tscn").instantiate()
	flow.profile_store = MuseumProfileStore.in_memory()
	flow.campaign_seed_override = 52
	root.add_child(flow)
	await frames(5)
	var day = preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await day.walk_to(Vector2(940,450))
	await day.walk_to(Vector2(940,210))
	await day.walk_to(flow.museum.board.position + Vector2(-40,20))
	key(KEY_E)
	await frames(3)
	await choose_region(&"JINBEI")
	await choose_row(0)
	await click(flow.museum.expedition_map.confirm_button.get_global_rect().get_center())
	await frames(6)
	session = flow.dungeon
	check(session.run_seed == 522269330,"Normal expedition retains original Seed")
	var world = session.world
	var signature: String = world.layout.signature()
	var start_id: StringName = world.current_id
	var driver = preload("res://tests/integration_input_driver.gd").new(self,world)
	var start: Room = world.current_room
	await driver.walk(start._door_position(start.doors.keys()[0]))
	driver.release()
	await frames(6)
	var room: Room = world.current_room
	var room_id: StringName = world.current_id
	check(room_id != start_id and room.room_type == RoomDefinition.Type.COMBAT,"Actual Door enters normal Combat")
	check(not str(room.geometry.id).begins_with("LAB_"),"Unchanged production geometry, no experimental injection")
	var shapes: Array = room._wall_rects.duplicate()
	var geometry: RoomGeometryDefinition = room.geometry
	check(room.has_node("TombQualityVisual"),"Normal Jinbei room automatically installs highest-quality architecture")
	check(room.has_node("CombatFeedbackVisual"),"Normal weapon feedback installed")
	# Visual-only fixture: use the real Burn renderer without advancing its DOT.
	var marked: Enemy = room.damage_targets()[0]
	var burn := Burn.new()
	burn.target = marked
	burn.set_physics_process(false)
	marked.add_child(burn)
	burn.set_physics_process(false)
	await frames(2)
	check(marked.modulate.a == 1 and marked.self_modulate.a == 0,"Replacement hides body only, preserving inherited status-effect opacity")
	check(burn.visible and burn.modulate.a == 1,"Actual Burn child renderer remains visible")
	screenshot("burn_status")
	for actor in room.damage_targets():
		if actor.definition.id in [&"scarab", &"corpse_dog"]:
			check(room.has_node("EnemyArt_" + str(actor.get_instance_id())),"Normal enemy receives dedicated body " + str(actor.definition.id))
			check(actor.body_radius() == 14,"Original enemy collision retained")
	for mode in [1,2,0,2]:
		ArtRenderSettings.mode = mode
		await frames(2)
		check(room.get_node("TombQualityVisual").visible == (mode != 0),"Quality/Legacy architecture mode " + str(mode))
		check(room.doors.values().all(func(d: Door) -> bool: return d.modulate.a == (1 if mode == 0 else 0)),"Real gate drawing switches without duplicate door " + str(mode))
		check(burn.z_index == (0 if mode == 0 else 925) and burn.z_as_relative == (mode == 0),"Burn layering switches above body and restores Legacy " + str(mode))
		if mode in [1,2]: screenshot("mode_%d" % mode)
	burn.queue_free()
	recording = true
	check(await driver.fight(),"Original weapon clears normal first encounter with new bodies")
	driver.release()
	await frames(15)
	recording = false
	check(room.remaining_count() == 0 and room.doors.values().all(func(d: Door) -> bool: return d.is_open),"Actual clear opens doors")
	check(room._wall_rects == shapes and world.layout.signature() == signature,"Visual promotion changes no collision or map signature")
	check(room.get_children().all(func(n: Node) -> bool: return not n.name.begins_with("EnemyArt_") and not n.name.begins_with("EnemyWarning_")),"Death clears new body and warnings")
	screenshot("cleared")
	check(await driver.visit(start_id),"Real doorway remains passable")
	await frames(5)
	check(world.current_id == start_id,"Returns to normal START")
	check(await driver.visit(room_id),"Revisit via real normal Door")
	check(world.current_room.remaining_count() == 0 and world.current_room.has_node("TombQualityVisual"),"CLEARED revisit keeps quality and no enemy respawn")
	# Each original geometry is checked as a pure fitting query, not injected into maps.
	var pool: RoomGeometryPool = load("res://data/geometries/ordinary_pool.tres")
	var prop_script = preload("res://scripts/art/tomb_quality_prop.gd")
	for layout in pool.geometries:
		check(RoomGeometryValidation.validation_error(layout).is_empty(),"Original geometry connectivity " + str(layout.id))
		for rect in layout.obstacles:
			var prop = prop_script.new()
			prop.footprint = rect
			prop.texture = ArtAssetCatalog.texture("a5_principal")
			var fitted: Rect2 = prop.fitted_rect()
			check(fitted.size.x <= rect.size.x + .01 and fitted.end.y == rect.end.y and fitted.position.y >= rect.position.y - 24.01,"Uniform fit respects original footprint " + str(layout.id))
			prop.free()
	check(geometry == load(geometry.resource_path),"Shared production Geometry resource remains unchanged")
	print("[Normal art integration] %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
