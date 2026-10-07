extends "res://tests/phase_9b3_ai_checks.gd"
## 真正Room实体碰撞、活跃潜地状态机；不是仅检查obstacle数组。
func unobstructed(origin:Vector2,point:Vector2,actor:Enemy)->bool:
	var query:=PhysicsRayQueryParameters2D.create(room.to_global(origin),room.to_global(point),1,[actor.get_rid()])
	return room.get_world_2d().direct_space_state.intersect_ray(query).is_empty()
func bury(actor:BurrowingCorpse)->void:
	room.queue_redraw()
	actor.activation_remaining=0
	actor.state=BurrowingCorpse.State.BURIED
	actor.timer=0.01
	actor.velocity=Vector2.ZERO
	actor.get_node("CollisionShape2D").set_deferred("disabled",true)
	await test.frames(2)
func run()->void:
	for translated in [false,true]:
		await fresh([Rect2(604,312,72,112)])
		var actor:=spawn("burrowing_corpse",Vector2(400,368)) as BurrowingCorpse
		if translated:
			room.position=Vector2(310,-180)
			room.enemy_spawner.position=Vector2(17,11)
			actor.global_position=room.to_global(Vector2(400,368))
		player.global_position=room.to_global(Vector2(880,368))
		player.set_physics_process(false)
		player.velocity=Vector2.ZERO
		await test.frames(2)
		var origin:=room.to_local(actor.global_position)
		var preferred:=room.to_local(player.global_position)
		test.check(not unobstructed(origin,preferred,actor),"Real central coffin blocks direct predicted landing")
		await bury(actor)
		test.check(actor.state==BurrowingCorpse.State.WARNING and actor.landing.is_finite() and actor.landing!=preferred,"Blocked preferred point searches a legal alternate, not cancellation")
		test.check(unobstructed(origin,actor.landing,actor),"Accepted central-obstacle landing has clear layer1 ray in world space")
		test.check(not room.definition.obstacles[0].grow(72).has_point(actor.landing),"Alternate landing retains original clearance")
		var landing:=actor.landing
		var hp:=player.health.current_hp
		test.capture("burrow_central_transformed" if translated else "burrow_central_obstacle")
		await test.frames(44)
		test.check(actor.state==BurrowingCorpse.State.WARNING and player.health.current_hp==hp,"Original 0.8s telegraph stays harmless until emergence")
		await test.frames(6)
		test.check(actor.state==BurrowingCorpse.State.SURFACE and actor.eruptions==1 and actor.global_position.distance_to(room.to_global(landing))<8,"Actual emergence uses Room-to-world landing, including transformed parents")
	await fresh([Rect2(604,144,72,448)])
	var actor:=spawn("burrowing_corpse",Vector2(400,368)) as BurrowingCorpse
	player.position=Vector2(880,368)
	player.set_physics_process(false)
	await test.frames(2)
	var origin:=room.to_local(actor.global_position)
	await bury(actor)
	test.check(actor.state==BurrowingCorpse.State.WARNING and actor.landing.x<604,"Full separating wall selects nearest same-side point")
	test.check(unobstructed(origin,actor.landing,actor),"Full-wall accepted landing is physically reachable")
	test.capture("burrow_full_wall")
	await fresh()
	actor=spawn("burrowing_corpse",Vector2(400,320)) as BurrowingCorpse
	player.position=Vector2(800,320)
	player.set_physics_process(false)
	player.velocity=Vector2(100,0)
	await test.frames(2)
	origin=room.to_local(actor.global_position)
	var predicted:=room.to_local(player.global_position+player.velocity*0.45)
	await bury(actor)
	test.check(actor.state==BurrowingCorpse.State.WARNING and actor.landing.distance_to(predicted)<0.01,"Open-space landing preserves movement prediction exactly")
	test.check(actor.landing.distance_to(origin)>300 and unobstructed(origin,actor.landing,actor),"Open-space burrow still advances rather than drilling in place")
	var marker:=actor.marker
	test.capture("burrow_open_prediction")
	player.position=Vector2(1000,496)
	await test.frames(51)
	test.check(actor.state==BurrowingCorpse.State.SURFACE and actor.eruptions==1 and not actor.get_node("CollisionShape2D").disabled,"Open-space emergence restores surface collision")
	await fresh([Room.ROOM_RECT])
	actor=spawn("burrowing_corpse") as BurrowingCorpse
	player.set_physics_process(false)
	await test.frames(2)
	await bury(actor)
	test.check(actor.state==BurrowingCorpse.State.SURFACE and actor.timer>1.9 and actor.marker==null,"No legal candidate resets surface and timer instead of permanent burial")
	await test.frames(2)
	test.check(not actor.get_node("CollisionShape2D").disabled and actor.take_damage(1),"Fallback restores collision and vulnerability")
	await fresh()
	actor=spawn("burrowing_corpse") as BurrowingCorpse
	player.set_physics_process(false)
	await bury(actor)
	marker=actor.marker
	actor.health.take_damage(9999)
	var hp:=player.health.current_hp
	await test.frames(60)
	test.check(not is_instance_valid(marker) and not is_instance_valid(actor) and player.health.current_hp==hp,"Buried death cancels marker, emergence and delayed damage")
	await fresh()
	actor=spawn("burrowing_corpse") as BurrowingCorpse
	actor.state=BurrowingCorpse.State.BURIED
	actor.timer=0.6
	actor.health.take_damage(9999)
	await test.frames(60)
	test.check(not is_instance_valid(actor) and room.hazards.get_child_count()==0,"Death before warning cannot create later marker")
	await fresh()
	actor=spawn("burrowing_corpse") as BurrowingCorpse
	player.set_physics_process(false)
	await bury(actor)
	marker=actor.marker
	var old_room:=room
	hp=player.health.current_hp
	var side:int=session.world.layout.rooms[session.world.current_id].neighbors.keys()[0]
	var destination:StringName=session.world.layout.rooms[session.world.current_id].neighbors[side]
	session.world._switch_room(destination,-1)
	await test.frames(60)
	test.check(not is_instance_valid(old_room) and not is_instance_valid(marker) and not is_instance_valid(actor),"Actual Room switch releases buried actor and marker")
	test.check(player.health.current_hp==hp,"Unloaded warning cannot deliver delayed damage to retained Player")
	session.queue_free()
	await test.frames(3)
