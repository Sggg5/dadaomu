class_name RoomVisual
extends Node2D
## Pure visual room adapter: exact existing geometry, no physics bodies/RNG.
var room: Room
var floor_layer: TileMapLayer
var lamps: Array[PointLight2D] = []
var clock: float = 0.0
var use_old_space: bool = false # Isolated 12A.1/12A.2 comparison only.
var old_surfaces: Array[Sprite2D] = []
var space_surfaces: Array[Node2D] = []
var warning_layers: Dictionary = {} # Weak references, original visual Z only.
var region_space_enabled: bool = true
var space_floor: TombSpaceFloor
var last_visual_state: Array = []
var warning_visits: int = 0 # Diagnostic: registration work, not a per-frame tree scan.
var quality_visual: Node2D
const QUALITY = preload("res://scripts/art/tomb_quality_visual.gd")
const DETAIL_BODY = preload("res://scripts/art/detailed_enemy_visual.gd")
const FEEDBACK = preload("res://scripts/art/combat_feedback_visual.gd")
func normal_art_enabled() -> bool:
	# Historical comparison labs retain their explicitly installed before/after art.
	return room.geometry == null or not str(room.geometry.id).begins_with("LAB_")
func _install_normal_art() -> void:
	if not is_instance_valid(room) or not normal_art_enabled(): return
	if jinbei_space() and supported() and ["a5_principal", "a5_offering", "a5_gate", "a5_masonry"].all(func(id: String) -> bool: return ArtAssetCatalog.texture(id) != null):
		quality_visual = QUALITY.new()
		quality_visual.room = room
		quality_visual.name = "TombQualityVisual"
		room.add_child(quality_visual)
	if is_instance_valid(room.combat_target):
		var feedback = FEEDBACK.new()
		feedback.room = room
		feedback.name = "CombatFeedbackVisual"
		room.add_child(feedback)
	for actor in room.damage_targets():
		_install_enemy_art(actor)
func _install_enemy_art(node: Node) -> void:
	if not is_instance_valid(node) or not normal_art_enabled() or not node is Enemy or not room.is_ancestor_of(node): return
	if node.definition == null or node.definition.id not in [&"corpse_dog", &"scarab"]: return
	if ArtAssetCatalog.texture("a6_" + str(node.definition.id)) == null: return
	var name := "EnemyArt_" + str(node.get_instance_id())
	if room.has_node(name): return
	var body = DETAIL_BODY.new()
	body.actor = node
	body.name = name
	room.add_child(body)
func jinbei_space() -> bool:
	return region_space_enabled and (room.geometry == null or room.geometry.visual_motif not in [&"HAN_BRICK",&"TANG_MURAL"])
func prop_kind(rect: Rect2, index: int) -> String:
	if rect.size.x < 62 and rect.size.y < 100: return "pillar"
	if rect.size.x > rect.size.y*1.8: return "altar"
	var kinds := ["stone_coffin","wood_coffin","coffin_bed","altar"]
	return kinds[(index+absi(str(room.definition.room_id).hash())%4)%4]
var use_old_floor: bool = false # Isolated before/after comparison, not a save setting.
func supported() -> bool:
	return ArtAssetCatalog.texture("stone_0") != null and ArtAssetCatalog.texture("wall") != null and ArtAssetCatalog.texture("coffin") != null
func _ready() -> void:
	# Arena geometry has no regional motif: read the existing profile, not UI text.
	var host = room.get_parent()
	var controller = host.get_parent() if host != null and host.name == &"RoomHost" else null
	var profile = controller.get("site_loot_profile") if controller != null else null
	region_space_enabled = profile == null or profile.id == &"FORMAL_DEFAULT"
	if controller!=null:
		preload("res://scripts/art/player_hud_boundary.gd").apply.call_deferred(controller)
	if not supported(): return
	floor_layer = TileMapLayer.new()
	floor_layer.position = Room.ROOM_RECT.position
	floor_layer.z_index = -100
	floor_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if room.geometry != null:
		# Region palettes are visual-only; keep their existing motifs below.
		if room.geometry.visual_motif == &"HAN_BRICK": floor_layer.modulate = Color(.92,.95,1)
		elif room.geometry.visual_motif == &"TANG_MURAL": floor_layer.modulate = Color(1,.88,.77)
	_build_floor()
	add_child(floor_layer)
	for rect in room._wall_rects:
		_build_wall(rect)
	if jinbei_space():
		space_floor = TombSpaceFloor.new(); space_floor.room = room; add_child(space_floor)
		space_surfaces.append(space_floor)
	for point in [Vector2(300,160),Vector2(980,160)]:
		_build_lamp(point)
	_prioritize_warnings(room)
	get_tree().node_added.connect(_warning_added)
	_install_normal_art.call_deferred()

func _warning_added(node: Node) -> void:
	if node is Enemy and room.is_ancestor_of(node):
		_install_enemy_art.call_deferred(node)
	if node is BossTelegraph or node is EncounterHazard:
		_register_warning.call_deferred(node)

