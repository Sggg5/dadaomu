extends RefCounted
## Count snapshots model natural floor progression; weapon/projectile combat remains real.
## Driver relocates to safe points and is not a human skill/duration measurement.
var test:SceneTree
const TOMB:TombDefinition=preload("res://data/tombs/default_tomb.tres")
func _init(context:SceneTree)->void:test=context
func run()->void:
	var records:Array=[]
	for mode in ["moving","stationary"]:
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
				# Stationary pressure probe uses open geometry, so a wall cannot explain missed shots.
				if mode=="stationary":
					world.boss_arena_override=BossArenaDefinition.new()
					world.boss_arena_override.id=&"UNIT_OPEN"
					world.boss_arena_override.tags=definition.compatible_arena_tags.duplicate()
					world.layout.rooms[world.layout.boss_id].definition=world.layout.rooms[world.layout.boss_id].definition.duplicate()
					world.layout.rooms[world.layout.boss_id].definition.obstacles=[]
				var plan:=RelicRewardPlan.build(77,5,RelicRewardService.PRODUCTION_POOL)
				var count:int=[3,5,8,11,13][number-1]
				var index:=0
				for source in plan.assigned:
					if index<count:world.player.relics.inventory.add(plan.assigned[source])
					index+=1
				world._switch_room(world.layout.boss_id,-1)
				await test.frames(3)
				var boss:=world.current_room.boss_encounter.boss
				var build_ids:=world.player.relics.inventory.ids()
				var driver=preload("res://tests/threat_fight_driver.gd").new(test)
				var ticks:=0
				var targets:Array=boss.combat_targets() if boss.has_method("combat_targets") else [boss]
				if mode=="stationary":await driver.shoot_safe(targets[0])
				for iteration in range(2400):
					if world.current_room.boss_encounter.finished or world.player.health.is_dead:break
					targets=boss.combat_targets() if boss.has_method("combat_targets") else [boss]
					if targets.is_empty():break
					if mode=="moving":await driver.shoot_safe(targets[0])
					else:
						world.player.weapon.try_attack(world.player.global_position,(targets[0].global_position-world.player.global_position).normalized(),world.player.stats)
						await test.frames(3)
					ticks+=3
					if iteration==70:test.capture(str(definition.id)+"_"+mode+"_pressure")
				var actions:int=boss.get("skills_executed")
				var skips:int=boss.get("phase_skip_count") if boss.get("phase_skip_count")!=null else 0
				var phases:Array=boss.get("phases_seen").keys()
				var row:={"boss":str(definition.id),"floor":number,"relics":count,"build_seed":77,"build_ids":build_ids,"mode":mode,"seconds":ticks/60.0,"cycles":boss.get("cycles"),"combos":boss.get("combinations"),"actions":actions,"phases":phases,"phase_skips":skips,"phase_actions":boss.get("phase_actions"),"hp_lost":80-world.player.health.current_hp,"defeated":world.current_room.boss_encounter.finished,"player_dead":world.player.health.is_dead,"below_action_reference":actions<number+2}
				records.append(row)
				print("[Natural Boss] ",JSON.stringify(row))
				test.check(world.current_room.boss_encounter.finished or world.player.health.is_dead,"Natural Build produces finite combat outcome: "+str(definition.id)+" "+mode)
				if mode=="moving":test.check(world.current_room.boss_encounter.finished,"Safe-point moving weapon driver defeats natural Boss: "+str(definition.id))
				session.queue_free()
				await test.frames(3)
	var file:=FileAccess.open("res://logs/phase_9b33_natural_benchmarks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(records,"  "))
