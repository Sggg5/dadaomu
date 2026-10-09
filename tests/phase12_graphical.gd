extends "res://tests/phase_11i1_smoke.gd"
## Reuses actual clean GameFlow/input-only journey, never gifts funds or HP.
var hooked: bool = false
var visitor_captured: bool = false
func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	if label == "first_tomb" and not hooked:
		hooked = true
		flow.dungeon.world.room_changed.connect(_room_changed)
	if label == "first_display":
		flow.museum.business.visitor_spawned.connect(_visitor_arrived)
	if label == "input_combat" and flow.dungeon != null and flow.dungeon.world.current_room.room_type == RoomDefinition.Type.BOSS:
		label = "boss_battle"
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://docs/screenshots/phase_12/%d_%s.png" % [ArtRenderSettings.mode,label])
func _room_changed(_id: StringName) -> void:
	await frames(2)
	if flow.dungeon == null: return
	match flow.dungeon.world.current_room.room_type:
		RoomDefinition.Type.ANTIQUE: capture("antique_pedestal")
		RoomDefinition.Type.TRAP, RoomDefinition.Type.SECRET: capture("event_room")
		RoomDefinition.Type.BOSS: capture("boss_entrance")
func _visitor_arrived(visitor: MuseumVisitor) -> void:
	for frame in range(900):
		if visitor_captured or not is_instance_valid(visitor): return
		if visitor.activity == MuseumVisitor.Activity.VIEW:
			visitor_captured = true
			capture("museum_real_visitors")
			return
		await frames(1)
