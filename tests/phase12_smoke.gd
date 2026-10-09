extends "res://tests/phase_5b_smoke.gd"
func collider_signature(node: Node) -> Array:
	var output: Array = []
	for child in node.get_children():
		if child is CollisionShape2D:
			output.append([str(child.shape),child.position,child.disabled])
		output.append_array(collider_signature(child))
	return output
func run() -> void:
	ArtRenderSettings.initialize()
	var expected: String = ""
	for mode in range(3):
		ArtRenderSettings.mode = mode
		session = SESSION.instantiate()
		root.add_child(session); await frames(4)
		var world := session.world
		if expected.is_empty(): expected = world.layout.signature()
		check(world.layout.signature() == expected,"Visual mode preserves topology/templates")
		check(world.player.stats.max_hp == 80,"HP remains80")
		check(world.player.antiques.capacity == 8,"Bag remains8")
		var before := collider_signature(world)
		var ray := PhysicsRayQueryParameters2D.create(Vector2(640,160),Vector2(0,160),1)
		var hit_before := world.get_world_2d().direct_space_state.intersect_ray(ray)
		ArtRenderSettings.mode = (mode+1)%3; await frames(3)
		check(collider_signature(world) == before,"Mode switch leaves all actual collision shapes untouched")
		var hit_after := world.get_world_2d().direct_space_state.intersect_ray(ray)
		check(not hit_before.is_empty() and hit_before.position == hit_after.position,"Light occluders do not alter actual layer1 raycast")
		check((world.player.get_node("CollisionShape2D").shape as CircleShape2D).radius == 16,"Player collision radius stays16")
		var previous_mode := ArtRenderSettings.mode
		var event := InputEventKey.new(); event.keycode = KEY_F6; event.physical_keycode = KEY_F6; event.pressed = true
		root.push_input(event); await frames(2)
		check(ArtRenderSettings.mode == (previous_mode+1)%3,"Actual F6 changes exactly one visual mode")
		check(world.player.art_visual.get_child_count() == 1,"Visual has one sprite, no collider/weapon")
		check(world.current_room.art_visual.lamps.size() == 2,"Two bounded native lights per Room")
		check(not ArtAssetCatalog.texture("missing_asset_fixture"),"Missing asset is safe null")
		var texture := ArtAssetCatalog.texture("actors")
		ArtAssetCatalog._textures["actors"] = null; await frames(2)
		check(not world.player.art_visual.visible,"Missing atlas enables legacy actor body")
		ArtAssetCatalog._textures["actors"] = texture
		var image := texture.get_image()
		check(image.get_size() == Vector2i(288,384),"36 frames48x64")
		check(world.player.aim_direction.length() > .99,"Sprite facing never changes360aim")
		session.queue_free(); await frames(4)
	for id in AntiqueVisual.ORIGINAL_IDS:
		ArtRenderSettings.mode = 1
		check(AntiqueVisual.icon(id) != null,"Original unique icon "+str(id))
	check(AntiqueVisual.icon(&"gz_sancai_horse") == null,"Regional ID cannot reuse original horse image")
	check(MuseumProfileStore.VERSION == 10,"Profile remains10")
	seed(12033); var expected_random := randi(); seed(12033)
	ArtAssetCatalog.texture("stone_0"); ArtAssetCatalog.frame("actors",2,3); AntiqueVisual.icon(&"han_jade_disc")
	check(randi() == expected_random,"Visual asset queries do not consume global random stream")
	print("[Phase12 visual] %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
