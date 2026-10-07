extends RefCounted
var test:SceneTree
func _init(context:SceneTree)->void:test=context
func run()->void:
	for template_index in [18,23,29]:
		var session:=preload("res://scenes/main/dungeon_test.tscn").instantiate() as DungeonSession
		session.seed_value=33
		test.root.add_child(session)
		test.session=session
		test.current_scene=session
		await test.frames(3)
		var world:=session.world
		var combat_id:StringName=&""
		for id in world.layout.ordered_ids():
			if world.layout.rooms[id].room_type==RoomDefinition.Type.COMBAT:combat_id=id;break
		world.layout.rooms[combat_id].definition=load("res://data/rooms/variety/encounter_%02d.tres"%template_index)
		world.layout.rooms[combat_id].distance_from_start=5
		var plan:=RelicRewardPlan.build(template_index,5,RelicRewardService.PRODUCTION_POOL)
		# Constructing a high Build is a unit fixture only. Complete-flow suite earns every relic with E.
		var index:=0
		for source in plan.assigned:
			if index<12:world.player.relics.inventory.add(plan.assigned[source])
			index+=1
		world._switch_room(combat_id,-1)
		await test.frames(2)
		test.check(world.current_room.difficulty.tier==3 and world.current_room.enemy_spawner.get_remaining()>0,"High combination uses real Tier3 spawner")
		test.capture("combo_%d"%template_index)
		var driver=preload("res://tests/threat_fight_driver.gd").new(test)
		driver.picked.assign(world.player.relics.inventory.ids())
		await driver.fight()
		test.check(world.current_room.enemy_spawner.get_remaining()==0 and world.current_room.room_state.status==RoomState.Status.CLEARED,"High-pressure live combination clears including spawned children")
		var old_room:=world.current_room
		world._switch_room(world.layout.start_id,-1)
		await test.frames(3)
		test.check(not is_instance_valid(old_room) and world.current_room.projectiles.get_child_count()==0,"Combo hazards and projectiles unload on transition")
		session.queue_free()
		await test.frames(3)
