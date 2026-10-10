extends RefCounted
## Experiment-only lifetime binding to the existing room_changed signal.
const SAMPLE=preload("res://tests/support/phase12a5_visual.gd")
static func refresh(world: RoomController) -> Node2D:
	var room:=world.current_room
	if room==null or room.geometry==null or room.geometry.id!=&"LAB_V1_PRINCIPAL_BURIAL": return null
	var current:=room.get_node_or_null("PrincipalArtSample") as Node2D
	if current!=null: return current
	var visual=SAMPLE.new(); visual.name="PrincipalArtSample"; visual.room=room
	room.add_child(visual)
	return visual
static func install(world: RoomController) -> Node2D:
	if not world.has_meta("a5_visual_preview"):
		world.set_meta("a5_visual_preview",true)
		world.room_changed.connect(func(_id:StringName)->void:refresh(world))
	return refresh(world)
