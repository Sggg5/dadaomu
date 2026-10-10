extends "res://tests/phase_11a_smoke.gd"
## Four layouts, memory-only GameFlow. Every selection starts a fresh fixture Run.
const LAB=preload("res://tests/support/phase12a4_lab.gd")
var busy: bool=false
var lab_ui: CanvasLayer
var notice: Label
var layout_buttons: Array[Button]=[]
var active_index: int=0
func run() -> void:
	lab_ui=CanvasLayer.new(); lab_ui.process_mode=Node.PROCESS_MODE_ALWAYS; root.add_child(lab_ui)
	var seed_guard=preload("res://tests/support/phase12a4_seed_guard.gd").new(); lab_ui.add_child(seed_guard)
	notice=Label.new(); notice.position=Vector2(64,8); notice.add_theme_font_size_override("font_size",18)
	lab_ui.add_child(notice)
	for i in range(4):
		var button:=Button.new()
		button.text=["旧四角","A 主棺","B 盗掘","C 侧室"][i]
		button.position=Vector2(560+i*150,5); button.size=Vector2(140,32)
		button.pressed.connect(show_layout.bind(i)); lab_ui.add_child(button); layout_buttons.append(button)
	var help:=Label.new(); help.text="WASD移动 · 鼠标瞄准 / 左键射击\nTab背包 · 先空格开始，再F6切换"
	help.position=Vector2(64,643); help.add_theme_font_size_override("font_size",16); lab_ui.add_child(help)
	var start:=Button.new(); start.text="空格：开始/暂停 · 切布局重置隔离本局 · F6三模式"
	start.position=Vector2(430,646); start.size=Vector2(650,40)
	var shortcut:=Shortcut.new(); var key_event:=InputEventKey.new(); key_event.physical_keycode=KEY_SPACE
	shortcut.events=[key_event]; start.shortcut=shortcut
	start.pressed.connect(func() -> void: paused=not paused)
	lab_ui.add_child(start)
	var restart:=Button.new(); restart.text="重开本实验 [R]"
	restart.position=Vector2(1100,646); restart.size=Vector2(160,40)
	var restart_shortcut:=Shortcut.new(); var restart_key:=InputEventKey.new(); restart_key.physical_keycode=KEY_R
	restart_shortcut.events=[restart_key]; restart.shortcut=restart_shortcut
	restart.pressed.connect(func() -> void: show_layout(active_index))
	lab_ui.add_child(restart)
	await show_layout(0)
	if "--verify-switches" in OS.get_cmdline_user_args():
		for i in range(4):
			await click(layout_buttons[i].get_global_rect().get_center())
			for count in range(4000):
				if not busy: break
				await frames(1)
			check(not busy and paused,"Actual layout button completes fresh paused fixture "+str(i))
			var expected: StringName=&"SIDE_CRYPTS" if i==0 else (load(LAB.POOL_PATH) as RoomGeometryPool).geometries[i-1].id
			check(session.world.current_room.geometry.id==expected,"Mouse selection loads requested geometry "+str(i))
			check(session.world.player.health.current_hp==80 and session.run_seed==522269330,"Fresh fixture preserves base HP and seed")
			await frames(2) # Allow the final notice to reach the native renderer.
			RenderingServer.force_draw(); root.get_texture().get_image().save_png("res://docs/screenshots/phase_12a4/%d_lab_selector.png"%i)
		key(KEY_R); await frames(2)
		for count in range(4000):
			if not busy: break
			await frames(1)
		check(not busy and session.world.current_room.geometry.id==&"LAB_V1_SIDE_CHAMBER","R restarts selected isolated layout")
		key(KEY_N); await frames(4)
		check(session.run_seed==522269330 and session.world.current_room.geometry.id==&"LAB_V1_SIDE_CHAMBER","N cannot accidentally leave fixed-seed laboratory")
		print("[Phase12A4 selector] %d checks, %d failures"%[checks,failures]); quit(0 if failures==0 else 1)
func show_layout(index: int) -> void:
	if busy: return
	busy=true; active_index=index; paused=false; notice.text="正在装配隔离布局…"
	if is_instance_valid(flow): flow.queue_free(); await frames(3)
	ArtRenderSettings.initialized=true; ArtRenderSettings.mode=2
	flow=preload("res://scenes/main/game_flow.tscn").instantiate()
	flow.profile_store=MuseumProfileStore.in_memory(); flow.campaign_seed_override=52
	root.add_child(flow); await frames(5)
	var day=preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await day.walk_to(Vector2(940,450)); await day.walk_to(Vector2(940,210)); await day.walk_to(flow.museum.board.position+Vector2(-40,20))
	key(KEY_E); await frames(3); await choose_region(&"JINBEI"); await choose_row(0)
	await click(flow.museum.expedition_map.confirm_button.get_global_rect().get_center()); await frames(6)
	session=flow.dungeon
	var driver=preload("res://tests/integration_input_driver.gd").new(self,session.world)
	var room:=session.world.current_room
	await driver.walk(room._door_position(room.doors.keys()[0])); driver.release(); await frames(4)
	var lab=LAB.new(session.world)
	session.world.antique_loot.selected_rooms=[lab.room_id] # Explicit isolated pickup fixture.
	lab.select(index); await frames(4)
	for path in ["Root/Title","Root/Seed","Root/Progress","Root/EncounterDepth","Root/RestartButton","Root/QuitButton","Root/Minimap","Root/Instructions","Root/Legend"]:
		session.world.hud.get_node(path).hide()
	notice.text="12A.4 DRAFT · "+["旧四角对照","A 主棺墓室","B 盗掘墓室","C 侧室/陪葬室"][index]
	DisplayServer.window_set_title("大盗墓时代 · 12A.4布局实验V1 · Seed522269330 · 隔离内存档")
	busy=false; paused=true
