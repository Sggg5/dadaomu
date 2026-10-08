extends "res://tests/phase_11b_tombs_smoke.gd"
## Technical gallery: actual production Room/Spawner/hazards, isolated geometry overrides only.
func run()->void:
	for region in ["luoyang","guanzhong"]:
		var tomb:=load("res://data/regional/"+region+"/tomb.tres") as TombDefinition
		for geometry in tomb.floor_at(1).geometry_pool.geometries:
			session=preload("res://scenes/main/dungeon_test.tscn").instantiate()
			session.tomb=tomb
			session.seed_value=33
			root.add_child(session)
			await frames(3)
			var world:=session.world
			var room_id:StringName
			for id in world.layout.ordered_ids():
				if world.layout.rooms[id].room_type==RoomDefinition.Type.COMBAT:room_id=id;break
			world.geometry_plan.assigned[room_id]=geometry
			world._switch_room(room_id,-1)
			await frames(3)
			check(world.current_room.geometry==geometry and world.current_room.enemy_spawner.get_remaining()>0,"Real regional active room/actual enemies")
			capture("geometry_"+str(geometry.id))
			session.queue_free()
			await frames(4)
	print("[11B gallery] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
