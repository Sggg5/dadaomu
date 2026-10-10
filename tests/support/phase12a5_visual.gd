extends Node2D
## Explicit A-only visual attachment. Not referenced by production Room/GeometryPlan.
const ARCH=preload("res://tests/support/phase12a5_architecture.gd")
const PROP=preload("res://tests/support/phase12a5_prop.gd")
var room: Room
var original_tints: Dictionary={}
var changed_state: int=-1
func _ready() -> void:
	assert(room.geometry.id==&"LAB_V1_PRINCIPAL_BURIAL")
	if room.art_visual==null or not room.art_visual.supported() or room.art_visual.lamps.size()!=2:
		visible=false; set_process(false); return
	# Missing DRAFT resources leave the existing architecture completely intact.
	for id in ["a5_principal","a5_offering","a5_gate","a5_masonry"]:
		if ArtAssetCatalog.texture(id)==null:
			visible=false; set_process(false); return
	z_index=-86; texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var architecture=ARCH.new(); architecture.room=room; add_child(architecture)
	# Reposition the existing two visual-only lamps; do not add real-time lights.
	room.art_visual.lamps[0].position=Vector2(480,238)
	room.art_visual.lamps[1].position=Vector2(800,238)
	for child in room.get_children():
		if child.get_script()!=null and child.get_script().resource_path=="res://tests/support/phase12a4_decor.gd":
			original_tints[child]=child.modulate; child.modulate=Color.TRANSPARENT
	for surface in room.art_visual.space_surfaces:
		if surface is TombSpacePiece and surface.footprint in room.obstacles():
			var index:=room.obstacles().find(surface.footprint)
			if index==1:surface.kind="wood_coffin";surface.queue_redraw()
			elif index==3:surface.kind="pillar";surface.queue_redraw()
		if surface is TombSpacePiece and surface.kind=="wall":
			original_tints[surface]=surface.modulate; surface.modulate=Color.TRANSPARENT
	for index in [0,2]:
		var rect: Rect2=room.obstacles()[index]
		for surface in room.art_visual.space_surfaces:
			if surface is TombSpacePiece and surface.footprint==rect:
				original_tints[surface]=surface.modulate; surface.modulate=Color.TRANSPARENT
		var prop=PROP.new(); prop.footprint=rect
		prop.asset_id="a5_principal" if index==0 else "a5_offering"
		add_child(prop)
	for side in room.doors:
		var door: Door=room.doors[side]
		original_tints[door]=door.modulate; door.modulate=Color.TRANSPARENT
		var seal=PROP.new(); seal.door=door; seal.asset_id="a5_gate"; add_child(seal)
func _process(_delta: float) -> void:
	visible=ArtRenderSettings.active()
	if changed_state!=ArtRenderSettings.mode:
		changed_state=ArtRenderSettings.mode
		# Door original fallback is fully preserved for LEGACY.
		for surface in original_tints:
			if is_instance_valid(surface): surface.modulate=Color.TRANSPARENT if visible else original_tints[surface]
		queue_redraw()
func _draw() -> void:
	# Static, low-opacity lighting in BOTH textured modes. No full-room concept image.
	var b:=Room.ROOM_RECT
	for band in range(8):
		var width: float=(8-band)*4
		var shade:=Color(.035,.052,.06,.017)
		draw_rect(Rect2(b.position,Vector2(b.size.x,width)),shade)
		draw_rect(Rect2(Vector2(b.position.x,b.end.y-width),Vector2(b.size.x,width)),shade)
		draw_rect(Rect2(b.position,Vector2(width,b.size.y)),shade)
		draw_rect(Rect2(Vector2(b.end.x-width,b.position.y),Vector2(width,b.size.y)),shade)
	# Processional paving is flush and quiet; visual axis never becomes a fake obstacle.
	for y in range(424,552,32):
		draw_rect(Rect2(590,y,100,28),Color(.43,.46,.42,.11))
		draw_line(Vector2(590,y),Vector2(690,y),Color(.63,.61,.49,.18),1)
	for rect in room.obstacles():
		for spread in range(12,0,-2):
			draw_rect(Rect2(rect.position+Vector2(-spread,0),rect.size+Vector2(spread*2,spread)),Color(.015,.024,.028,.035))
	for point in [Vector2(480,238),Vector2(800,238)]:
		for radius in [88,64,40]:
			draw_set_transform(point,0,Vector2(1,.55))
			draw_circle(Vector2.ZERO,radius,Color(.69,.46,.21,.023))
		draw_set_transform(Vector2.ZERO)
