extends RefCounted
var test: SceneTree
var completed: bool = false


func _init(context: SceneTree) -> void: test = context


func run() -> void:
	var arena = preload("res://tests/phase_6_5_boss_checks.gd").new(test)
	await arena.arena()
	var boss: TombGuardianBeast = arena.boss
	var player: Player = arena.player
	var room: Room = arena.room
	boss.stop_ai()
	var pool: RelicPool = RelicRewardService.LEGACY_POOL
	for data in pool.relics:
		player.relics.inventory.clear()
		room.discard_projectiles()
		await test.frames(3)
		boss.health.restore(1040)
		boss.position = Vector2(850,368)
		player.position = Vector2(640,368)
		player.relics.inventory.add(data)
		var rear_target: Enemy
		if data.id == &"ink_line":
			# 原规则排除直接命中对象；穿透后命中后方靶，墨线才自然回扫到Boss。
			for extra in pool.relics:
				if extra.id == &"tomb_nail": player.relics.inventory.add(extra)
			rear_target = BossEncounter.SCARAB.instantiate() as Enemy
			rear_target.configure_spawn(player,room.projectiles,BossEncounter.SCARAB_DATA,room.difficulty)
			rear_target.position = Vector2(1000,368)
			room.enemy_spawner.add_child(rear_target)
			rear_target.stop_ai()
		var warmups: int = 2 if data.id == &"copper_mirror" else (4 if data.id == &"luoyang_shovel" else 0)
		for index in range(warmups): player.relics.prepare_attack(AttackRequest.new())
		if data.id == &"spirit_kite": player.health.take_damage(1)
		player.weapon.cooldown_remaining = 0
		player.weapon.try_attack(player.position,Vector2.RIGHT,player.stats)
		await test.frames(85)
		test.check(boss.health.current_hp < 1040, "Formal relic naturally reaches beast through real attack: " + str(data.id))
		if data.id == &"black_powder": test.check(boss.health.current_hp <= 1010, "Powder explosion naturally includes beast target")
		if data.id == &"corpse_oil_lamp": test.check(boss.health.current_hp <= 1011, "Oil lamp naturally burns beast after actual hit")
		if data.id == &"ink_line": test.check(boss.health.current_hp <= 1014, "Ink line naturally damages beast through Room target set")
		if is_instance_valid(rear_target): rear_target.queue_free()
	player.relics.inventory.clear()
	for data in pool.relics: player.relics.inventory.add(data)
	room.discard_projectiles()
	await test.frames(3)
	boss.roar_direction = Vector2.RIGHT
	boss._roar()
	var bullets: Array = room.projectiles.get_children().filter(func(node: Node) -> bool: return node is EnemyProjectile)
	test.check(bullets.size() == 5 and bullets.all(func(node: EnemyProjectile) -> bool: return is_equal_approx(node.damage,18.9) and node.velocity.length() == 320 and node.pierce_remaining == 0 and node.tags.is_empty()), "All eight Player relics never modify beast EnemyProjectile")
	completed = true
