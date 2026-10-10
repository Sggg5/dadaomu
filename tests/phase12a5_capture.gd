extends "res://tests/phase12a5_smoke.gd"
## Focused A-only evidence pass; original four-layout assertions remain in smoke.
var route_recording: bool=false
var route_ticks: int=0
var route_frames: int=0
func route_frame() -> void:
	if not route_recording or benchmarking: return
	route_ticks+=1
	if route_ticks%12==0 and route_frames<48:
		capture("route_%03d"%route_frames);route_frames+=1
func run() -> void:
	root.mode=Window.MODE_WINDOWED; root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i(1280,720)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT; root.content_scale_factor=1.0
	ArtRenderSettings.initialized=true; ArtRenderSettings.mode=2
	benchmarking="--benchmark" in OS.get_cmdline_user_args()
	if benchmarking:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED); Engine.max_fps=0
	process_frame.connect(observe_frame); physics_frame.connect(observe_physics)
	physics_frame.connect(route_frame)
	case_index=1; await enter_formal()
	var world:=session.world
	var layout_signature:=world.layout.signature()
	var lab=LAB.new(world); world.antique_loot.selected_rooms=[lab.room_id]
	lab.select(1); await frames(3)
	var room:=world.current_room
	var shapes:=room._wall_rects.duplicate()
	var driver=preload("res://tests/integration_input_driver.gd").new(self,world)
	pause_actors(room,true); await frames(2)
	check(root.get_texture().get_size()==Vector2(1280,720),"Native render target1280x720 independent of desktop DPI")
	ArtRenderSettings.mode=1; await frames(2); capture("static_basic")
	ArtRenderSettings.mode=2; await frames(2); capture("static_enhanced")
	ArtRenderSettings.mode=0; await frames(2); capture("legacy")
	if attached.has(room.get_instance_id()):
		var sample=attached[room.get_instance_id()].get_ref()
		check(not sample.visible,"LEGACY hides dedicated visual")
		check(room.doors.values().all(func(d:Door)->bool:return d.modulate.a==1),"LEGACY restores original actual door drawing")
	ArtRenderSettings.mode=2; await frames(2)
	# All positions below are reached by real WASD pathfinding; no teleport.
	for entry in range(4):check(await driver.walk(room.get_entry_position(entry)),"Actual walk reaches entry "+str(entry))
	route_recording=true
	for goal in [Vector2(640,180),Vector2(530,344),Vector2(640,445),Vector2(750,344),Vector2(640,245)]:
		check(await driver.walk(goal),"Real walking around main coffin "+str(goal))
		capture("walk_%d_%d"%[int(goal.x),int(goal.y)])
	route_recording=false
	check(await driver.walk(room.get_entry_position(Door.Direction.SOUTH)),"Return to actual south entrance")
	capture("door_near")
	pause_actors(room,false); await frames(2)
	motion_count=0;tick_count=0;enemy_origins.clear();perf_frames.clear();draws.clear()
	saw_warning=false;saw_projectile=false;saw_movement=false;penetrated=false
	for enemy in room.damage_targets():enemy_origins[enemy.get_instance_id()]=enemy.position
	watching=true;perf_start=Time.get_ticks_usec();perf_previous=0
	check(await driver.fight(),"Actual player weapon clears A room")
	watching=false;driver.release()
	check(saw_warning and saw_projectile and saw_movement,"Real warning/projectile/enemy activity")
	check(not penetrated,"No enemy penetration during sample combat")
	check(room._wall_rects==shapes and world.layout.signature()==layout_signature,"All geometry and formal map signatures remain unchanged")
	check(room.doors.values().all(func(d:Door)->bool:return d.is_open),"Real clear unlocks both actual doors")
	capture("cleared_open_doors")
	var cache:=room.get_node_or_null("AntiqueCache") as AntiqueCache
	check(cache!=null,"Normal clear creates test-cache via existing service")
	if cache!=null:
		check(await driver.walk(cache.position+Vector2(24,0)),"Actual walk to drop")
		key(KEY_E);await frames(3)
		check(world.player.antiques.items().size()==1,"Real E pickup, no inventory injection")
	var side: int=world.layout.rooms[lab.room_id].neighbors.find_key(world.layout.start_id)
	check(await driver.walk(room._door_position(side)),"Actual open door traversal")
	await frames(5);driver.release()
	check(world.current_id==world.layout.start_id,"Actual exit enters neighboring START")
	check(await driver.visit(lab.room_id),"Actual Door returns to cleared A sample")
	if "--old-a" not in OS.get_cmdline_user_args():
		check(world.current_room.get_node_or_null("PrincipalArtSample")!=null,"A dedicated visual survives Room destruction/revisit via test-only binding")
	check(world.current_room.remaining_count()==0,"Revisit keeps CLEARED and does not respawn enemies")
	var record:=LAB.metrics(room.geometry) if is_instance_valid(room) else LAB.metrics(load("res://tests/fixtures/phase12a4/principal_burial.tres"))
	record["resolution"]="1280x720";record["renderer"]=RenderingServer.get_current_rendering_method()
	record["texture_bytes"]=Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
	if not perf_frames.is_empty():
		perf_frames.sort();var sum:=0.0;var draw_sum:=0.0
		for value in perf_frames:sum+=value
		for value in draws:draw_sum+=value
		record["fps"]=perf_frames.size()*1000/sum
		record["p95_ms"]=perf_frames[int(perf_frames.size()*.95)]
		record["draw_calls"]=draw_sum/maxi(1,draws.size())
		record["sample_seconds"]=sum/1000
		record["render_frame_samples"]=perf_frames.size()
	var prefix: String="before" if "--old-a" in OS.get_cmdline_user_args() else "after"
	var file:=FileAccess.open(OUTPUT+prefix+("_focused_performance.json" if benchmarking else "_focused_validation.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(record,"\t"));file.close()
	print("[Phase12A5 focused] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
