extends Node2D
## DRAFT Jinbei architecture used by normal rooms. All rectangles are read from the real Room.
## Cached CanvasItem drawing; no physics, random streams, timers or gameplay writes.
var room: Room
var stone: Texture2D
var door_texture: Texture2D
func _ready() -> void:
	z_index=-69
	z_as_relative=false
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	stone=ArtAssetCatalog.texture("a5_masonry")
	door_texture=ArtAssetCatalog.texture("a5_gate")
func tile(r: Rect2, tint: Color) -> void:
	if stone==null: return
	for y in range(int(r.position.y),int(r.end.y),96):
		for x in range(int(r.position.x),int(r.end.x),96):
			var size:=Vector2(minf(96,r.end.x-x),minf(96,r.end.y-y))
			draw_texture_rect_region(stone,Rect2(Vector2(x,y),size),Rect2(Vector2.ZERO,size),tint)
func _draw() -> void:
	var b:=Room.ROOM_RECT
	for r in room._wall_rects:
		if r in room.obstacles(): continue
		var north:=r.end.y<=b.position.y
		var south:=r.position.y>=b.end.y
		var west:=r.end.x<=b.position.x
		var face:=r
		var cap:=r
		if north:
			face=Rect2(r.position-Vector2(0,24),Vector2(r.size.x,40))
			cap=Rect2(r.position-Vector2(0,40),Vector2(r.size.x,16))
		elif south:
			cap=Rect2(r.position,Vector2(r.size.x,12))
			face=Rect2(r.position+Vector2(0,12),Vector2(r.size.x,28))
		else:
			cap=Rect2(r.position-Vector2(24 if west else 0,0),Vector2(40,r.size.y))
		# Facade remains on the original wall side of the playable boundary.
		tile(face,Color(.64,.69,.69)); tile(cap,Color(.94,.95,.86))
		draw_line(cap.position,Vector2(cap.end.x,cap.position.y),Color(.64,.67,.58),2)
		draw_line(Vector2(face.position.x,face.end.y-1),face.end,Color(.08,.12,.13,.8),3)
		# Weathered architectural course (not a new blocking decoration).
		if north:
			for x in range(int(face.position.x)+32,int(face.end.x)-25,112):
				draw_line(Vector2(x,face.position.y+17),Vector2(x+26,face.position.y+17),Color(.09,.14,.15,.65),2)
	for side in room.doors:
		var p: Vector2=room._door_position(side)
		var axis:=Vector2.RIGHT if side in [Door.Direction.NORTH,Door.Direction.SOUTH] else Vector2.DOWN
		var outward:=Vector2.UP.rotated(side*PI*.5)
		# Jambs lie beyond the 112px physical opening, never in its free throat.
		for sign_value in [-1,1]:
			var c: Vector2=p+axis*sign_value*(Door.WIDTH*.5+9)+outward*7
			var size:=Vector2(18,40) if axis==Vector2.RIGHT else Vector2(40,18)
			tile(Rect2(c-size*.5,size),Color(.91,.91,.8))
			draw_line(c-axis*7-outward*16,c-axis*7+outward*16,Color(.14,.18,.17,.75),2)
		# A flush threshold is deliberately a floor treatment, not a raised platform.
		draw_set_transform(p,side*PI*.5)
		draw_rect(Rect2(-56,-12,112,24),Color(.07,.1,.11,.55))
		draw_line(Vector2(-56,9),Vector2(56,9),Color(.62,.58,.44,.5),2)
		draw_set_transform(Vector2.ZERO)
