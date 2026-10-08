class_name RegionalRoomDecor
extends RefCounted
## Original schematic masonry/mural motifs, no photographic archaeological attribution.
static func draw(canvas:Room,geometry:RoomGeometryDefinition)->void:
	if geometry.visual_motif==&"HAN_BRICK":
		for y in range(144,593,28):
			canvas.draw_line(Vector2(64,y),Vector2(1216,y),Color("657177"),1)
			for x in range(64+(28 if int(y/28)%2 else 0),1216,56):canvas.draw_line(Vector2(x,y),Vector2(x,minf(y+28,Room.ROOM_RECT.end.y)),Color("4c585f"),1)
		for x in [100,1080]:
			canvas.draw_rect(Rect2(x,208,96,40),Color("88988e"),false,2)
			canvas.draw_line(Vector2(x+8,238),Vector2(x+45,216),Color("9caa9a"),2)
	elif geometry.visual_motif==&"TANG_MURAL":
		for x in [124,1000]:
			canvas.draw_rect(Rect2(x,188,156,62),Color("68433b"))
			canvas.draw_rect(Rect2(x,188,156,62),Color("c39463"),false,2)
			for offset in [32,78,124]:
				canvas.draw_circle(Vector2(x+offset,203),5,Color("c6a579"))
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(x+offset,210),Vector2(x+offset-11,237),Vector2(x+offset+11,237)]),Color("a97354"))
