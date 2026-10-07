extends "res://tests/phase_9b3_ai_checks.gd"
func run()->void:
	await fresh()
	player.position=Vector2(800,320)
	player.set_physics_process(false)
	var wave:=RoomDefinition.new()
	for point in [Vector2(400,320),Vector2(460,320)]:
		var entry:=EnemySpawnDefinition.new()
		entry.enemy_scene=preload("res://scenes/enemies/burrowing_corpse.tscn")
		entry.enemy_definition=preload("res://data/enemies/burrowing_corpse.tres")
		entry.position=point
		wave.spawns.append(entry)
	room.room_type=RoomDefinition.Type.COMBAT
	room.room_state.status=RoomState.Status.ACTIVE # Unit fixture only, real run covered separately.
	room.enemy_spawner.spawn(wave)
	var first:=room.enemy_spawner.get_child(0) as BurrowingCorpse
	var second:=room.enemy_spawner.get_child(1) as BurrowingCorpse
	test.check(first!=second and room.enemy_spawner.get_remaining()==2,"Fixture owns two distinct registered burrow enemies")
	for actor in [first,second]:
		actor.activation_remaining=0
		actor.state=BurrowingCorpse.State.BURIED
		actor.timer=0.01
		actor.get_node("CollisionShape2D").set_deferred("disabled",true)
	await test.frames(2)
	test.check(first.state==BurrowingCorpse.State.WARNING and second.state==BurrowingCorpse.State.WARNING,"Both corpses still enter predicted burrow warning")
	test.check(first.landing.distance_to(second.landing)>=48,"Concurrent landings reserve separate padded bodies")
	for actor in [first,second]:test.check(actor.landing.distance_to(player.position)>=40,"Landing cannot overlap Player body")
	for interval in range(20):
		await test.frames(30)
		for actor in [first,second]:test.check(Room.ROOM_RECT.grow(-14).has_point(room.to_local(actor.global_position)),"Repeated simultaneous emergence cannot eject corpses outside room")
	player.set_physics_process(true)
	var driver=preload("res://tests/threat_fight_driver.gd").new(test)
	await driver.fight()
	test.check(room.enemy_spawner.get_remaining()==0,"Separated real burrow actors remain hittable and clear")
	session.queue_free()
	await test.frames(3)
