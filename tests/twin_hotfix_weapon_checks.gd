extends RefCounted
class PlaytestPause extends Node:
	func _input(event:InputEvent)->void:
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_P:
			get_tree().paused=not get_tree().paused
var test:SceneTree
var states:Dictionary={}
func _init(context:SceneTree)->void:test=context
func drive(world:RoomController,actor:Enemy,shoot:bool)->void:
	var player:=world.player
	var safest:=player.global_position
	var best:float=-INF
	for y in range(230,540,48):
		for x in range(160,1140,48):
			var point:=Vector2(x,y)
			if world.current_room.obstacles().any(func(rect:Rect2)->bool:return rect.grow(28).has_point(point)):continue
			var global_point:=world.current_room.to_global(point)
			var ray:=PhysicsRayQueryParameters2D.create(player.global_position,global_point,1,[player.get_rid()])
			if not player.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():continue
			var sight:=PhysicsRayQueryParameters2D.create(actor.global_position,global_point,1,[actor.get_rid()])
			if not actor.get_world_2d().direct_space_state.intersect_ray(sight).is_empty():continue
			var score:=400-absf(global_point.distance_to(actor.global_position)-430)-player.global_position.distance_to(global_point)*0.2
			for other in world.current_room.boss_encounter.targets():
				score=minf(score,global_point.distance_to(other.global_position)-100)
				if other is MechanismBoss and other.state in [&"WINDUP",&"DASH"] and other.current.get("kind")==&"CHARGE":
					var end:Vector2=other.global_position+other.locked*600
					if Geometry2D.get_closest_point_to_segment(global_point,other.global_position,end).distance_to(global_point)<80:score-=800
			for node in world.current_room.get_children():
				if node is BossTelegraph and node.contains(global_point):score-=1000
			for bullet in world.current_room.projectiles.get_children():
				if bullet is EnemyProjectile:
					var closest:=Geometry2D.get_closest_point_to_segment(global_point,bullet.global_position,bullet.global_position+bullet.velocity*0.45)
					score=minf(score,global_point.distance_to(closest)*2-60)
			if score>best:best=score;safest=global_point
	var direction:Vector2=(safest-player.global_position).normalized()
	for action in [&"move_up",&"move_right",&"move_down",&"move_left"]:Input.action_release(action)
	if absf(direction.x)>0.2:Input.action_press("move_right" if direction.x>0 else "move_left",absf(direction.x))
	if absf(direction.y)>0.2:Input.action_press("move_down" if direction.y>0 else "move_up",absf(direction.y))
	if shoot:
		var travel:=player.global_position.distance_to(actor.global_position)/player.stats.projectile_speed
		player.weapon.try_attack(player.global_position,(actor.global_position+actor.velocity*minf(travel,0.25)-player.global_position).normalized(),player.stats)
	states[actor.state]=true
	await test.frames(1)
