extends "res://tests/phase_11a_smoke.gd"
## Real doors, weapons, movement, enemies and E pickup; memory fixtures only.
const LAB=preload("res://tests/support/phase12a4_lab.gd")
var case_index: int=0
var records: Array=[]
var watching: bool=false
var tick_count: int=0
var motion_count: int=0
var saw_warning: bool=false
var saw_projectile: bool=false
var saw_movement: bool=false
var saw_avoidance: bool=false
var penetrated: bool=false
var enemy_origins: Dictionary={}
var perf_start: int=0
var perf_previous: int=0
var perf_frames: Array[float]=[]
var draws: Array[float]=[]
var benchmarking: bool=false
func capture(label: String) -> void:
	if benchmarking or DisplayServer.get_name()=="headless": return
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://docs/screenshots/phase_12a4/%d_%s.png" % [case_index,label])
func observe_frame() -> void:
	if not watching or session==null: return
	var room:=session.world.current_room
	saw_projectile=saw_projectile or room.projectiles.get_child_count()>0
	for entry in room.art_visual.warning_layers.values():
		var hazard=entry[0].get_ref()
		if is_instance_valid(hazard) and hazard is EncounterHazard and hazard.phase==EncounterHazard.Phase.WARN:
			if not saw_warning and not benchmarking: capture("actual_warning")
			saw_warning=true
	if benchmarking:
		var now:=Time.get_ticks_usec()
		if now-perf_start>=1000000 and now-perf_start<4000000:
			if perf_previous>0: perf_frames.append((now-perf_previous)/1000.0)
			draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		perf_previous=now
func observe_physics() -> void:
	if not watching or session==null: return
	tick_count+=1
	var room:=session.world.current_room
	if tick_count%12==0 and motion_count<24 and not benchmarking:
		capture("motion_%03d" % motion_count); motion_count+=1
	for enemy in room.damage_targets():
		if not enemy is Enemy or enemy.health.is_dead: continue
		var id:=enemy.get_instance_id()
		if enemy_origins.has(id) and enemy.position.distance_to(enemy_origins[id])>12: saw_movement=true
		saw_avoidance=saw_avoidance or enemy._avoid_remaining>0
		var point:=room.to_local(enemy.global_position)
		# Exact circle/rectangle distance, not the square inflated-corner approximation.
		if room.obstacles().any(func(rect:Rect2)->bool:return point.distance_to(point.clamp(rect.position,rect.end))<enemy.body_radius()-.5): penetrated=true
func pause_actors(room: Room, value: bool) -> void:
	for node in room.enemy_spawner.get_children():
		node.set_physics_process(not value)
		var shape:=node.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape!=null: shape.set_deferred("disabled",value)
	for node in room.hazards.get_children(): node.set_physics_process(not value)
func enter_formal() -> void:
	flow=preload("res://scenes/main/game_flow.tscn").instantiate()
	flow.profile_store=MuseumProfileStore.in_memory(); flow.campaign_seed_override=52
	root.add_child(flow); await frames(5)
	var day=preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await day.walk_to(Vector2(940,450)); await day.walk_to(Vector2(940,210)); await day.walk_to(flow.museum.board.position+Vector2(-40,20))
	key(KEY_E); await frames(3); await choose_region(&"JINBEI"); await choose_row(0)
	await click(flow.museum.expedition_map.confirm_button.get_global_rect().get_center()); await frames(6)
	session=flow.dungeon
	var world:=session.world
	var driver=preload("res://tests/integration_input_driver.gd").new(self,world)
	var start:=world.current_room
	await driver.walk(start._door_position(start.doors.keys()[0])); driver.release(); await frames(4)
