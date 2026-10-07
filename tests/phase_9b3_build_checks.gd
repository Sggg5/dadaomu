extends RefCounted
var test:SceneTree
func _init(context:SceneTree)->void:test=context
func run()->void:
	var session:=preload("res://scenes/main/dungeon_test.tscn").instantiate() as DungeonSession
	session.seed_value=33
	test.root.add_child(session)
	test.session=session
	test.current_scene=session
	await test.frames(3)
	var player:=session.world.player
	var room:=session.world.current_room
	var request:=AttackRequest.new()
	request.origin=Vector2(480,496)
	request.direction=Vector2.UP
	request.damage=20
	request.speed=600
	request.lifetime=2
	var dummy:=preload("res://scenes/enemies/scarab_enemy.tscn").instantiate() as Enemy
	var data:=preload("res://data/enemies/scarab.tres").duplicate() as EnemyDefinition
	data.max_hp=100000
	dummy.configure_spawn(player,room.projectiles,data)
	dummy.encounter_room=room
	dummy.position=Vector2(480,304)
	room.enemy_spawner.add_child(dummy)
	dummy.stop_ai()
	player.position=request.origin
	for definition:Variant in RelicRewardService.PRODUCTION_POOL.relics:
		player.relics.inventory.clear()
		test.check(player.relics.inventory.add(definition),"Every independent relic effect installs: "+str(definition.id))
		for repeat in range(8):
			var prepared:=player.relics.prepare_attack(request)
			test.check(not prepared.is_empty() and prepared.size()<=48 and prepared.all(func(r:AttackRequest)->bool:return r.damage>0 and r.speed>0 and is_finite(r.damage)),"Every relic has valid attack contract")
			for shot in prepared:player.weapon.attack_requested.emit(shot)
			var context:=ProjectileHitContext.new()
			context.target=dummy
			context.position=dummy.position
			context.damage=20
			context.hit_count=2
			context.direction=Vector2.UP
			player.relics.projectile_hit.emit(context)
		await test.frames(4)
		player.relics.notify_enemy_killed(dummy)
		player.relics.notify_room_cleared(RoomClearContext.new())
		player.relics.player_damaged.emit(1)
		player.relics.inventory.clear()
		room.discard_projectiles()
		await test.frames(3)
		test.check(dummy.movement_modifiers.is_empty(),"Uninstall cancels target movement effects")
	for seed_value in [3,18,33,77]:
		var plan:=RelicRewardPlan.build(seed_value,5,RelicRewardService.PRODUCTION_POOL)
		for count in [5,8,12,13]:
			player.relics.inventory.clear()
			var index:=0
			for source in plan.assigned:
				if index<count:player.relics.inventory.add(plan.assigned[source])
				index+=1
			for attack in range(30):
				var prepared:=player.relics.prepare_attack(request)
				test.check(prepared.size()>0 and prepared.size()<=48,"Varied 5/8/12/13 relic plans stay bounded")
				for shot in prepared:player.weapon.attack_requested.emit(shot)
				await test.frames(2)
				test.check(room.projectiles.get_child_count()<=256,"Combined projectiles obey room limit")
			player.relics.inventory.clear()
			room.discard_projectiles()
			await test.frames(3)
	var original:=session.rewards.plan.signature()
	var snapshot:=session.rewards.plan.assigned[&"F5:BOSS"].id
	var options:=session.rewards.plan.choices(&"F1:ITEM")
	test.check(options.size()==1 and session.rewards.plan.assigned[&"F5:BOSS"].id==snapshot,"Skipped source or options lookup never consumes another reward")
	test.key(KEY_R)
	await test.frames(5)
	test.check(session.rewards.plan.signature()==original and session.world.player.relics.inventory.ids().is_empty(),"Real R reproduces profiled plan and resets Build")
	test.key(KEY_N)
	await test.frames(5)
	test.check(session.rewards.plan.signature()!=original and session.world.player.relics.inventory.ids().is_empty(),"Real N rebuilds varied plan with empty Build")
	player=session.world.player
	room=session.world.current_room
	# Defense only consumes on an eligible hit; the Player invulnerability gate remains first.
	player.relics.inventory.add(load("res://data/relics/ward_coin.tres"))
	player.relics.notify_room_cleared(RoomClearContext.new())
	var before:=player.health.current_hp
	player.take_damage(10)
	test.check(is_equal_approx(before-player.health.current_hp,6.5),"Clear-charge defense reduces one valid hit without healing")
	before=player.health.current_hp
	player.take_damage(10)
	test.check(player.health.current_hp==before,"Repeated damage remains blocked during invulnerability")
	session.queue_free()
	await test.frames(3)
