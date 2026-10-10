extends Node2D
## Native debug evidence only: read actual Walls/CollisionShape2D, never resources.
var room: Room
func _ready() -> void: z_index=1500
func _draw() -> void:
	for shape in room.get_node("Walls").get_children():
		if shape is CollisionShape2D and shape.shape is RectangleShape2D:
			var center:=room.to_local(shape.global_position)
			var bounds:=Rect2(center-shape.shape.size*.5,shape.shape.size)
			draw_rect(bounds,Color(.25,.8,1,.7),false,2)