func run()->void:
	for arena_path in ["boss_dual_open","boss_corner_cover"]:
		for first in [0,1]:
			var flow:=preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
			flow.profile_store=MuseumProfileStore.in_memory()
			flow.forced_night_seed=33
			test.root.add_child(flow)
			await test.frames(3)
			preload("res://tests/expedition_map_fixture.gd").confirm(flow)
			await test.frames(5)
			test.session=flow.dungeon
			var session:DungeonSession=test.session
			# Isolated fast-arrival fixture; combat below is untouched production weapons/AI/physics.
			var carry:=RunCarryState.capture(session.world.player)
			session._drop_world()
			session.floor_number=4
			session.boss_plan.assigned[4]=preload("res://data/bosses/twin_revenants.tres")
			session._assemble_world(session.floor_layout(4))
			carry.apply(session.world.player)
			# Small explicit carried-build fixture, not edits to shared/base PlayerStats.
			session.world.player.relics.inventory.add(preload("res://data/relics/black_powder.tres"))
			session.world.player.relics.inventory.add(preload("res://data/relics/chain_spring.tres"))
			session.world.player.relics.inventory.add(preload("res://data/relics/blood_contract.tres"))
			session.world.player.relics.inventory.add(preload("res://data/relics/flying_tiger_boots.tres"))
			var world:=session.world
			world.boss_arena_override=load("res://data/geometries/arenas/"+arena_path+".tres")
			world._switch_room(world.layout.boss_id,-1)
			await test.frames(3)
			var boss:Enemy=world.current_room.boss_encounter.boss
			var members:Array=boss.get("members")
			if "--manual" in OS.get_cmdline_user_args():
				DisplayServer.window_set_title("双生尸煞热修试玩 · Seed33 · F4 · 按P开始/暂停 · 隔离存档")
				var pause_control:=PlaytestPause.new()
				pause_control.process_mode=Node.PROCESS_MODE_ALWAYS
				test.root.add_child(pause_control)
				test.paused=true
				return
			for frame in range(7200):
				if not is_instance_valid(members[first]) or members[first].health.is_dead or world.player.health.is_dead:break
				await drive(world,members[first],true)
			test.check(not world.player.health.is_dead and (not is_instance_valid(members[first]) or members[first].health.is_dead),"Weapon kills first twin %d in %s"%[first,arena_path])
			if world.player.health.is_dead:
				flow.queue_free();await test.frames(3);continue
			var survivor:Enemy=members[1-first]
			states.clear()
			var cycles:int=survivor.cycles
			for frame in range(660):
				if world.player.health.is_dead:break
				await drive(world,survivor,false)
				if frame==330:test.capture("twin_solo_"+arena_path+"_order"+str(first))
			test.check(not is_instance_valid(members[first]),"Corpse freed during physical solo stage")
			test.check(survivor.solo and survivor.may_attack and survivor.cycles>=cycles+2,"Solo completes multiple attack cycles")
			test.check(is_equal_approx(world.hud.boss_display.bar.value,boss.health.current_hp),"Shared HUD follows living member")
			test.check(states.has(&"WINDUP") and states.has(&"RECOVERY"),"Physical AI visits windup and recovery")
			var hp:float=boss.health.current_hp
			for frame in range(7200):
				if world.current_room.boss_encounter.finished or world.player.health.is_dead:break
				await drive(world,survivor,true)
			test.capture("twin_"+arena_path+"_order"+str(first))
			print("[Weapon lifecycle] arena=",arena_path," first=",first," playerHP=",world.player.health.current_hp," sharedHP=",boss.health.current_hp," solo=",survivor.solo," may_attack=",survivor.may_attack," state=",survivor.state," turn=",boss.turn," actorPosition=",survivor.global_position," playerPosition=",world.player.global_position)
			test.check(world.current_room.boss_encounter.finished and boss.health.current_hp<hp,"Real survivor weapon damage ends shared encounter")
			test.check(session.bosses_defeated==1 and world.current_room.room_state.status==RoomState.Status.CLEARED,"Exactly one boss settlement and cleared room")
			if not world.player.health.is_dead and world.current_room.boss_encounter.finished:
				var exit:Node2D=world.current_room.get_node("ExpeditionExit")
				for frame in range(600):
					var offset:Vector2=exit.global_position-world.player.global_position
					if offset.length()<30:break
					for action in [&"move_up",&"move_right",&"move_down",&"move_left"]:Input.action_release(action)
					if absf(offset.x)>8:Input.action_press("move_right" if offset.x>0 else "move_left")
					if absf(offset.y)>8:Input.action_press("move_down" if offset.y>0 else "move_up")
					await test.frames(1)
				for action in [&"move_up",&"move_right",&"move_down",&"move_left"]:Input.action_release(action)
				test.key(KEY_E)
				await test.frames(5)
				test.check(session.floor_number==5,"Fifth floor assembled after twin victory")
			for action in [&"move_up",&"move_right",&"move_down",&"move_left"]:Input.action_release(action)
			flow.queue_free()
			await test.frames(4)
