extends "res://tests/phase_11a_smoke.gd"
## Real GameFlow/map/door entry. Freeze encounter physics only for identical
## rendered snapshots; this is a rendering benchmark, not combat-play FPS.
func freeze_physics(node: Node) -> void:
	node.set_physics_process(false)
	for child in node.get_children(): freeze_physics(child)
func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://docs/screenshots/phase_12a2/%d_%s.png" % [ArtRenderSettings.mode,label])
func run() -> void:
	if DisplayServer.get_name() == "headless": push_error("Benchmark needs actual graphical renderer"); quit(1); return
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
	var start := world.current_room
	var direction: int = start.doors.keys()[0]
	check(await driver.walk(start._door_position(direction)),"Real movement enters connected room for benchmark")
	await frames(10); driver.release()
	freeze_physics(world)
	var signature := world.layout.signature()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var results: Array = []
	for choice in [[0,false],[1,true],[1,false],[2,true],[2,false]]:
		var mode: int = choice[0]
		var old_space: bool = choice[1]
		world.current_room.art_visual.use_old_space = old_space
		ArtRenderSettings.mode = mode
		await create_timer(1).timeout
		var values: Array[float] = []; var draw_calls: Array[float] = []; var cpu_values: Array[float] = []
		var begun := Time.get_ticks_usec()
		var previous := begun
		while Time.get_ticks_usec()-begun < 3000000:
			await process_frame
			var now := Time.get_ticks_usec()
			values.append((now-previous)/1000.0)
			previous = now
			draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
			cpu_values.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
		values.sort()
		var elapsed := (Time.get_ticks_usec()-begun)/1000000.0
		var draws := 0.0; var cpu := 0.0
		for value in draw_calls: draws += value
		for value in cpu_values: cpu += value
		results.append({"mode":mode,"old_space":old_space,"scene":"same frozen real first Combat","seed":522269330,"resolution":"1280x720","vsync":"disabled","frames":values.size(),"seconds":elapsed,"fps":values.size()/elapsed,"p95_frame_ms":values[int(values.size()*.95)],"process_ms_mean":cpu/maxi(1,cpu_values.size()),"draw_calls_mean":draws/maxi(1,draw_calls.size()),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT)})
		check(world.layout.signature() == signature,"Same layout and encounter for mode "+str(mode))
		capture("same_combat_old" if old_space else "same_combat_new")
	var file := FileAccess.open("res://docs/screenshots/phase_12a2/performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t")); file.close()
	flow.queue_free(); await frames(4)
	print("[Phase12A2 benchmark] %d checks, %d failures" % [checks,failures]); quit(0 if failures == 0 else 1)
