extends "res://tests/phase12a4_smoke.gd"
## Reuses EVERY A4 geometry/real-weapon/door/drop assertion. A-only visual injection.
const SAMPLE=preload("res://tests/support/phase12a5_visual.gd")
const OUTPUT="res://docs/screenshots/phase_12a5/"
var attached: Dictionary={}
func pause_actors(room: Room, value: bool) -> void:
	super.pause_actors(room,value)
	# Identical test header in old/new captures, avoiding the new north cap behind text.
	for path in ["Root/Title","Root/Seed","Root/Progress","Root/EncounterDepth","Root/Minimap"]:
		session.world.hud.get_node(path).hide()
	if value and case_index==1 and "--old-a" not in OS.get_cmdline_user_args():
		var physical_before:=room._wall_rects.duplicate()
		var stats_before:=session.world.player.stats.duplicate()
		var cached:=ArtAssetCatalog.texture("a5_principal")
		ArtAssetCatalog._textures["a5_principal"]=null
		var fallback=SAMPLE.new(); fallback.room=room; room.add_child(fallback)
		check(not fallback.visible and fallback.original_tints.is_empty(),"Missing draft asset preserves original visual fallback")
		check(fallback.get_child_count()==0,"Missing draft asset creates no empty replacement architecture")
		fallback.queue_free(); ArtAssetCatalog._textures["a5_principal"]=cached
		var old_tile:=ArtAssetCatalog.texture("stone_0")
		ArtAssetCatalog._textures["stone_0"]=null
		var old_fallback=SAMPLE.new(); old_fallback.room=room; room.add_child(old_fallback)
		check(not old_fallback.visible and old_fallback.get_child_count()==0,"Missing base art safely retains original geometry drawing")
		old_fallback.queue_free();ArtAssetCatalog._textures["stone_0"]=old_tile
		var visual=preload("res://tests/support/phase12a5_binding.gd").install(session.world)
		attached[room.get_instance_id()]=weakref(visual)
		check(room._wall_rects==physical_before,"A5 attachment keeps every real collision rectangle")
		check(session.world.player.stats.max_hp==stats_before.max_hp and session.world.player.stats.move_speed==stats_before.move_speed,"A5 does not change HP/speed")
		check(room.art_visual.lamps.size()==2,"A5 retains only existing two real lights")
		check(visual.get_children().all(func(child:Node)->bool:return not child is CollisionObject2D),"A5 has no physics children")
		for id in ["a5_principal","a5_offering","a5_gate","a5_masonry"]:
			check(ArtAssetCatalog.texture(id)!=null,"DRAFT native asset exists "+id)
		check(ArtAssetCatalog.texture("a5_principal").get_size()==Vector2(160,148),"Dedicated main coffin native160x148, never small-prop stretch")
		check(ArtAssetCatalog.texture("a5_offering").get_size()==Vector2(144,60),"Offering native144x60 follows144x48 collider")
func capture(label: String) -> void:
	if benchmarking or DisplayServer.get_name()=="headless": return
	RenderingServer.force_draw()
	var prefix: String="before" if "--old-a" in OS.get_cmdline_user_args() else "after"
	root.get_texture().get_image().save_png(OUTPUT+"%s_%d_%s.png"%[prefix,case_index,label])
func run() -> void:
	# Canvas-items stretch otherwise renders at a DPI-dependent desktop resolution.
	# Evidence is native Godot viewport pixels, never a post-capture resize.
	root.mode=Window.MODE_WINDOWED
	root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i(1280,720)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_factor=1.0
	await super.run()
	var prefix: String="before" if "--old-a" in OS.get_cmdline_user_args() else "after"
	var file:=FileAccess.open(OUTPUT+prefix+("_performance.json" if benchmarking else "_validation.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(records,"\t")); file.close()