func _register_warning(node: Node) -> void:
	if not is_instance_valid(node) or not room.is_ancestor_of(node): return
	var id := node.get_instance_id()
	if not warning_layers.has(id): warning_layers[id] = [weakref(node),node.z_index]
	node.z_index = 1100 if visible and jinbei_space() and not use_old_space else warning_layers[id][1]

func _build_floor() -> void:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(32,32)
	var macro := ArtAssetCatalog.texture("stone_macro")
	if not use_old_floor and macro != null:
		var source := TileSetAtlasSource.new()
		source.texture = macro
		source.texture_region_size = Vector2i(32,32)
		for y in range(3):
			for x in range(3): source.create_tile(Vector2i(x,y))
		tiles.add_source(source,0)
		floor_layer.clear()
		floor_layer.tile_set = tiles
		for y in range(14):
			for x in range(36): floor_layer.set_cell(Vector2i(x,y),0,Vector2i(x%3,y%3))
		return
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

func _build_wall(rect: Rect2) -> void:
		var obstacle := rect in room.obstacles()
		var sprite := Sprite2D.new()
		sprite.texture = ArtAssetCatalog.texture("coffin" if obstacle and room.coffin_style() else "wall")
		if sprite.texture == null: return
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = rect.get_center()
		sprite.scale = rect.size / Vector2(128,128)
		sprite.z_as_relative = false
		sprite.z_index = int(rect.end.y)
		add_child(sprite); old_surfaces.append(sprite)
		if jinbei_space():
			var piece := TombSpacePiece.new()
			piece.footprint = rect
			piece.kind = prop_kind(rect,room.obstacles().find(rect)) if obstacle else "wall"
			piece.z_as_relative = false
			piece.z_index = int(rect.end.y) if obstacle else -70
			add_child(piece); space_surfaces.append(piece)
		var occluder := LightOccluder2D.new()
		var polygon := OccluderPolygon2D.new()
		polygon.polygon = PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
		occluder.occluder = polygon
		add_child(occluder)

func _build_lamp(point: Vector2) -> void:
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
func _prioritize_warnings(node: Node) -> void:
	warning_visits += 1
	if node is BossTelegraph or node is EncounterHazard:
		_register_warning(node)
	for child in node.get_children():
		if child != self: _prioritize_warnings(child)
func _process(delta: float) -> void:
	clock += delta
	visible = ArtRenderSettings.active() and supported()
	var state := [visible,ArtRenderSettings.mode,use_old_space,use_old_floor,region_space_enabled]
	var changed := state != last_visual_state
	# Minimal visual-only header packing leaves north masonry below the text.
	var controller = room.get_parent()
	if controller != null and controller.name == &"RoomHost": controller = controller.get_parent()
	if changed and controller != null and controller.get("current_room") == room and is_instance_valid(controller.get("hud")):
		var compact := visible and jinbei_space() and not use_old_space
		var header = controller.get("hud").get_node("Root")
		for path in ["Title","HP","RoomInfo","Enemies","Seed","Progress","EncounterDepth"]:
			var label := header.get_node(path) as Control
			var original: float = 20 if path=="Title" else 64 if path in ["HP","RoomInfo","Enemies"] else 108 if path=="EncounterDepth" else 106
			label.position.y = (6 if path=="Title" else 44 if path in ["HP","RoomInfo","Enemies"] else 72) if compact else original
	for id in warning_layers.keys():
		var warning = warning_layers[id][0].get_ref()
		if warning == null: warning_layers.erase(id)
		elif changed: warning.z_index = 1100 if visible and jinbei_space() and not use_old_space else warning_layers[id][1]
	if changed:
		for surface in old_surfaces: surface.visible = use_old_space or not jinbei_space()
		for surface in space_surfaces: surface.visible = not use_old_space
		room.queue_redraw()
		queue_redraw()
		last_visual_state = state
	for lamp in lamps:
		lamp.enabled = visible and ArtRenderSettings.mode == ArtRenderSettings.Mode.ENHANCED
		lamp.energy = .32 + sin(clock*3+lamp.position.x)*.035

func _draw() -> void:
	if use_old_floor or not visible: return
	# Sparse dust confined to perimeter/obstacle feet; center stays readable.
	for x in range(96,1200,96):
		draw_line(Vector2(x,147),Vector2(x+16,147),Color(.42,.37,.28,.12),3)
		draw_line(Vector2(x,589),Vector2(x+12,589),Color(.42,.37,.28,.12),3)
	for y in range(176,560,96):
		draw_line(Vector2(67,y),Vector2(67,y+12),Color(.42,.37,.28,.12),3)
		draw_line(Vector2(1213,y),Vector2(1213,y+16),Color(.42,.37,.28,.12),3)
	for rect in room._wall_rects:
		var inside := rect.intersection(Room.ROOM_RECT)
		if inside.has_area():
			draw_line(Vector2(inside.position.x,inside.end.y+2),inside.end+Vector2(0,2),Color(.42,.37,.28,.16),5)
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F6:
		ArtRenderSettings.mode = (ArtRenderSettings.mode+1)%3
		get_viewport().set_input_as_handled()
