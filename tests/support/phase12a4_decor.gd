extends Node2D
## DRAFT, attached exclusively by the isolated laboratory. No physics or RNG.
var room: Room
var layout_index: int
func _ready() -> void:
	z_index=-85
	var roles: Array=[]
	match layout_index:
		1: roles=["stone_coffin","wood_coffin","altar","pillar"]
		2: roles=["coffin_bed","coffin_bed","wood_coffin","pillar","altar"]
		3: roles=["altar","coffin_bed","coffin_bed","altar"]
	for piece in room.art_visual.space_surfaces:
		if piece is TombSpacePiece and piece.kind!="wall":
			var index:=room.obstacles().find(piece.footprint)
			if index>=0 and index<roles.size(): piece.kind=roles[index]; piece.queue_redraw()
func _draw() -> void:
	match layout_index:
		1:
			# Flush burial-axis paving, without false raised steps in free space.
			var primary: Rect2=room.obstacles()[0]
			draw_rect(primary.grow(18),Color(.53,.51,.41,.1),false,2)
			for y in range(424,552,32):
				draw_rect(Rect2(588,y,104,26),Color(.39,.42,.39,.09))
				draw_line(Vector2(588,y),Vector2(692,y),Color(.53,.54,.44,.12),1)
		2:
			# Robbers' dragging traces stay sparse and in the side approach.
			for i in range(5):
				var p:=Vector2(288+i*30,344-i*8)
				draw_line(p,p+Vector2(19,-4),Color(.58,.50,.36,.16),2)
			for rect in room.obstacles():
				draw_line(rect.position+Vector2(7,4),rect.position+Vector2(27,7),Color(.17,.20,.2,.3),3)
		3:
			# Low contrast side-service paving identifies a functional chamber.
			for y in range(300,428,32):
				draw_line(Vector2(376,y),Vector2(470,y),Color(.52,.51,.43,.09),1)
