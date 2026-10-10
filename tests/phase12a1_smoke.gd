extends "res://tests/phase_5b_smoke.gd"
## Isolated visual state tests. Gameplay invariants retained by Phase12 + freeze tests.
func run() -> void:
	ArtRenderSettings.mode = ArtRenderSettings.Mode.BASIC
	session = SESSION.instantiate(); root.add_child(session); await frames(4)
	var p := session.world.player
	p.set_physics_process(false)
	var visual := p.art_visual
	visual.set_process(false)
	var directions := [Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT,Vector2.UP]
	for row in range(4):
		p.velocity = directions[row]*100
		visual._process(.02)
		check(visual.body_row == row,"Four locomotion views " + str(row))
		for aim in [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]:
			p.aim_direction = aim
			visual.attack_remaining = .12
			visual._process(.02)
			check(visual.body_row == row,"Mouse/shooting cannot override stride " + str(row))
			check(visual.last_cell.x in [1,2],"Attack does not replace walk with wholebody action")
			check(visual.sprite.position == Vector2(0,-24),"Fixed feet anchor for move/aim")
	p.velocity = Vector2.ZERO; visual._process(.02)
	check(visual.last_cell.x == 0 and visual.body_row == 3,"Idle retains last locomotion facing")
	p.invulnerability_remaining = .2; visual._process(.02)
	check(visual.sprite.modulate != Color.WHITE and visual.last_cell.x == 0,"Hurt tint preserves idle pose")
	for size in [15,20,25]:
		visual.size_variant = size; visual._process(.02)
		check(visual.sprite.texture.get_size() == Vector2(64,80),"Native size variant " + str(size))
		check(visual.sprite.scale == Vector2.ONE,"No fractional sprite scaling")
	var saved_body := ArtAssetCatalog.texture("player_body_25")
	ArtAssetCatalog._textures["player_body_25"] = null; visual._process(.02)
	check(visual.sprite.texture.get_size() == Vector2(48,64),"Missing new body falls back to original atlas")
	ArtAssetCatalog._textures["player_body_25"] = saved_body
	p.health.take_damage(p.health.current_hp); visual._process(.02)
	check(visual.last_cell.x == 3,"Explicit death frame")
	check(p.stats.max_hp == 80 and p.antiques.capacity == 8,"Gameplay baseline unchanged")
	var layer := session.world.current_room.art_visual.floor_layer
	check(layer.tile_set.get_source_count() == 1,"Contiguous macro atlas replaces random tile tones")
	check(layer.get_cell_atlas_coords(Vector2i(2,2)) == Vector2i(2,2),"3x3 macro atlas coordinate")
	check(layer.get_cell_atlas_coords(Vector2i(3,3)) == Vector2i.ZERO,"Repeat wraps at96 pixels")
	var saved_floor := ArtAssetCatalog.texture("stone_macro")
	ArtAssetCatalog._textures["stone_macro"] = null
	session.world.current_room.art_visual._build_floor()
	check(layer.tile_set.get_source_count() == 4,"Missing macro floor retains original4tile fallback")
	ArtAssetCatalog._textures["stone_macro"] = saved_floor
	session.queue_free(); await frames(4)
	print("[Phase12A1 visual] %d checks, %d failures" % [checks,failures]); quit(0 if failures==0 else 1)
