extends "res://tests/density_fight_driver.gd"
func fight() -> void:
	var world:RoomController=test.session.world
	if world.current_room.room_state.status!=RoomState.Status.ACTIVE:return
	for cycle in range(2000):
		var actors:=CombatGeometry.targets(world.current_room)
		if actors.is_empty():
			if world.current_room.enemy_spawner.get_remaining()==0:break
			await test.frames(3)
			continue
		if world.player.health.is_dead:break
		if cycle%200==0:print('[AI trace] ',world.current_id,' HP=',world.player.health.current_hp,' actors=',actors.map(func(a:Enemy)->String:return str(a.definition.id)+':'+str(a.health.current_hp)))
		var enemy:=actors[0] as Enemy
		for actor in actors:
			if actor is BurrowingCorpse and actor.state==BurrowingCorpse.State.SURFACE:enemy=actor;break
		await shoot_safe(enemy)
	print("[threat fight] ",world.current_id," hp=",world.player.health.current_hp," remaining=",world.current_room.enemy_spawner.get_remaining()," build=",world.player.relics.inventory.ids())
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
			if distance<230 or distance>800:continue
			if world.current_room.definition.obstacles.any(func(rect:Rect2)->bool:return rect.grow(24).has_point(point)):continue
			var ray:=PhysicsRayQueryParameters2D.create(enemy.position,point,1,[enemy.get_rid()])
			if not enemy.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():continue
			var score:float=500-absf(distance-300)
			for other in CombatGeometry.targets(world.current_room):
				if other!=enemy:score=minf(score,point.distance_to(other.position))
				if other is TombCrossbow and other.winding:
					var aim_end:Vector2=other.position+other.locked_direction*1100
					if Geometry2D.get_closest_point_to_segment(point,other.position,aim_end).distance_to(point)<50:score-=600
				if other is CorpseDog and other.state in [CorpseDog.State.WINDUP,CorpseDog.State.DASH]:
					var dash_end:Vector2=other.position+other.aim_direction*230
					if Geometry2D.get_closest_point_to_segment(point,other.position,dash_end).distance_to(point)<60:score-=600
			for projectile in world.current_room.projectiles.get_children():
				if projectile is EnemyProjectile:
					var closest:=Geometry2D.get_closest_point_to_segment(point,projectile.position,projectile.position+projectile.velocity*0.3)
					score=minf(score,point.distance_to(closest)*2)
			score-=world.current_room.hazards.danger_at(point)*400
			if score>best:best=score;safest=point
	world.player.position=safest
	world.player.velocity=Vector2.ZERO
	world.player.weapon.try_attack(safest,(enemy.position-safest).normalized(),world.player.stats)
	await test.frames(3)
func boss_fight() -> void:
	var room:Room=test.session.world.current_room
	for tick in range(3000):
		if room.boss_encounter.finished or test.session.world.player.health.is_dead:break
		await shoot_safe(room.boss_encounter.boss)
	test.check(room.boss_encounter.finished and not test.session.world.player.health.is_dead,"Actual weapon defeats each distinct Boss with earned Build")
	await test.frames(3)
	await claim()
