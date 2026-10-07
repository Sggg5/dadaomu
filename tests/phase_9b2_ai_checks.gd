extends RefCounted
var test:SceneTree
func _init(context:SceneTree)->void:test=context
func run()->void:
	var session:=preload("res://scenes/main/dungeon_test.tscn").instantiate() as DungeonSession
	session.tomb=preload("res://tests/fixtures/pre_threat_tomb.tres")
	session.profiled_relic_rewards=false
	session.seed_value=33
	test.root.add_child(session)
	test.session=session
	test.current_scene=session
	await test.frames(3)
	# New ordinary behavior tests use live instances and bounded summon accounting.
	var spawner:=session.world.current_room.enemy_spawner
	var definition:=RoomDefinition.new()
	for index in range(3):
		var entry:=EnemySpawnDefinition.new()
		entry.enemy_scene=preload("res://scenes/enemies/brood_mother.tscn")
		entry.enemy_definition=preload("res://data/enemies/brood_mother.tres")
		entry.position=Vector2(400+index*160,300)
		definition.spawns.append(entry)
	spawner.spawn(definition)
	await test.frames(30)
	for actor in spawner.get_children():
		if actor is BroodMother:
			for repeat in range(10):spawner._request_summon(2,actor)
	await test.frames(3)
	test.check(spawner.get_remaining()==7 and spawner.get_remaining()<=3+EnemySpawner.MAX_SUMMONS,"Ordinary mother summons bounded by room and owner limits")
	for actor in spawner.get_children():
		if actor is ScarabEnemy: actor.health.take_damage(9999)
	await test.frames(2)
	for actor in spawner.get_children():
		if actor is BroodMother:
			for repeat in range(10): spawner._request_summon(2,actor)
	await test.frames(3)
	test.check(spawner.summons_created==8 and spawner.get_remaining()<=7,"Mother room also has a finite total summon budget")
	for actor in spawner.get_children():
		if actor is Enemy:actor.health.take_damage(9999)
	await test.frames(3)
	test.check(spawner.get_remaining()==0,"Summoned deaths participate in room clear accounting")
	var dog:=preload("res://scenes/enemies/corpse_dog.tscn").instantiate() as CorpseDog
	dog.configure_spawn(session.world.player,session.world.current_room.projectiles)
	dog.position=Vector2(880,368)
	session.world.current_room.add_child(dog)
	session.world.player.position=Vector2(1040,368)
	await test.frames(65)
	test.check(dog.attacks>0,"Live dog executes locked dash and recovery")
	dog.queue_free()
	var paper:=preload("res://scenes/enemies/paper_spirit.tscn").instantiate() as PaperSpirit
	paper.configure_spawn(session.world.player,session.world.current_room.projectiles)
	paper.position=Vector2(400,240)
	session.world.current_room.add_child(paper)
	session.world.player.position=Vector2(400,496)
	await test.frames(110)
	test.check(paper.volleys>0,"Live paper spirit performs three-shot volley")
	paper.queue_free()
	session.queue_free()
	await test.frames(3)
	for number in [1,3,4]:
		session=preload("res://scenes/main/dungeon_test.tscn").instantiate() as DungeonSession
		session.tomb=preload("res://tests/fixtures/pre_threat_tomb.tres")
		session.profiled_relic_rewards=false
		session.seed_value=33
		test.root.add_child(session)
		test.session=session
		test.current_scene=session
		await test.frames(3)
		if number!=1:
			session._drop_world()
			session.floor_number=number
			session._assemble_world(session.floor_layout(number))
			test.session=session
		var world:=session.world
		world._switch_room(world.layout.boss_id,-1)
		var boss:=world.current_room.boss_encounter.boss
		boss.health.take_damage(boss.health.max_hp*0.51)
		var saw_decoys:=false
		var saw_dash:=false
		for tick in range(480):
			world.player.position=Vector2(1000 if tick%60<30 else 280,496)
			world.player.velocity=Vector2.ZERO
			await test.frames(1)
			if boss is ScarabNest: saw_dash=saw_dash or boss.dashing
			if boss is PaperGeneral and boss.decoys.any(func(reference:WeakRef)->bool:return is_instance_valid(reference.get_ref())):
				if not saw_decoys:test.capture("paper_general_decoys")
				saw_decoys=true
			if world.player.health.is_dead:break
		if boss is ScarabNest:
			test.check(saw_dash,"Nest half-health pattern actually performs side movement")
			test.check(boss.cycles>0 and boss.rage and world.current_room.boss_encounter.summons.size()<=6,"Nest rage bursts and bounded swarm differ from scarab melee")
		if boss is PaperGeneral:
			test.check(saw_decoys,"Two live decoys actually appear with weak attacks")
			test.check(boss.volleys>=2 and boss.rage and boss.decoys.size()<=2,"Paper general strafes, cross volleys and bounded decoys")
		if boss is BronzeKing:
			test.check(boss.slams>0 and boss.charges>0,"Bronze king performs heavy slam and short charge")
			boss.state=BronzeKing.State.GUARD
			boss.direction=Vector2.RIGHT
			boss.guard_locked=true
			world.player.position=boss.position+Vector2(120,0)
			var hp:=boss.health.current_hp
			boss.take_damage(10)
			test.check(is_equal_approx(hp-boss.health.current_hp,4.5),"Bronze frontal guard reduces damage, not HP inflation")
			world.player.position=boss.position+Vector2(-120,0)
			boss.aim_direction=Vector2.LEFT
			boss._tick_ai(0.016)
			test.check(boss.direction==Vector2.RIGHT,"Guard facing remains locked so actual flanking is possible")
			hp=boss.health.current_hp
			boss.take_damage(10)
			test.check(is_equal_approx(hp-boss.health.current_hp,10),"Flanking bypasses temporary frontal guard")
		test.capture("boss_%d_patterns" % number)
		session.queue_free()
		await test.frames(3)
