extends "res://tests/phase12a5_capture.gd"
const DEST="res://docs/screenshots/phase_12a6/"
var visual_checks_done:bool=false
var battle_frame:int=0
var animation_cells:Dictionary={}
var actual_states:Dictionary={}
var battle_metrics:Array=[]
func clip_prefix() -> String:
	return "old" if "--old-enemies" in OS.get_cmdline_user_args() else "new"
func pause_actors(room:Room,value:bool) -> void:
	super.pause_actors(room,value)
	if case_index==1 and "--old-enemies" not in OS.get_cmdline_user_args():
		preload("res://tests/support/phase12a6_binding.gd").install(session.world)
		if value and not visual_checks_done:
			visual_checks_done=true
			check(room.damage_targets().size()==5,"Same real encounter: two dogs, three scarabs")
			for actor in room.damage_targets():
				check(actor.body_radius()==14,"Actual collider radius unchanged")
				var visual=room.get_node("EnemyArt_"+str(actor.get_instance_id()))
				check(visual.frame_cache.size()==64,"Four directions x16 independent poses")
				check(visual.sprite.texture!=null,"Paused initial preview already has a complete native body")
				check(visual.get_children().all(func(n:Node)->bool:return not n is CollisionObject2D),"Enemy art contains no physics")
func capture(label:String) -> void:
	if benchmarking or DisplayServer.get_name()=="headless":return
	RenderingServer.force_draw()
	var prefix:="old" if "--old-enemies" in OS.get_cmdline_user_args() else "new"
	root.get_texture().get_image().save_png(DEST+prefix+"_"+label+".png")
func observe_physics() -> void:
	super.observe_physics()
	if not watching or session==null:return
	var room:=session.world.current_room
	for actor in room.enemy_spawner.get_children():
		if not actor is Enemy:continue
		var visual=room.get_node_or_null("EnemyArt_"+str(actor.get_instance_id()))
		if visual!=null:
			var id:=str(actor.definition.id)
			if not animation_cells.has(id):animation_cells[id]={};actual_states[id]={}
			animation_cells[id][visual.cell]=true
			actual_states[id].merge(visual.seen_states,true)
	if tick_count%6==0 and battle_frame<240 and not benchmarking:
		capture("battle_%03d"%battle_frame)
		var hazard_warnings:int=0
		for entry in room.art_visual.warning_layers.values():
			var hazard=entry[0].get_ref()
			if is_instance_valid(hazard) and hazard is EncounterHazard and hazard.phase==EncounterHazard.Phase.WARN:hazard_warnings+=1
		var enemy_warnings:int=0
		for actor in room.damage_targets():
			if actor is Enemy and actor.telegraphing:enemy_warnings+=1
		battle_metrics.append({"frame":battle_frame,"alive":room.remaining_count(),"projectiles":room.projectiles.get_child_count(),"enemy_warnings":enemy_warnings,"environment_warnings":hazard_warnings})
		if DisplayServer.get_name()!="headless":
			for kind in [&"corpse_dog",&"scarab"]:
				for actor in room.enemy_spawner.get_children():
					if actor is Enemy and actor.definition.id==kind:
						var image:=root.get_texture().get_image()
						var area:=Rect2i(Vector2i(actor.global_position)-Vector2i(48,64),Vector2i(96,96))
						var crop:=image.get_region(area)
						crop.save_png(DEST+clip_prefix()+"_"+str(kind)+"_%03d.png"%battle_frame);break
		battle_frame+=1
func run() -> void:
	await super.run()
	var output:=FileAccess.open(DEST+("old" if "--old-enemies" in OS.get_cmdline_user_args() else "new")+("_benchmark_states.json" if benchmarking else "_runtime_states.json"),FileAccess.WRITE)
	output.store_string(JSON.stringify({"cells":animation_cells,"states":actual_states,"checks":checks,"failures":failures,"frame_metrics":battle_metrics},"\t"));output.close()
