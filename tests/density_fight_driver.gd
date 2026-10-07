extends "res://tests/phase_5b_run_checks.gd"
func visit(target: StringName) -> void:
	await super.visit(target)
	await claim()
func claim() -> void:
	await super.claim()
	var world:RoomController=test.session.world
	var pedestal:=world.current_room.get_node_or_null("PlannedRelic") as RelicPedestal
	if pedestal==null:return
	world.player.position=pedestal.position+Vector2(24,0)
	world.player.velocity=Vector2.ZERO
	await test.frames(1)
	var id:=pedestal.definition.id
	test.key(KEY_E)
	test.check(world.player.relics.inventory.has(id) and pedestal.claimed,"Real E picks stable item-room/Boss source")
	picked.append(id)
	await test.frames(2)
func fight() -> void:
	var world:RoomController=test.session.world
	if world.current_room.room_state.status!=RoomState.Status.ACTIVE:return
	for cycle in range(180):
		var actors:=CombatGeometry.targets(world.current_room)
		if actors.is_empty():break
		if world.player.health.is_dead:break
		var enemy:=actors[0] as Enemy
		await shoot_safe(enemy)
	test.check(not world.player.health.is_dead and world.current_room.room_state.status==RoomState.Status.CLEARED,"Density room including dynamic summons really clears")
	await claim()
func shoot_safe(enemy:Enemy) -> void:
	var world:RoomController=test.session.world
	var safest:=world.player.position
	var best:float=-INF
	for y in range(208,538,48):
		for x in range(160,1160,48):
			var point:=Vector2(x,y)
			var distance:=point.distance_to(enemy.position)
			if distance<230 or distance>420:continue
			if world.current_room.obstacles().any(func(rect:Rect2)->bool:return rect.grow(24).has_point(point)):continue
			var ray:=PhysicsRayQueryParameters2D.create(enemy.position,point,1,[enemy.get_rid()])
			if not enemy.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():continue
			var score:float=500-absf(distance-300)
			for other in CombatGeometry.targets(world.current_room):
				if other!=enemy:score=minf(score,point.distance_to(other.position))
			for projectile in world.current_room.projectiles.get_children():
				if projectile is EnemyProjectile:
					var closest:=Geometry2D.get_closest_point_to_segment(point,projectile.position,projectile.position+projectile.velocity*0.3)
					score=minf(score,point.distance_to(closest)*2)
			if score>best:best=score;safest=point
	world.player.position=safest
	world.player.velocity=Vector2.ZERO
	world.player.weapon.try_attack(safest,(enemy.position-safest).normalized(),world.player.stats)
	await test.frames(10)
func boss_fight() -> void:
	var room:Room=test.session.world.current_room
	for tick in range(900):
		if room.boss_encounter.finished or test.session.world.player.health.is_dead:break
		await shoot_safe(room.boss_encounter.boss)
	test.check(room.boss_encounter.finished and not test.session.world.player.health.is_dead,"Actual weapon defeats each distinct Boss with earned Build")
	await test.frames(3)
	await claim()
