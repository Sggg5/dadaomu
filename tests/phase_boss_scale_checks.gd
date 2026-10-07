extends "res://tests/phase_9b32_mechanic_checks.gd"
const RADII:Dictionary={"scarab_nest":40,"coffin_old_corpse":44,"jinbei_warlord_corpse":36,"chain_zombie":36,"paper_general":32,"centipede_mother":44,"bronze_king":48,"twin_revenants":32,"tomb_guardian_beast":52,"tomb_master":42}
func run()->void:
	var records:Array=[]
	for number in range(1,6):
		for definition:Variant in TOMB.floor_at(number).boss_pool.bosses:
			for distance in [150,300,500]:
				await setup(definition,true)
				var actors:Array=boss.combat_targets() if boss.has_method("combat_targets") else [boss]
				for actor:Enemy in actors:
					test.check(actor.body_radius()==RADII[str(definition.id)],"Actual Boss collider radius: "+str(definition.id))
					test.check(world.current_room.obstacles().all(func(rect:Rect2)->bool:return not rect.grow(actor.body_radius()).has_point(world.current_room.to_local(actor.global_position))),"Actual sized Boss spawn clears current Arena")
				# Keep initial separation exact; movement/skills afterwards are real, no repeated relocation.
				world.player.position=Vector2(400+distance,368)
				actors[0].global_position=world.current_room.to_global(Vector2(400,368))
				if actors.size()>1:actors[1].global_position=world.current_room.to_global(Vector2(400,268))
				if distance==300:test.capture(str(definition.id)+"_body")
				var hp:=world.player.health.current_hp
				for frame in range(1800):
					if world.player.health.is_dead:break
					await test.frames(1)
				var skills:int=boss.get("skills_executed")
				var history:Variant=boss.get("skill_history")
				if history==null and boss.has_method("combat_targets"):
					history=[]
					for actor in actors:history.append_array(actor.skill_history)
				records.append({"boss":str(definition.id),"initial_distance":distance,"skills":skills,"history":history,"hp_lost":hp-world.player.health.current_hp,"dead":world.player.health.is_dead})
				test.check(skills>0,"Actual near/mid/far AI executes skills")
				if number>=3 and distance==500:test.check(world.player.health.current_hp<hp,"F3-F5 500px is not a permanent zero-pressure zone: "+str(definition.id))
				test.capture(str(definition.id)+"_scale_"+str(distance))
				session.queue_free()
				await test.frames(3)
	FileAccess.open("res://logs/boss_distance_statistics.json",FileAccess.WRITE).store_string(JSON.stringify(records,"  "))
	print("[Boss distance] ",JSON.stringify(records))
