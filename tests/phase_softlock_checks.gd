extends "res://tests/phase_9b3_ai_checks.gd"
func begin(actor:BurrowingCorpse)->void:
	actor.activation_remaining=0
	actor.state=BurrowingCorpse.State.BURIED
	actor.timer=0.01
	actor.submerged_elapsed=0
	actor.get_node("CollisionShape2D").set_deferred("disabled",true)
func recovered(actor:BurrowingCorpse,label:String)->void:
	test.check(actor.state==BurrowingCorpse.State.SURFACE and not actor.get_node("CollisionShape2D").disabled,label+": surface collider restored")
	test.check(Room.ROOM_RECT.has_point(room.to_local(actor.global_position)) and not actor.health.is_dead,label+": living body remains inside room")
func real_room(index:int)->void:
	await fresh()
	var world:=session.world
	var id:StringName
	for key in world.layout.ordered_ids():
		if world.layout.rooms[key].room_type==RoomDefinition.Type.COMBAT:id=key;break
	world.layout.rooms[id].definition=load("res://data/rooms/variety/encounter_%02d.tres"%index)
	world.geometry_plan.assigned[id]=preload("res://data/geometries/central_coffin.tres")
	world._switch_room(id,-1)
	await test.frames(3)
	room=world.current_room
	player=world.player
	player.set_physics_process(false)
	var corpses:Array[BurrowingCorpse]=[]
	for actor in room.enemy_spawner.get_children():
		if actor is BurrowingCorpse:corpses.append(actor)
		elif actor is Enemy:actor.health.take_damage(9999)
	await test.frames(40)
	test.check(room.enemy_spawner.get_remaining()==2 and corpses.size()==2,"variety_%d actual Health deaths leave two corpses"%index)
	var snapshot:=room.enemy_spawner.debug_living_snapshot()
	test.check(snapshot.size()==2 and snapshot.all(func(row:Dictionary)->bool:return row.valid and row.inside_room and row.health>0),"Debug snapshot observes actual living ledger")
	for cycle in range(100):
		player.position=[Vector2(160,208),Vector2(1120,208),Vector2(1120,528),Vector2(160,528)][cycle%4]
		for actor in corpses:begin(actor)
		await test.frames(95)
		for actor in corpses:recovered(actor,"Simultaneous cycle %d"%cycle)
		var points:=corpses.map(func(actor:BurrowingCorpse)->Vector2:return room.to_local(actor.global_position))
		test.check(points[0].distance_to(points[1])>=28,"Simultaneous emergence never deeply overlaps bodies")
	var emitted:=[0]
	room.enemy_spawner.all_defeated.connect(func()->void:emitted[0]+=1)
	corpses[0].take_damage(9999)
	await test.frames(2)
	test.check(room.enemy_spawner.get_remaining()==1,"Actual ledger 2 to 1")
	corpses[1].take_damage(9999)
	await test.frames(2)
	test.check(room.enemy_spawner.get_remaining()==0 and emitted[0]==1,"Actual ledger 1 to 0 emits once")
	test.check(room.room_state.status==RoomState.Status.CLEARED and room.doors.values().all(func(door:Door)->bool:return door.is_open),"Real variety room clears and every real door opens")
	print("[Softlock room] variety_%d: 100 double-burrow cycles, 2->1->0->CLEARED->OPEN"%index)
func anomalies()->void:
	await fresh([Rect2(604,312,72,112)])
	var actor:=spawn("burrowing_corpse",Vector2(400,368)) as BurrowingCorpse
	player.set_physics_process(false)
	for count in [11,12]:
		for child in room.hazards.get_children():child.queue_free()
		await test.frames(2)
		for n in range(count):room.hazards.blast(Vector2(160,208),10,10,0)
		begin(actor)
		await test.frames(100)
		recovered(actor,"Hazard capacity %d"%count)
	room.hazards.stop()
	room.hazards.stopped=false
	await test.frames(2)
	begin(actor)
	await test.frames(2)
	test.check(actor.state==BurrowingCorpse.State.WARNING,"Warning exists before marker-loss probe")
	actor.marker.queue_free()
	await test.frames(2)
	recovered(actor,"Lost marker")
	test.check(actor.recovery_reason==&"MARKER_LOST","Lost marker gets explicit diagnosis")
	begin(actor)
	actor.timer=20
	await test.frames(148)
	recovered(actor,"Hard 2.4 second limit")
	test.check(actor.recovery_reason==&"TIMEOUT","Frozen timer cannot keep enemy underground")
	begin(actor)
	await test.frames(2)
	room.geometry.obstacles.append(Rect2(actor.landing-Vector2(90,90),Vector2(180,180)))
	await test.frames(52)
	recovered(actor,"Landing became illegal")
	begin(actor)
	await test.frames(1)
	room.room_state.status=RoomState.Status.ACTIVE # Synthetic encounter state change, not reopening production START.
	await test.frames(2)
	recovered(actor,"Room state changed")
	begin(actor)
	player.health.take_damage(9999)
	await test.frames(2)
	recovered(actor,"Player death")
	test.check(not actor.ai_enabled and not is_instance_valid(actor.marker),"Death cancels outstanding attack")
	session.queue_free()
	await test.frames(3)
	test.check(not is_instance_valid(actor),"Room unload leaves no underground actor")
	await fresh()
	actor=spawn("burrowing_corpse") as BurrowingCorpse
	player.set_physics_process(false)
	room.geometry.obstacles=[Room.ROOM_RECT] # Impossible dynamic geometry tests finite failure, never a production spawn.
	begin(actor)
	await test.frames(3)
	test.check(actor.state==BurrowingCorpse.State.SURFACE and not actor.get_node("CollisionShape2D").disabled and actor.recovery_failed,"No legal location reports explicit failure and restores hittable surface")
	session.queue_free()
	await test.frames(3)
func run()->void:
	await real_room(17)
	await real_room(29)
	await anomalies()
