extends RefCounted
var test:SceneTree
const TOMB:TombDefinition=preload("res://data/tombs/default_tomb.tres")
func _init(context:SceneTree)->void:test=context
func run()->void:
	var records:Array=[]
	for number in range(1,6):
		for definition:Variant in TOMB.floor_at(number).boss_pool.bosses:
			for count in [3,8,12]:
				var session:=preload("res://scenes/main/dungeon_test.tscn").instantiate() as DungeonSession
				session.seed_value=33
				test.root.add_child(session)
				test.session=session
				test.current_scene=session
				await test.frames(3)
				if number!=1:
					session._drop_world()
					session.floor_number=number
					session._assemble_world(session.floor_layout(number))
					await test.frames(3)
				var world:=session.world
				world.boss_definition=definition
				var plan:=RelicRewardPlan.build(77,5,RelicRewardService.PRODUCTION_POOL)
				var index:=0
				for source in plan.assigned:
					if index<count:world.player.relics.inventory.add(plan.assigned[source])
					index+=1
				world._switch_room(world.layout.boss_id,-1)
				await test.frames(3)
				var boss:=world.current_room.boss_encounter.boss
				var driver=preload("res://tests/threat_fight_driver.gd").new(test)
				var ticks:=0
				var minimum_hp:=world.player.health.current_hp
				for iteration in range(5000):
					if world.current_room.boss_encounter.finished or world.player.health.is_dead:break
					var targets:Array=boss.combat_targets() if boss.has_method("combat_targets") else [boss]
					if targets.is_empty():break
					await driver.shoot_safe(targets[0])
					ticks+=3
					minimum_hp=minf(minimum_hp,world.player.health.current_hp)
					if count==12 and iteration==20:test.capture(str(definition.id)+"_12_action")
				var phases:Dictionary=boss.get("phases_seen")
				var row:={"boss":str(definition.id),"relics":count,"build_ids":world.player.relics.inventory.ids(),"seconds":ticks/60.0,"skills":boss.get("skills_executed"),"phases":phases.keys(),"hp_lost":80-minimum_hp,"defeated":world.current_room.boss_encounter.finished}
				records.append(row)
				print("[Boss benchmark] ",JSON.stringify(row))
				test.check(world.current_room.boss_encounter.finished and not world.player.health.is_dead,"Actual 3/8/12-item weapon defeats Boss: "+str(definition.id))
				test.check(world.current_room.room_state.status==RoomState.Status.CLEARED and world.current_room.has_node("PlannedRelic"),"One encounter defeat opens room and creates one stable Boss reward")
				if count==12:test.capture(str(definition.id)+"_high_build_clear")
				session.queue_free()
				await test.frames(3)
	# Fixed-position high Build probe: measures this fixture only, never claims human difficulty.
	for number in range(1,6):
		for definition:Variant in TOMB.floor_at(number).boss_pool.bosses:
			var session:=preload("res://scenes/main/dungeon_test.tscn").instantiate() as DungeonSession
			session.seed_value=33
			test.root.add_child(session)
			test.session=session
			test.current_scene=session
			await test.frames(3)
			if number!=1:
				session._drop_world()
				session.floor_number=number
				session._assemble_world(session.floor_layout(number))
				await test.frames(3)
			var world:=session.world
			world.boss_definition=definition
			# A fixed-position firing probe requires open LOS. Moving/specific-wall suites
			# keep real obstacles; otherwise a twin moving behind a coffin is a timeout,
			# rather than a measurement of standing still against the new combo rhythm.
			world.layout.rooms[world.layout.boss_id].definition=world.layout.rooms[world.layout.boss_id].definition.duplicate()
			world.layout.rooms[world.layout.boss_id].definition.obstacles=[]
			var plan:=RelicRewardPlan.build(77,5,RelicRewardService.PRODUCTION_POOL)
			var index:=0
			for source in plan.assigned:
				if index<12:world.player.relics.inventory.add(plan.assigned[source])
				index+=1
			world._switch_room(world.layout.boss_id,-1)
			await test.frames(3)
			var boss:=world.current_room.boss_encounter.boss
			var driver=preload("res://tests/threat_fight_driver.gd").new(test)
			var targets:Array=boss.combat_targets() if boss.has_method("combat_targets") else [boss]
			await driver.shoot_safe(targets[0]) # one legal initial position, then never move
			var ticks:=3
			for iteration in range(1600):
				if world.current_room.boss_encounter.finished or world.player.health.is_dead:break
				targets=boss.combat_targets() if boss.has_method("combat_targets") else [boss]
				if targets.is_empty():break
				world.player.weapon.try_attack(world.player.global_position,(targets[0].global_position-world.player.global_position).normalized(),world.player.stats)
				await test.frames(3)
				ticks+=3
			var row:={"boss":str(definition.id),"relics":12,"build_ids":world.player.relics.inventory.ids(),"mode":"stationary","seconds":ticks/60.0,"skills":boss.get("skills_executed"),"phases":boss.get("phases_seen").keys(),"hp_lost":80-world.player.health.current_hp,"defeated":world.current_room.boss_encounter.finished,"player_dead":world.player.health.is_dead}
			records.append(row)
			print("[Boss stationary] ",JSON.stringify(row))
			test.check(world.current_room.boss_encounter.finished or world.player.health.is_dead,"Standing still probe produces a real terminal outcome")
			session.queue_free()
			await test.frames(3)
	var file:=FileAccess.open("res://logs/phase_9b32_boss_benchmarks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(records,"  "))
