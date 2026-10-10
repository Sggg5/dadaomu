extends "res://tests/phase12a6_capture.gd"
## Real input bait, not a pose/state injection. Separate from the normal fight.
func clip_prefix() -> String:return "probe"
func capture(label:String) -> void:
	if benchmarking or DisplayServer.get_name()=="headless":return
	RenderingServer.force_draw();root.get_texture().get_image().save_png(DEST+"probe_"+label+".png")
func run() -> void:
	root.size=Vector2i(1280,720);root.content_scale_size=Vector2i(1280,720)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_factor=1
	ArtRenderSettings.initialized=true;ArtRenderSettings.mode=2
	process_frame.connect(observe_frame);physics_frame.connect(observe_physics)
	case_index=1;await enter_formal()
	var world:=session.world;var lab=LAB.new(world);lab.select(1);await frames(3)
	preload("res://tests/support/phase12a5_binding.gd").install(world)
	preload("res://tests/support/phase12a6_binding.gd").install(world)
	var room:=world.current_room
	var driver=preload("res://tests/integration_input_driver.gd").new(self,world)
	watching=true
	check(await driver.walk(Vector2(480,260)),"Actual WASD approaches scarab without actor teleport")
	driver.release()
	for i in range(36):
		await frames(1)
		if actual_states.has("scarab") and actual_states["scarab"].has("attack"):break
	check(actual_states.has("scarab") and actual_states["scarab"].has("windup"),"Actual scarab AI enters bite windup")
	check(actual_states.has("scarab") and actual_states["scarab"].has("attack"),"Actual scarab bite recovery drives attack animation")
	check(not world.player.health.is_dead,"Original80HP player survives brief bait, no invulnerability injection")
	check(await driver.fight(),"Real weapon clears baited original five-enemy encounter")
	# Record the original death-animation tail and genuinely unlocked doors too.
	driver.release();await frames(15);watching=false
	check(room.remaining_count()==0 and room.doors.values().all(func(d:Door)->bool:return d.is_open),"Natural clear opens real doors after all death nodes expire")
	check(room.get_children().all(func(n:Node)->bool:return not n.name.begins_with("EnemyArt_")),"Dead sibling bodies and warning nodes unload safely")
	check(room.get_children().all(func(n:Node)->bool:return not n.name.begins_with("EnemyWarning_")),"No dead-enemy warning siblings remain after natural release")
	var f:=FileAccess.open(DEST+"probe_states.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"states":actual_states,"checks":checks,"failures":failures,"hp":world.player.health.current_hp,"frame_metrics":battle_metrics},"\t"));f.close()
	print("[Phase12A6 actual attack] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
