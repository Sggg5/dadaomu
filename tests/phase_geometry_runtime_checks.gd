extends RefCounted
var test:SceneTree
const TOMB:TombDefinition=preload("res://data/tombs/default_tomb.tres")
const POOL:RoomGeometryPool=preload("res://data/geometries/ordinary_pool.tres")
const ARENAS:BossArenaPool=preload("res://data/geometries/arenas/boss_pool.tres")
func _init(context:SceneTree)->void:test=context
func setup()->DungeonSession:
	var session:=preload("res://scenes/main/dungeon_test.tscn").instantiate() as DungeonSession
	session.seed_value=33
	test.root.add_child(session)
	test.session=session
	test.current_scene=session
	await test.frames(3)
	return session
func check_actors(room:Room)->void:
	for actor in CombatGeometry.targets(room):
		var point:=room.to_local(actor.global_position)
		test.check(room.obstacles().all(func(rect:Rect2)->bool:return not rect.grow(18).has_point(point)),"Actual instantiated actor cannot spawn inside padded wall")
func boss_arena(definition:BossDefinition,geometry:RoomGeometryDefinition)->void:
	var session:=await setup()
	var world:=session.world
	world.boss_definition=definition
	world.boss_arena_override=geometry as BossArenaDefinition
	var template:=world.layout.rooms[world.layout.boss_id].definition.duplicate() as RoomDefinition
	template.obstacles=[Rect2(604,312,72,112)] # poison Encounter must never leak into Arena
	world.layout.rooms[world.layout.boss_id].definition=template
	world._switch_room(world.layout.boss_id,-1)
	await test.frames(3)
	var room:=world.current_room
	test.check(room.geometry==geometry and room.obstacles()==geometry.obstacles,"Boss geometry independent from poisoned ordinary Encounter")
	check_actors(room)
	var boss:=room.boss_encounter.boss
	var obstructed:=geometry.obstacles[0].get_center() if not geometry.obstacles.is_empty() else Vector2(640,368)
	if boss is MechanismBoss:
		var zone:BossTelegraph=(boss as MechanismBoss).zone(BossTelegraph.Shape.CIRCLE,room.to_global(obstructed),42,0.8,4)
		var center:=room.to_local(zone.global_position)
		test.check(room.obstacles().all(func(rect:Rect2)->bool:return not rect.grow(24).has_point(center)),"Actual ground danger zone relocates illegal Arena origin")
	if definition.id==&"paper_general":
		var fake:=PaperDecoy.new()
		fake.owner_boss=boss
		boss.add_child(fake)
		fake.global_position=room.to_global(obstructed)
		await test.frames(2)
		var center:=room.to_local(fake.global_position)
		test.check(room.obstacles().all(func(rect:Rect2)->bool:return not rect.grow(24).has_point(center)),"Moving decoy uses current Arena free space")
	room.boss_encounter._summon(4)
	room.boss_encounter.create_eggs(4)
	await test.frames(2)
	check_actors(room)
	# All timed ground targets share the same Room geometry query as spawn and pickup placement.
	for preferred in [Vector2(640,368),Vector2(420,260),Vector2(1040,480)]:
		var point:=EncounterGeometry.safe_point(room,preferred,70)
		test.check(point.is_finite() and room.obstacles().all(func(rect:Rect2)->bool:return not rect.grow(70).has_point(point)),"Boss warning/egg/landing query reads current Arena")
	test.capture(str(geometry.id)+"_"+str(definition.id))
	session.queue_free()
	await test.frames(3)
func run()->void:
	var translated:=await setup()
	var translated_room:=translated.world.current_room
	translated_room.position=Vector2(310,-180)
	translated_room.enemy_spawner.position=Vector2(17,11)
	translated_room.geometry=load("res://data/geometries/offset_coffin.tres")
	for rect in translated_room.obstacles():translated_room._add_block(translated_room.get_node("Walls"),rect)
	var wave:=RoomDefinition.new()
	var spawn:=EnemySpawnDefinition.new()
	spawn.enemy_scene=preload("res://scenes/enemies/scarab_enemy.tscn")
	spawn.enemy_definition=preload("res://data/enemies/scarab.tres")
	spawn.position=Vector2(392,300)
	wave.spawns.append(spawn)
	var expected:=EnemySpawnPlacement.build(wave,translated_room.geometry).positions[0]
	translated_room.enemy_spawner.spawn(wave)
	await test.frames(2)
	var actor:=translated_room.enemy_spawner.get_child(0) as Enemy
	var actual:=translated_room.to_local(actor.global_position)
	test.check(actual.is_equal_approx(expected),"Translated Room/Spawner preserve Room-local legal spawn")
	test.check(translated_room.obstacles().all(func(rect:Rect2)->bool:return not rect.grow(24).has_point(actual)),"Translated spawn keeps actual obstacle clearance")
	translated.queue_free()
	await test.frames(3)
	for entry:Variant in POOL.geometries:
		var geometry:=entry as RoomGeometryDefinition
		var session:=await setup()
		var world:=session.world
		var combat_id:StringName
		for id in world.layout.ordered_ids():
			if world.layout.rooms[id].room_type==RoomDefinition.Type.COMBAT and world.layout.rooms[id].neighbors.values().has(world.layout.start_id):combat_id=id;break
		world.geometry_plan.assigned[combat_id]=geometry
		world._switch_room(combat_id,-1)
		await test.frames(3)
		test.check(world.current_room.geometry==geometry and world.current_room.enemy_spawner.placement_error.is_empty(),"Actual combat room uses independent geometry: "+str(geometry.id))
		check_actors(world.current_room)
		test.capture(str(geometry.id))
		var driver=preload("res://tests/threat_fight_driver.gd").new(test)
		await driver.fight()
		test.check(world.current_room.doors.values().all(func(door:Door)->bool:return door.is_open),"Clearing varied geometry opens actual doors")
		await driver.visit(world.layout.start_id)
		test.check(world.current_id==world.layout.start_id,"Real Door works after varied-space battle")
		session.queue_free()
		await test.frames(3)
	for entry:Variant in ARENAS.geometries:
		var geometry:=entry as RoomGeometryDefinition
		var selected:BossDefinition
		for floor_number in range(1,6):
			for definition in TOMB.floor_at(floor_number).boss_pool.bosses:
				if geometry.tags.any(func(tag:StringName)->bool:return tag in definition.compatible_arena_tags):selected=definition;break
			if selected!=null:break
		await boss_arena(selected,geometry)
	await boss_arena(TOMB.floor_at(4).boss_pool.bosses[0],preload("res://data/geometries/arenas/boss_side_walls.tres"))
	await boss_arena(TOMB.floor_at(5).boss_pool.bosses[0],preload("res://data/geometries/arenas/boss_open.tres"))
	await boss_arena(TOMB.floor_at(5).boss_pool.bosses[1],preload("res://data/geometries/arenas/boss_edge_cover.tres"))
	var session:=await setup()
	var plan:=session.world.geometry_plan.signature()
	var boss:=BossArenaPlan.pick(session.run_seed,1,session.world.layout.boss_id,ARENAS,session.boss_for_floor(1)).id
	test.key(KEY_R)
	await test.frames(5)
	test.check(session.world.geometry_plan.signature()==plan and BossArenaPlan.pick(session.run_seed,1,session.world.layout.boss_id,ARENAS,session.boss_for_floor(1)).id==boss,"Real R repeats normal geometry and Boss Arena")
	test.key(KEY_N)
	await test.frames(5)
	test.check(session.world.geometry_plan.signature()!=plan,"Real N changes geometry plan")
	session.queue_free()
	await test.frames(3)
