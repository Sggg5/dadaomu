extends RefCounted
var test: SceneTree
func _init(context: SceneTree) -> void:test=context
func run() -> void:
	var session := preload("res://scenes/main/dungeon_test.tscn").instantiate() as DungeonSession
	session.seed_value=33
	test.root.add_child(session)
	test.session=session
	test.current_scene=session
	await test.frames(3)
	var ids: Array[StringName]=[&"five_emperor_coins",&"black_powder",&"tomb_nail",&"copper_mirror",&"chain_spring",&"iron_caltrop",&"bagua_mirror",&"red_rope",&"cinnabar_seal",&"powder_packet",&"bronze_arrowhead",&"seven_nails"]
	for count in [5,8,12]:
		session.world.player.relics.inventory.clear()
		for index in range(count):
			for data: Variant in RelicRewardService.PRODUCTION_POOL.relics:
				if data.id==ids[index]:test.check(session.world.player.relics.inventory.add(data),"Independent effect installs")
		var peak := 0
		for attack in range(30):
			var request := AttackRequest.new()
			request.origin=session.world.player.position
			request.direction=Vector2.RIGHT
			request.damage=20
			request.speed=600
			request.lifetime=1.5
			var requests := session.world.player.relics.prepare_attack(request)
			peak=maxi(peak,requests.size())
			test.check(requests.size()>1 and requests.size()<=48 and requests.all(func(item:AttackRequest)->bool:return is_finite(item.damage) and item.damage>0 and item.direction.is_normalized() and item.speed>0),"5/8/12-item attack stays valid and bounded")
			if attack==29:
				for item in requests: session.world.player.weapon.attack_requested.emit(item)
		await test.frames(10)
		test.capture("build_%d" % count)
		print("[9B.2 build] items=%d peak_projectiles=%d live=%d" % [count,peak,session.world.current_room.projectiles.get_child_count()])
		session.world.current_room.discard_projectiles()
		await test.frames(2)
	session.world.player.relics.inventory.clear()
	for data: Variant in RelicRewardService.PRODUCTION_POOL.relics: session.world.player.relics.inventory.add(data)
	var world:=session.world
	world._switch_room(world.layout.rooms[world.layout.start_id].neighbors.values()[0],-1)
	# 当前房可安全，单项装配一个耐久靶，不以此替代完整实战流程。
	var enemy:=preload("res://scenes/enemies/scarab_enemy.tscn").instantiate() as Enemy
	var data:=preload("res://data/enemies/scarab.tres").duplicate() as EnemyDefinition
	data.max_hp=2000
	enemy.configure_spawn(world.player,world.current_room.projectiles,data)
	enemy.position=Vector2(480,304)
	world.current_room.enemy_spawner.add_child(enemy)
	enemy.stop_ai()
	world.player.position=Vector2(480,496)
	for attack in range(12):
		world.player.weapon.try_attack(world.player.position,Vector2.UP,world.player.stats)
		await test.frames(12)
	test.check(enemy.health.current_hp<2000 and world.current_room.projectiles.get_child_count()<=256,"Twenty-item actual projectile hits stay bounded without recursive explosion")
	var burns:=0
	for node in enemy.get_children():
		if node is Burn: burns+=1
	test.check(burns<=2,"Two independent burn effects have at most two bounded DOT nodes per target")
	var hp:=enemy.health.current_hp
	world.player.relics.inventory.clear()
	world.current_room.discard_projectiles()
	await test.frames(120)
	test.check(enemy.health.current_hp==hp,"Uninstall cancels pending burns and no secondary damage recurs")
	session.queue_free()
	await test.frames(3)
