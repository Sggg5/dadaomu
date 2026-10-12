extends "res://tests/integration_input_driver.gd"
## Input-only test operator: eight WASD directions, physical mouse aim/fire.
## Uses ordinary LOS/path queries and projectile interception; no game-state writes.
func steer(direction:Vector2)->void:
	for action in ["move_up","move_right","move_down","move_left"]:Input.action_release(action)
	if absf(direction.x)>.1:Input.action_press("move_right" if direction.x>0 else "move_left")
	if absf(direction.y)>.1:Input.action_press("move_down" if direction.y>0 else "move_up")
func intercept(enemy:Enemy)->Vector2:
	var relative:=enemy.global_position-world.player.global_position
	var speed:float=world.player.stats.projectile_speed
	var a:float=enemy.velocity.length_squared()-speed*speed
	var b:float=2*relative.dot(enemy.velocity)
	var c:float=relative.length_squared()
	var time:float=relative.length()/maxf(speed,1)
	var determinant:float=b*b-4*a*c
	if absf(a)>0.001 and determinant>=0:
		var candidate:float=(-b-sqrt(determinant))/(2*a)
		if candidate>0:time=candidate
	return enemy.global_position+enemy.velocity*minf(time,1)
func aim(enemy:Enemy)->void:
	var motion:=InputEventMouseMotion.new();motion.position=world.get_canvas_transform()*intercept(enemy)
	test.root.push_input(motion,true);Input.action_press("attack")
func sight(point:Vector2,enemy:Enemy,room:Room)->bool:
	var ray:=PhysicsRayQueryParameters2D.create(room.to_global(point),enemy.global_position,1,[world.player.get_rid(),enemy.get_rid()])
	return world.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()
func fight(limit:int=12000)->bool:
	var room:Room=world.current_room
	var grid:=AStarGrid2D.new();grid.region=Rect2i(2,5,36,14);grid.cell_size=Vector2(32,32);grid.offset=Vector2(16,0);grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.update()
	for y in range(5,19):
		for x in range(2,38):
			var point:=grid.get_point_position(Vector2i(x,y))
			if not Room.ROOM_RECT.grow(-22).has_point(point):grid.set_point_solid(Vector2i(x,y),true)
			for obstacle in room.obstacles():
				if obstacle.grow(28).has_point(point):grid.set_point_solid(Vector2i(x,y),true)
	var waypoint:Vector2=world.player.position
	for frame in range(limit):
		if world.player.health.is_dead:print("[Input bot death] ",world.current_id);release();return false
		if world.current_room!=room:release();return false
		if room.room_state.status==RoomState.Status.CLEARED:release();return true
		var targets:=room.damage_targets()
		var enemy:Enemy
		var visible:Enemy
		for actor in targets:
			if not is_instance_valid(actor) or not actor is Enemy or actor.health.is_dead:continue
			if enemy==null or actor.position.distance_to(world.player.position)<enemy.position.distance_to(world.player.position):enemy=actor
			if sight(world.player.position,actor,room) and (visible==null or actor.position.distance_to(world.player.position)<visible.position.distance_to(world.player.position)):visible=actor
		if visible!=null:enemy=visible
		if enemy==null:await tick();continue
		aim(enemy)
		if visible==null and frame%15==0:
			var goal:Vector2=world.player.position;var distance:float=INF
			for y in range(208,550,48):
				for x in range(144,1170,48):
					var point:=Vector2(x,y)
					if point.distance_to(enemy.position)<180 or room.obstacles().any(func(rect:Rect2)->bool:return rect.grow(32).has_point(point)) or not sight(point,enemy,room):continue
					var cost:float=point.distance_to(world.player.position)+absf(point.distance_to(enemy.position)-340)*.3
					if cost<distance:distance=cost;goal=point
			var route:=grid.get_point_path(nearby_cell(grid,world.player.position,room),nearby_cell(grid,goal,room))
			if route.size()>1:waypoint=route[1]
			else:waypoint=goal
		var desired:=Vector2.ZERO;var best:float=-INF
		for index in range(8):
			var direction:=Vector2.from_angle(index*TAU/8)
			var step:float=32.0 if visible!=null else clampf(world.player.position.distance_to(waypoint),8,32)
			var point:Vector2=world.player.position+direction*step
			if not Room.ROOM_RECT.grow(-18).has_point(point) or room.obstacles().any(func(rect:Rect2)->bool:return rect.grow(28).has_point(point)):continue
			var ray:=PhysicsRayQueryParameters2D.create(world.player.global_position,room.to_global(point),1,[world.player.get_rid()])
			if not world.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():continue
			var nearest:float=1000
			for actor in targets:
				if is_instance_valid(actor) and actor is Enemy and not actor.health.is_dead:nearest=minf(nearest,point.distance_to(actor.position+actor.velocity*.2))
			var score:float=minf(nearest,300)-absf(point.distance_to(enemy.position)-360)*.3
			if visible==null:score+=(world.player.position.distance_to(waypoint)-point.distance_to(waypoint))*4
			for projectile in room.projectiles.get_children():
				if projectile is EnemyProjectile:
					var close:=Geometry2D.get_closest_point_to_segment(point,projectile.position,projectile.position+projectile.velocity*.35)
					score-=maxf(0,90-close.distance_to(point))*7
			score-=room.hazards.danger_at(point)*1000
			for node in room.get_children():
				if node is BossTelegraph and node.contains(room.to_global(point)):score-=1200
			if score>best:best=score;desired=direction
		steer(desired);await tick()
	for actor in room.damage_targets():
		if is_instance_valid(actor) and actor is Enemy:print("[Unfinished target] ",actor.definition.id," position=",actor.position," HP=",actor.health.current_hp," player=",world.player.position)
	print("[Input bot timeout] ",world.current_id," hp=",world.player.health.current_hp," remaining=",room.remaining_count());release();return false

func walk(target:Vector2,limit:int=1200)->bool:
	var room:=world.current_room
	var grid:=AStarGrid2D.new()
	grid.region=Rect2i(2,5,36,14);grid.cell_size=Vector2(32,32);grid.offset=Vector2(16,0)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y in range(5,19):
		for x in range(2,38):
			var point:=grid.get_point_position(Vector2i(x,y))
			if not Room.ROOM_RECT.grow(-22).has_point(point):grid.set_point_solid(Vector2i(x,y),true)
			for obstacle in room.obstacles():
				if obstacle.grow(22).has_point(point):grid.set_point_solid(Vector2i(x,y),true)
	var end:=nearby_cell(grid,target,room)
	for frame in range(limit):
		if world.player.health.is_dead or world.current_room!=room:release();return false
		var delta:=target-world.player.position
		if delta.length()<15:release();await tick();return true
		var start:=nearby_cell(grid,world.player.position,room)
		var path:=grid.get_point_path(start,end)
		if path.is_empty():
			print("[Walk no path] room=",world.current_id," player=",world.player.position," target=",target," cells=",start," -> ",end)
			release();return false
		var next:=path[0] if world.player.position.distance_to(path[0])>24 else path[1] if path.size()>1 else target
		steer((next-world.player.position).normalized())
		await tick()
	print("[Walk timeout] room=",world.current_id," player=",world.player.position," target=",target)
	release();return false
