extends "res://tests/phase_11a_smoke.gd"
## Real formal map/door/weapon inputs. Comparison freezes enemies only.
var movie_index: int = 0
func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://docs/screenshots/phase_12a1/"+label+".png")
func enemies_physics(node: Node, enabled: bool) -> void:
	if node is Enemy: node.set_physics_process(enabled)
	for child in node.get_children(): enemies_physics(child,enabled)
func run() -> void:
	ArtRenderSettings.initialized = true; ArtRenderSettings.mode = ArtRenderSettings.Mode.BASIC
	flow = preload("res://scenes/main/game_flow.tscn").instantiate()
	flow.profile_store = MuseumProfileStore.in_memory(); flow.campaign_seed_override = 52
	root.add_child(flow); await frames(5)
	var day = preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await day.walk_to(Vector2(940,450)); await day.walk_to(Vector2(940,210)); await day.walk_to(flow.museum.board.position+Vector2(-40,20))
	key(KEY_E); await frames(3); await choose_region(&"JINBEI"); await choose_row(0)
	await click(flow.museum.expedition_map.confirm_button.get_global_rect().get_center()); await frames(6)
	session = flow.dungeon
	check(session.run_seed == 522269330,"Fixed Jinbei seed")
	var world := session.world
	var driver = preload("res://tests/integration_input_driver.gd").new(self,world)
	var start := world.current_room
	await driver.walk(start._door_position(start.doors.keys()[0])); await frames(10); driver.release()
	check(world.current_room.room_type == RoomDefinition.Type.COMBAT,"Actual Door enters first Combat")
	enemies_physics(world.current_room,false)
	var v := world.player.art_visual
	var floor_visual := world.current_room.art_visual
	v.use_old_art = true; floor_visual.use_old_floor = true; floor_visual._build_floor(); await frames(3); capture("before_body_floor")
	floor_visual.use_old_floor = false; floor_visual._build_floor(); await frames(3); capture("after_floor_old_body")
	v.use_old_art = false
	for size in [15,20,25]:
		v.size_variant = size; await frames(3); capture("body_"+str(size))
	v.size_variant = 20
	enemies_physics(world.current_room,true)
	check(await driver.fight(),"Real weapon clears Combat, moving and shooting")
	await driver.walk(Vector2(640,470)); driver.release(); await frames(5)
	var directions := [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT,Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1),Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]
	for i in range(directions.size()):
		var d: Vector2 = directions[i].normalized()
		var aim := -d if i < 8 else d.rotated(PI/2)
		driver.steer(d)
		Input.action_press("attack")
		var motion := InputEventMouseMotion.new(); motion.position = world.player.position+aim*180
		root.push_input(motion,true)
		for frame in range(12):
			await frames(1)
			if frame%3==0:
				capture("motion_%03d" % movie_index); movie_index += 1
		driver.release(); await frames(10)
		capture("direction_"+str(i))
		check(world.player.aim_direction.dot(aim) > .9,"Backward/diagonal aim " + str(i))
		await driver.walk(Vector2(640,470)); driver.release(); await frames(5)
	var idle_row: int = v.body_row
	for i in range(8):
		var motion := InputEventMouseMotion.new(); motion.position = world.player.position+Vector2.from_angle(i*TAU/8)*180
		root.push_input(motion,true); Input.action_press("attack"); await frames(8); driver.release()
		check(v.body_row == idle_row,"Standing mouse rotation preserves body")
		capture("standing_"+str(i))
	for mode in range(3):
		ArtRenderSettings.mode = mode; await frames(3); capture("mode_"+str(mode))
	ArtRenderSettings.mode = 2
	await frames(20); key(KEY_F1); await frames(2); capture("hurt_redflash")
	check(world.player.art_visual.sprite.modulate != Color.WHITE,"Real debug damage produces readable hurt tint")
	# Dedicated terminal visual fixture, after the actual combat/input journey.
	await frames(20); world.player.take_damage(1000); await frames(2); capture("death_pose")
	check(world.player.art_visual.last_cell.x == 3,"Actual death signal selects stable death pose")
	flow.queue_free(); await frames(4)
	print("[Phase12A1 graphical] %d checks, %d failures" % [checks,failures]); quit(0 if failures==0 else 1)
