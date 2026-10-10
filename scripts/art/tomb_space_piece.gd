class_name TombSpacePiece
extends Node2D
## DRAFT original architectural illustration. Coordinates are read-only Room local.
## Base footprints follow existing collision rectangles; elevated caps are visual only.
var footprint: Rect2
var kind: String = "wall"
var variant: int = 0
var bounds := Room.ROOM_RECT
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
func box(r: Rect2, fill: Color, edge: Color = Color.TRANSPARENT) -> void:
	draw_rect(r,fill)
	if edge.a > 0: draw_rect(r,edge,false,1)
func masonry(r: Rect2, fill: Color, step: Vector2 = Vector2(64,16)) -> void:
	box(r,fill)
	var texture := ArtAssetCatalog.texture("wall")
	if texture != null:
		# Original masonry texture adds grain; structural seams are drawn above.
		var py := r.position.y
		while py < r.end.y:
			var px := r.position.x
			while px < r.end.x:
				var size := Vector2(minf(64,r.end.x-px),minf(64,r.end.y-py))
				draw_texture_rect_region(texture,Rect2(Vector2(px,py),size),Rect2(Vector2(24,32),size),Color(1,1,1,.38))
				px += 64
			py += 64
	var row := 0
	var y := r.position.y
	while y < r.end.y:
		draw_line(Vector2(r.position.x,y),Vector2(r.end.x,y),fill.darkened(.27),1)
		var x: float = r.position.x + (step.x*.5 if row%2 else 0)
		while x < r.end.x:
			draw_line(Vector2(x,y),Vector2(x,minf(y+step.y,r.end.y)),fill.darkened(.23),1)
			x += step.x
		y += step.y; row += 1
func _draw() -> void:
	if kind == "wall": wall(); return
	var atlas := ArtAssetCatalog.texture("tomb_props")
	if atlas != null:
		var index: int = {"stone_coffin":0,"wood_coffin":1,"coffin_bed":2,"pillar":3,"altar":4}.get(kind,2)
		# Flush base follows actual footprint; the raised illustration projects north.
		masonry(footprint,Color("343a38"),Vector2(48,16))
		var elevated := Rect2(footprint.position-Vector2(0,18),footprint.size+Vector2(0,18))
		draw_texture_rect_region(atlas,elevated,Rect2((index%3)*128,floori(index/3.0)*160,128,160))
	else: prop()
func wall() -> void:
	var r := footprint
	var north := r.end.y <= bounds.position.y
	var south := r.position.y >= bounds.end.y
	var west := r.end.x <= bounds.position.x
	var face := r
	var cap := r
	if north:
		face = Rect2(r.position-Vector2(0,20),Vector2(r.size.x,36))
		cap = Rect2(r.position-Vector2(0,34),Vector2(r.size.x,14))
	elif south:
		cap = Rect2(r.position,Vector2(r.size.x,14))
		face = Rect2(r.position+Vector2(0,14),Vector2(r.size.x,28))
	else:
		face = r
		cap = Rect2(r.position-Vector2(28 if west else 0,0),Vector2(44,r.size.y))
	masonry(face,Color("494c4b"),Vector2(72,14))
	masonry(cap,Color("5d645d"),Vector2(80,16))
	draw_line(cap.position,Vector2(cap.end.x,cap.position.y),Color("969d87"),2)
	if north:
		draw_line(Vector2(r.position.x,bounds.position.y),Vector2(r.end.x,bounds.position.y),Color("262d30"),3)
		# Recessed niches stay outside the playable floor.
		if r.size.x > 180:
			var center := Vector2(r.get_center().x,face.position.y+8)
			box(Rect2(center-Vector2(14,0),Vector2(28,25)),Color("292e30"),Color("777a6d"))
			box(Rect2(center+Vector2(-9,18),Vector2(18,5)),Color("5c6358"))
	# Mortar chips are deterministic and confined to the architectural surface.
	for i in range(3):
		var p := face.position+Vector2(minf(face.size.x-3,12+i*93),minf(face.size.y-3,5+i*3))
		draw_line(p,p+Vector2(5,2),Color("898c79"),1)
func prop() -> void:
	var r := footprint
	# Exact footprint is always solid/readable; lid projects toward screen north.
	var rise := 14.0 if kind != "pillar" else 27.0
	var top := Rect2(r.position-Vector2(0,rise),r.size)
	var stone := Color("6f7773")
	var face := Color("40494c")
	if kind == "wood_coffin": stone = Color("786049"); face = Color("44372d")
	box(r,face,Color("232b2f"))
	box(Rect2(r.position+Vector2(3,r.size.y-10),Vector2(maxf(1,r.size.x-6),8)),face.lightened(.12))
	box(top,stone,Color("929987") if kind != "wood_coffin" else Color("ac8b60"))
	draw_line(top.position+Vector2(2,2),Vector2(top.end.x-2,top.position.y+2),stone.lightened(.3),2)
	var inner := top.grow(-6)
	if kind == "stone_coffin" or kind == "wood_coffin":
		# Tapered lid and raised inner seal distinguish a coffin from a crate.
		var pts := PackedVector2Array([inner.position+Vector2(5,0),Vector2(inner.end.x-5,inner.position.y),inner.end,Vector2(inner.position.x,inner.end.y)])
		draw_colored_polygon(pts,stone.darkened(.13))
		draw_polyline(PackedVector2Array([pts[0],pts[1],pts[2],pts[3],pts[0]]),stone.lightened(.2),2)
		if kind == "wood_coffin":
			for offset in [0.27,0.73]:
				var y: float = top.position.y+top.size.y*offset
				draw_line(Vector2(top.position.x+2,y),Vector2(top.end.x-2,y),Color("a69a79"),3)
		else:
			var c := inner.get_center()
			draw_circle(c,5,Color("455650")); draw_arc(c,8,0,TAU,12,Color("9caa90"),1)
	elif kind == "pillar":
		masonry(inner,stone.darkened(.08),Vector2(32,18))
		box(Rect2(top.position-Vector2(3,4),Vector2(top.size.x+6,9)),Color("929886"),Color("b1b7a0"))
		box(Rect2(r.position+Vector2(-2,r.size.y-5),Vector2(r.size.x+4,5)),Color("69716a"))
	elif kind == "altar":
		box(inner,stone.darkened(.17),stone.lightened(.12))
		var c := inner.get_center()
		draw_circle(c,5,Color("343c3c")); draw_line(c-Vector2(11,0),c+Vector2(11,0),Color("bdab78"),2)
		# A chipped corner and offering groove, never an added collision.
		draw_colored_polygon(PackedVector2Array([top.position,top.position+Vector2(9,0),top.position+Vector2(0,8)]),Color("40494c"))
	else: # coffin bed / broken stone platform
		masonry(inner,stone.darkened(.09),Vector2(48,22))
		box(Rect2(inner.position+Vector2(3,3),inner.size-Vector2(6,6)),Color("58645d"),Color("8c9885"))

