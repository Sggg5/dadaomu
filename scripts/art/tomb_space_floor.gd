class_name TombSpaceFloor
extends Node2D
## Floor overlays below hazards/actors; independent arithmetic visual variation.
var room: Room
func _ready() -> void:
	z_index = -90
func _draw() -> void:
	var b := Room.ROOM_RECT
	# Soft contact bands: no opaque decoration in the central combat area.
	for width in range(12,0,-2):
		var alpha := .014 + (12-width)*.001
		draw_rect(Rect2(b.position,Vector2(b.size.x,width)),Color(.04,.07,.09,alpha))
		draw_rect(Rect2(b.position+Vector2(0,b.size.y-width),Vector2(b.size.x,width)),Color(.04,.07,.09,alpha))
		draw_rect(Rect2(b.position,Vector2(width,b.size.y)),Color(.04,.07,.09,alpha))
		draw_rect(Rect2(b.position+Vector2(b.size.x-width,0),Vector2(width,b.size.y)),Color(.04,.07,.09,alpha))
	# Baked warm pool supplements the two native lights in BASIC as well.
	for lamp in [Vector2(300,156),Vector2(980,156)]:
		for radius in [48,36,24]:
			draw_set_transform(lamp,0,Vector2(1,.52))
			draw_circle(Vector2.ZERO,radius,Color(.63,.43,.21,.025))
		draw_set_transform(Vector2.ZERO)
	var key := absi(str(room.definition.room_id).hash())
	# Perimeter-only wear, cracks and small pottery: no artificial center obstacle.
	for i in range(16):
		var x := 98.0 + float((key+i*197)%1080)
		var y := 166.0 if i%2==0 else 564.0
		var p := Vector2(x,y)
		if room.doors.keys().any(func(side: int) -> bool: return room._door_position(side).distance_to(p)<88): continue
		draw_line(p,p+Vector2(8,3),Color(.5,.48,.39,.13),1)
		draw_line(p+Vector2(8,3),p+Vector2(11,7),Color(.2,.24,.25,.18),1)
		if i%5==0:
			var atlas := ArtAssetCatalog.texture("tomb_props")
			if atlas != null: draw_texture_rect_region(atlas,Rect2(p-Vector2(7,5),Vector2(20,18)),Rect2(256,160,128,160))
			draw_circle(p+Vector2(12,6),4,Color("615848"))
			draw_arc(p+Vector2(12,4),3,0,TAU,10,Color("a58d66"),1)
			draw_line(p+Vector2(16,8),p+Vector2(21,10),Color("726b59"),2)
	for r in room.obstacles():
		for spread in range(10,0,-2):
			draw_rect(Rect2(r.position+Vector2(-spread,0),r.size+Vector2(spread*2,spread)),Color(.02,.04,.05,.025))
		for i in range(4):
			var p := Vector2(r.position.x+7+i*13,r.end.y+5)
			draw_line(p,p+Vector2(5,1),Color(.55,.51,.4,.17),2)
	if room.room_type == RoomDefinition.Type.BOSS:
		# Flush incised dais, never a false raised obstacle or a danger telegraph.
		var c := b.get_center()
		draw_rect(Rect2(c-Vector2(112,64),Vector2(224,128)),Color(.34,.38,.37,.1))
		for inset in [0,8]:
			draw_rect(Rect2(c-Vector2(112-inset,64-inset),Vector2(224-inset*2,128-inset*2)),Color(.49,.52,.47,.15),false,2)
		for x in [-72,-24,24,72]:
			draw_line(c+Vector2(x,-42),c+Vector2(x,42),Color(.18,.22,.24,.13),1)
	# Door contact transition follows actual connections, gaps remain unobstructed.
	for side in room.doors:
		var p: Vector2 = room._door_position(side)
		var horizontal := side==Door.Direction.NORTH or side==Door.Direction.SOUTH
		var extent := Vector2(68,5) if horizontal else Vector2(5,68)
		draw_rect(Rect2(p-extent*.5,extent),Color(.55,.53,.42,.18))