func run() -> void:
	ArtRenderSettings.initialized=true; ArtRenderSettings.mode=2
	benchmarking="--benchmark" in OS.get_cmdline_user_args()
	if benchmarking:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED); Engine.max_fps=0
	process_frame.connect(observe_frame); physics_frame.connect(observe_physics)
	var lab_pool:=load(LAB.POOL_PATH) as RoomGeometryPool
	check(lab_pool.validation_error().is_empty(),"Independent lab pool has stable valid IDs")
	for geometry in lab_pool.geometries:
		check(RoomGeometryValidation.validation_error(geometry).is_empty(),"Flood/4-entry validation "+str(geometry.id))
		var entries: Array[Vector2]=[Vector2(640,208),Vector2(1152,368),Vector2(640,528),Vector2(128,368)]
		check(geometry.environments.all(func(env:EncounterHazardDefinition)->bool:return entries.all(func(p:Vector2)->bool:return p.distance_to(env.position)>env.radius+16)),"Environmental warning leaves all entry body footprints clear")
	var tomb=preload("res://data/tombs/default_tomb.tres")
	var formal_pool=preload("res://data/geometries/ordinary_pool.tres")
	for seed_value in range(100):
		var layout:=TombFloorGenerator.generate(seed_value,1,tomb)
		var signature:=layout.signature()
		var formal:=RoomGeometryPlan.build(seed_value,1,layout,formal_pool).signature()
		var first:=RoomGeometryPlan.build(seed_value,1,layout,lab_pool).signature()
		check(first==RoomGeometryPlan.build(seed_value,1,layout,lab_pool).signature(),"Lab plan deterministic seed "+str(seed_value))
		check(layout.signature()==signature and RoomGeometryPlan.build(seed_value,1,layout,formal_pool).signature()==formal,"Lab plan does not perturb formal map/geometry "+str(seed_value))
	for index in range(4):
		case_index=index; await enter_formal()
		var world:=session.world
		check(not world.hud.damage_button.visible,"Formal GameFlow hides test damage button")
		key(KEY_F2); await frames(2)
		check(not world.get_node("RelicDebugPanel").formal_panel.visible,"Formal GameFlow cannot expose debug relic buttons")
		var layout_sig:=world.layout.signature()
		var formal_sig:=RoomGeometryPlan.build(session.run_seed,1,world.layout,world.geometry_pool).signature()
		var lab=LAB.new(world)
		# Explicit drop-placement fixture, not a production cache-budget change.
		world.antique_loot.selected_rooms=[lab.room_id]
		lab.select(index); await frames(3)
		var room:=world.current_room
		var driver=preload("res://tests/integration_input_driver.gd").new(self,world)
		pause_actors(room,true)
		var record: Dictionary=LAB.metrics(room.geometry)
		record["case"]=index
		check(room.remaining_count()==room.definition.spawns.size(),"Same encounter spawn count for case "+str(index))
		check(room.enemy_spawner.placement_error.is_empty(),"Actual spawner finds legal positions")
		for actor in room.damage_targets():
			check(room.obstacles().all(func(rect:Rect2)->bool:return not rect.grow(actor.body_radius()-1).has_point(room.to_local(actor.global_position))),"Enemy outside actual collision")
		ArtRenderSettings.mode=1; await frames(2); capture("static_basic")
		ArtRenderSettings.mode=2; await frames(2); capture("static_enhanced")
		check(room.get_node("Walls").get_child_count()==room._wall_rects.size(),"Actual rectangular colliders match every structural footprint")
		if not benchmarking and DisplayServer.get_name()!="headless":
			var overlay=preload("res://tests/support/phase12a4_collision_overlay.gd").new()
			overlay.room=room; room.add_child(overlay); await frames(2)
			capture("colliders_debug"); overlay.queue_free(); await frames(2)
		for side in range(4):
			check(await driver.walk(room.get_entry_position(side)),"Real movement reaches entry "+str(side))
		capture("door_approach")
		for rect in room.obstacles():
			var padded:=rect.grow(34)
			for point in [padded.position,Vector2(padded.end.x,padded.position.y),padded.end,Vector2(padded.position.x,padded.end.y)]:
				if Room.ROOM_RECT.grow(-25).has_point(point) and room.obstacles().all(func(r:Rect2)->bool:return not r.grow(23).has_point(point)):
					check(await driver.walk(point),"Actual character goes around obstacle corner")
		capture("obstacle_circuit")
		check(await driver.walk(room.get_entry_position(Door.Direction.SOUTH)),"Geometry tour ends away from reserved enemy spawns")
		pause_actors(room,false)
		await frames(2)
		check(room.damage_targets().all(func(actor:Node2D)->bool:return not actor.get_node("CollisionShape2D").disabled),"All enemy bodies restored for real combat")
		saw_warning=false; saw_projectile=false; saw_movement=false; saw_avoidance=false; penetrated=false
		motion_count=0; tick_count=0; enemy_origins.clear(); perf_frames.clear(); draws.clear()
		for enemy in room.damage_targets(): enemy_origins[enemy.get_instance_id()]=enemy.position
		watching=true; perf_start=Time.get_ticks_usec(); perf_previous=0
		var cleared: bool=await driver.fight()
		watching=false; driver.release()
		check(cleared,"Actual weapons clear layout "+str(index))
		check(saw_projectile and saw_movement,"Real projectiles and enemy movement observed")
		check(not penetrated,"No moving enemy penetrates actual obstacles")
		check(saw_warning,"Actual environmental WARNING observed")
		record["enemy_avoidance_observed"]=saw_avoidance
		check(room.room_state.status==RoomState.Status.CLEARED and room.doors.values().all(func(d:Door)->bool:return d.is_open),"Actual clear opens connected doors")
		var cache:=room.get_node_or_null("AntiqueCache") as AntiqueCache
		check(cache!=null,"Real clear generates fixture cache through normal Room logic")
		if cache!=null:
			check(room.obstacles().all(func(rect:Rect2)->bool:return not rect.grow(24).has_point(cache.position)),"Actual drop outside obstacles")
			var before:=world.player.antiques.items().size()
			check(await driver.walk(cache.position+Vector2(24,0)),"Actual walk reaches drop")
			key(KEY_E); await frames(3)
			check(world.player.antiques.items().size()==before+1,"Real E pickup adds antique once")
		capture("drop_claimed")
		var old_room: WeakRef=weakref(room)
		var side: int=world.layout.rooms[lab.room_id].neighbors.find_key(world.layout.start_id)
		var door:=room._door_position(side)
		check(await driver.walk(door),"Actual Door traversal walk")
		await frames(5); driver.release()
		check(world.current_id==world.layout.start_id,"Actual Door enters adjacent START")
		capture("door_traversed")
		check(old_room.get_ref()==null,"Old room/physics/danger nodes unloaded")
		check(await driver.visit(lab.room_id),"Actual Door returns to CLEARED lab room")
		check(world.current_room.remaining_count()==0,"Revisit does not spawn enemies")
		check(world.layout.signature()==layout_sig and RoomGeometryPlan.build(session.run_seed,1,world.layout,world.geometry_pool).signature()==formal_sig,"Formal topology and geometry selection remain identical")
		if not perf_frames.is_empty():
			perf_frames.sort(); var sum:=0.0; var draw_sum:=0.0
			for value in perf_frames: sum+=value
			for value in draws: draw_sum+=value
			record["active_combat_fps"]=perf_frames.size()*1000/sum
			record["p95_ms"]=perf_frames[int(perf_frames.size()*.95)]
			record["draw_calls"]=draw_sum/maxi(1,draws.size())
			record["sample_seconds"]=sum/1000
		record["texture_bytes"]=Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
		record["wall_obstacle_collisions"]=world.current_room._wall_rects.size()
		record["door_blockers"]=world.current_room.doors.size()
		record["initial_enemies"]=world.current_room.definition.spawns.size()
		record["benchmarking"]=benchmarking
		records.append(record)
		flow.queue_free(); await frames(4); session=null
	var file:=FileAccess.open("res://docs/screenshots/phase_12a4/"+("active_combat_performance.json" if benchmarking else "layout_validation.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(records,"\t")); file.close()
	check(RoomGeometryPlan.GEOMETRY_VERSION==2 and MuseumProfileStore.VERSION==10,"Production versions unchanged")
	print("[Phase12A4 lab] %d checks, %d failures" % [checks,failures]); quit(0 if failures==0 else 1)
