class_name RoomVisual
extends Node2D
## Pure visual room adapter: exact existing geometry, no physics bodies/RNG.
var room: Room
var floor_layer: TileMapLayer
var lamps: Array[PointLight2D] = []
var clock: float = 0.0
func supported() -> bool:
	return ArtAssetCatalog.texture("stone_0") != null and ArtAssetCatalog.texture("wall") != null and ArtAssetCatalog.texture("coffin") != null
func _ready() -> void:
	if not supported(): return
	floor_layer = TileMapLayer.new()
	floor_layer.position = Room.ROOM_RECT.position
	floor_layer.z_index = -100
	floor_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if room.geometry != null:
		# Region palettes are visual-only; keep their existing motifs below.
		if room.geometry.visual_motif == &"HAN_BRICK": floor_layer.modulate = Color(.92,.95,1)
		elif room.geometry.visual_motif == &"TANG_MURAL": floor_layer.modulate = Color(1,.88,.77)
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(32,32)
	for i in range(4):
		var source := TileSetAtlasSource.new()
		source.texture = ArtAssetCatalog.texture("stone_%d" % i)
		if source.texture == null: source.texture = ArtAssetCatalog.texture("stone_0")
		source.texture_region_size = Vector2i(32,32)
		source.create_tile(Vector2i.ZERO)
		tiles.add_source(source,i)
	floor_layer.tile_set = tiles
	var visual_key: int = int(room.definition.room_id.hash()) ^ (int(room.geometry.id.hash()) if room.geometry != null else 0)
	for y in range(14):
		for x in range(36):
			# Local arithmetic hash only; never consumes any gameplay random stream.
			floor_layer.set_cell(Vector2i(x,y),absi((x*73856093) ^ (y*19349663) ^ visual_key)%4,Vector2i.ZERO)
	add_child(floor_layer)
	for rect in room._wall_rects:
		var obstacle := rect in room.obstacles()
		var sprite := Sprite2D.new()
		sprite.texture = ArtAssetCatalog.texture("coffin" if obstacle and room.coffin_style() else "wall")
		if sprite.texture == null: continue
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = rect.get_center()
		sprite.scale = rect.size / Vector2(128,128)
		sprite.z_as_relative = false
		sprite.z_index = int(rect.end.y)
		add_child(sprite)
		var occluder := LightOccluder2D.new()
		var polygon := OccluderPolygon2D.new()
		polygon.polygon = PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
		occluder.occluder = polygon
		add_child(occluder)
	for point in [Vector2(300,160),Vector2(980,160)]:
		var lamp := PointLight2D.new()
		var gradient := Gradient.new()
		gradient.colors = PackedColorArray([Color(1,.72,.32,.75),Color(1,.5,.1,0)])
		var glow := GradientTexture2D.new()
		glow.gradient = gradient; glow.width = 256; glow.height = 256
		glow.fill = GradientTexture2D.FILL_RADIAL
		glow.fill_from = Vector2(.5,.5); glow.fill_to = Vector2(1,.5)
		lamp.texture = glow; lamp.position = point; lamp.energy = .35
		lamp.shadow_enabled = true
		add_child(lamp); lamps.append(lamp)
func _process(delta: float) -> void:
	clock += delta
	visible = ArtRenderSettings.active() and supported()
	for lamp in lamps:
		lamp.enabled = visible and ArtRenderSettings.mode == ArtRenderSettings.Mode.ENHANCED
		lamp.energy = .32 + sin(clock*3+lamp.position.x)*.035
	room.queue_redraw()
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F6:
		ArtRenderSettings.mode = (ArtRenderSettings.mode+1)%3
		get_viewport().set_input_as_handled()
