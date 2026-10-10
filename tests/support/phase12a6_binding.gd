extends RefCounted
const BODY=preload("res://tests/support/phase12a6_enemy_visual.gd")
static func refresh(world:RoomController) -> void:
	var room:=world.current_room
	if room==null or room.geometry==null or room.geometry.id!=&"LAB_V1_PRINCIPAL_BURIAL":return
	if not room.has_node("CombatArtSample"):
		var feedback=preload("res://tests/support/phase12a6_combat_visual.gd").new()
		feedback.room=room;feedback.name="CombatArtSample";room.add_child(feedback)
	for actor in room.damage_targets():
		if not actor is Enemy or actor.definition.id not in [&"scarab",&"corpse_dog"]:continue
		if ArtAssetCatalog.texture("a6_"+str(actor.definition.id))==null:continue
		var name:="EnemyArt_"+str(actor.get_instance_id())
		if room.has_node(name):continue
		var body=BODY.new();body.actor=actor;body.name=name;room.add_child(body)
static func install(world:RoomController) -> void:
	if not world.has_meta("a6_visual_preview"):
		world.set_meta("a6_visual_preview",true)
		world.room_changed.connect(func(_id:StringName)->void:refresh(world))
	refresh(world)
