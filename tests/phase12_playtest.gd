extends "res://tests/phase_11a_smoke.gd"
## Opens real formal GameFlow via actual map UI, entirely memory-only.
func run() -> void:
	ArtRenderSettings.initialized = true
	ArtRenderSettings.mode = ArtRenderSettings.Mode.ENHANCED
	flow = preload("res://scenes/main/game_flow.tscn").instantiate()
	flow.profile_store = MuseumProfileStore.in_memory(); flow.campaign_seed_override = 52
	root.add_child(flow); await frames(5)
	var day = preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await day.walk_to(Vector2(940,450)); await day.walk_to(Vector2(940,210)); await day.walk_to(flow.museum.board.position+Vector2(-40,20))
	key(KEY_E); await frames(3); await choose_region(&"JINBEI"); await choose_row(0)
	await click(flow.museum.expedition_map.confirm_button.get_global_rect().get_center()); await frames(6)
	check(flow.dungeon != null,"Memory-only formal map enters Jinbei")
	session = flow.dungeon
	var world := session.world
	var driver = preload("res://tests/integration_input_driver.gd").new(self,world)
	var start := world.current_room
	await driver.walk(start._door_position(start.doors.keys()[0])); await frames(6); driver.release()
	check(world.current_room.room_type == RoomDefinition.Type.COMBAT,"Actual Door enters first Combat for manual review")
	DisplayServer.window_set_title("大盗墓时代 · Phase12A.2返修 · Seed522269330 · 空格开始 · F6旧/基础/光影 · 隔离内存档")
	# Pause only the isolated handoff, so waiting for a human never kills the player.
	var overlay := CanvasLayer.new(); overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	var button := Button.new(); button.text = "Phase12A.2：第一战斗房 · 点击或空格开始试玩"
	button.position = Vector2(390,610); button.size = Vector2(500,45)
	var shortcut := Shortcut.new(); var event := InputEventKey.new(); event.keycode = KEY_SPACE
	shortcut.events = [event]; button.shortcut = shortcut
	overlay.add_child(button); root.add_child(overlay)
	button.pressed.connect(func() -> void: paused = false; overlay.queue_free())
	paused = true
