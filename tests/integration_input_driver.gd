extends RefCounted
## 11I primary driver: only movement/aim/attack input. No position, HP or inventory writes.
## The bot knows the generated graph; this does not establish human readability.
var test: SceneTree
var world: RoomController
var collect_rewards:bool=false
func _init(context:SceneTree, controller:RoomController)->void:
	test=context;world=controller
func release()->void:
	for action in ["move_up","move_right","move_down","move_left","attack"]:Input.action_release(action)
func steer(direction:Vector2)->void:
	for action in ["move_up","move_right","move_down","move_left"]:Input.action_release(action)
	if absf(direction.x)>.1:Input.action_press("move_right" if direction.x>0 else "move_left",absf(direction.x))
	if absf(direction.y)>.1:Input.action_press("move_down" if direction.y>0 else "move_up",absf(direction.y))
func tick()->void:
	await test.physics_frame
	await test.process_frame
func nearby_cell(grid:AStarGrid2D,point:Vector2,room:Room)->Vector2i:
	var nearest:=Vector2i(roundi((point.x-16)/32),roundi(point.y/32)).clamp(Vector2i(2,5),Vector2i(37,18))
	var best:=nearest;var cost:float=INF
	for y in range(maxi(5,nearest.y-3),mini(19,nearest.y+4)):
		for x in range(maxi(2,nearest.x-3),mini(38,nearest.x+4)):
			var cell:=Vector2i(x,y)
			if grid.is_point_solid(cell):continue
			var candidate:=grid.get_point_position(cell)
			var ray:=PhysicsRayQueryParameters2D.create(room.to_global(point),room.to_global(candidate),1,[world.player.get_rid()])
			if not world.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():continue
			if candidate.distance_squared_to(point)<cost:cost=candidate.distance_squared_to(point);best=cell
	return best
func walk(target:Vector2,limit:int=1200)->bool:
	var room:=world.current_room
	var grid:=AStarGrid2D.new()
	grid.region=Rect2i(2,5,36,14);grid.cell_size=Vector2(32,32);grid.offset=Vector2(16,0)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y in range(5,19):
		for x in range(2,38):
			var point:=grid.get_point_position(Vector2i(x,y))
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
func fight(limit:int=12000)->bool:
	var room:=world.current_room
	for frame in range(limit):
		if frame==120:test.capture("input_combat")
		if world.player.health.is_dead:
			print("[Input bot death] room=",world.current_id," frame=",frame," remaining=",room.remaining_count());release();return false
		if room.room_state.status==RoomState.Status.CLEARED:release();return true
		var targets:=room.damage_targets()
		var enemy:Enemy
		for actor in targets:
			if not is_instance_valid(actor) or not actor is Enemy or actor.health.is_dead:continue
			if enemy==null or actor.position.distance_to(world.player.position)<enemy.position.distance_to(world.player.position):enemy=actor
		if enemy!=null:
			if frame%30==0:
				var sight:=PhysicsRayQueryParameters2D.create(world.player.global_position,enemy.global_position,1,[world.player.get_rid(),enemy.get_rid()])
				if not world.get_world_2d().direct_space_state.intersect_ray(sight).is_empty():
					var goal:=world.player.position;var cost:float=INF
					for y in range(208,550,48):
						for x in range(144,1170,48):
							var point:=Vector2(x,y)
							if point.distance_to(enemy.position)<220:continue
							if room.obstacles().any(func(rect:Rect2)->bool:return rect.grow(28).has_point(point)):continue
							var ray:=PhysicsRayQueryParameters2D.create(room.to_global(point),enemy.global_position,1,[enemy.get_rid(),world.player.get_rid()])
							if not world.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():continue
							var distance:=point.distance_to(world.player.position)+absf(point.distance_to(enemy.position)-300)*.5
							if distance<cost:cost=distance;goal=point
					await walk(goal,180)
					if not is_instance_valid(enemy) or enemy.health.is_dead:continue
			var aim:=enemy.global_position+enemy.velocity*.15
			var motion:=InputEventMouseMotion.new();motion.position=world.get_canvas_transform()*aim;test.root.push_input(motion,true)
			Input.action_press("attack")
			var best:float=-INF
			var desired:=Vector2.ZERO
			for index in range(16):
				var direction:=Vector2.from_angle(index*TAU/16.0)
				var point:=world.player.position+direction*100
				if not Room.ROOM_RECT.grow(-38).has_point(point):continue
				var blocked:=false
				for obstacle in room.obstacles():
					if obstacle.grow(28).has_point(point):blocked=true
				if blocked:continue
				var ray:=PhysicsRayQueryParameters2D.create(room.to_global(world.player.position),room.to_global(point),1,[world.player.get_rid()])
				if not world.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():continue
				var nearest:float=1000
				for actor in targets:
					if is_instance_valid(actor) and actor is Enemy and not actor.health.is_dead:nearest=minf(nearest,point.distance_to(actor.position+actor.velocity*.3))
				var score:float=minf(nearest,280)-absf(point.distance_to(enemy.position)-330)*.15
				for projectile in room.projectiles.get_children():
					if projectile is EnemyProjectile:
						var close:=Geometry2D.get_closest_point_to_segment(point,projectile.position,projectile.position+projectile.velocity*.4)
						score-=maxf(0,80-close.distance_to(point))*5
				score-=room.hazards.danger_at(point)*600
				for node in room.get_children():
					if node is BossTelegraph and node.contains(room.to_global(point)):score-=1000
				if score>best:best=score;desired=direction
			steer(desired)
		await tick()
	print("[Input bot timeout] room=",world.current_id," hp=",world.player.health.current_hp," remaining=",room.remaining_count());release();return false
func visit(destination:StringName)->bool:
	var queue:Array[StringName]=[world.current_id]
	var parents:Dictionary={world.current_id: &""}
	while not queue.is_empty():
		var id:StringName=queue.pop_front()
		if id==destination:break
		for other in world.layout.rooms[id].neighbors.values():
			if not parents.has(other):parents[other]=id;queue.append(other)
	if not parents.has(destination):return false
	var route:Array[StringName]=[];var cursor:=destination
	while cursor!=world.current_id:route.push_front(cursor);cursor=parents[cursor]
	for next_id in route:
		if not await fight():return false
		if collect_rewards:await claim()
		var side:int=world.layout.rooms[world.current_id].neighbors.find_key(next_id)
		var direction:Vector2=[Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT][side]
		var door:Vector2=Room.ROOM_RECT.get_center()+direction*Vector2(576,224)
		if not await walk(door-direction*40):return false
		steer(direction)
		for frame in range(120):
			await tick()
			if world.current_id==next_id:break
		release()
		if world.current_id!=next_id:return false
		await test.frames(5)
	var cleared:bool=await fight()
	if cleared and collect_rewards:await claim()
	return cleared
func claim()->void:
	for node in world.current_room.get_children():
		if node is RelicPedestal or (node is AntiquePedestal and node.source_id==&"combat_cache" and world.player.antiques.can_add(node.definition)):
			if await walk(node.position+Vector2(24,0)):
				test.key(KEY_E);await test.frames(3)


