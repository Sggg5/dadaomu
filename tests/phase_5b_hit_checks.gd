extends RefCounted
const SCARAB: PackedScene = preload("res://scenes/enemies/scarab_enemy.tscn")
const ENEMY_BULLET: PackedScene = preload("res://scenes/enemies/enemy_projectile.tscn")
var test: SceneTree
var completed: bool = false
var pool: RelicPool = RelicRewardService.DEFAULT_POOL


func _init(context: SceneTree) -> void:
	test = context


func definition(id: StringName) -> RelicDefinition:
	for item in pool.relics:
		if item.id == id:
			return item
	return null


func enemy(position: Vector2) -> Enemy:
	var world: RoomController = test.session.world
	var actor := SCARAB.instantiate() as Enemy
	actor.position = position
	actor.configure_spawn(world.player, world.current_room.projectiles)
	world.current_room.enemy_spawner.add_child(actor)
	actor.health.initialize(200.0)
	actor.stop_ai()
	return actor


func fire(origin: Vector2 = Vector2(640, 368), direction: Vector2 = Vector2.RIGHT) -> Projectile:
	var world: RoomController = test.session.world
	world.player.position = origin
	world.player.weapon.cooldown_remaining = 0.0
	world.player.weapon.try_attack(origin, direction, world.player.stats)
	for child in world.current_room.projectiles.get_children():
		if child is Projectile and not child is EnemyProjectile:
			return child
	return null


func until_hit(actor: Enemy) -> void:
	for frame in range(80):
		if actor.health.current_hp < 200.0:
			return
		await test.frames(1)


func clean() -> void:
	var world: RoomController = test.session.world
	world.player.relics.inventory.clear()
	for actor in world.current_room.enemy_spawner.get_children():
		actor.queue_free()
	world.current_room.discard_projectiles()
	await test.frames(3)


func run() -> void:
	var world: RoomController = test.session.world
	var runtime := world.player.relics
	var inventory := runtime.inventory
	inventory.add(definition(&"black_powder"))
	var a := enemy(Vector2(850, 368))
	var b := enemy(Vector2(880, 400))
	var far := enemy(Vector2(1060, 500))
	var powder := inventory.get_effect(&"black_powder")
	var hits := [0]
	var collect := func(_context: ProjectileHitContext) -> void: hits[0] += 1
	runtime.projectile_hit.connect(collect)
	fire()
	await until_hit(a)
	test.check(a.health.current_hp == 170.0 and b.health.current_hp == 190.0 and far.health.current_hp == 200.0, "Black powder burst damages original and nearby targets only")
	test.check(powder.get("explosions") == 1 and hits[0] == 1, "Explosion damage never recursively emits projectile hit")
	test.capture("explosion")
	await clean()
	inventory.add(definition(&"tomb_nail"))
	inventory.add(definition(&"black_powder"))
	a = enemy(Vector2(850, 368))
	b = enemy(Vector2(950, 368))
	far = enemy(Vector2(1050, 368))
	powder = inventory.get_effect(&"black_powder")
	var bullet := fire()
	await test.frames(48)
	test.check(a.health.current_hp == 170.0 and b.health.current_hp == 170.0 and far.health.current_hp == 200.0 and not is_instance_valid(bullet), "Nail pierces exactly one enemy and consumes at second")
	test.check(powder.get("explosions") == 2 and hits[0] == 3, "Natural nail plus powder synergy produces two independent explosions from one projectile")
	test.capture("piercing_explosions")
	await test.frames(12)
	test.check(a.health.current_hp == 170.0 and b.health.current_hp == 170.0, "Piercing projectile never repeatedly hurts the same target")
	await clean()
	inventory.add(definition(&"tomb_nail"))
	bullet = fire(Vector2(1180, 500))
	await test.frames(12)
	test.check(not is_instance_valid(bullet), "Piercing projectile is still consumed immediately by wall")
	await clean()
	inventory.add(definition(&"ink_line"))
	a = enemy(Vector2(850, 368))
	b = enemy(Vector2(750, 378))
	far = enemy(Vector2(750, 410))
	# 墨线附近的靶子停用实体碰撞，以隔离瞬时线段伤害而不截断原弹丸。
	b.get_node("CollisionShape2D").set_deferred("disabled", true)
	await test.frames(2)
	fire()
	await until_hit(a)
	test.check(a.health.current_hp == 180.0 and b.health.current_hp == 194.0 and far.health.current_hp == 200.0, "Ink sweep deals six once to other targets inside a 24 pixel segment width")
	test.check(inventory.get_effect(&"ink_line").get("sweeps") == 1, "One hit produces one ink sweep")
	test.capture("ink_line")
	await test.frames(8)
	test.check(b.health.current_hp == 194.0, "Ink visual never reapplies line damage per frame")
	await clean()
	inventory.add(definition(&"five_emperor_coins"))
	inventory.add(definition(&"copper_mirror"))
	for index in range(3):
		fire()
		await test.frames(4)
		if index == 2:
			test.check(world.current_room.projectiles.get_children().filter(func(node: Node) -> bool: return node is Projectile).size() == 6, "Coins and mirror third attack spawns six actual projectiles")
			test.capture("mirror_six")
		world.current_room.discard_projectiles()
		await test.frames(2)
	await clean()
	inventory.add(definition(&"luoyang_shovel"))
	for index in range(5):
		fire()
		await test.frames(2)
		if index == 4:
			var heavy: Projectile
			for node in world.current_room.projectiles.get_children():
				if node is Projectile and node.tags.has(&"heavy"): heavy = node
			test.check(heavy != null and heavy.scale == Vector2.ONE * 1.8 and heavy.damage == 44.0, "Shovel generates a visibly larger physical projectile")
			test.capture("heavy_wind")
			await test.frames(16)
			test.check(not is_instance_valid(heavy), "Short heavy wind expires within 0.22 seconds")
		world.current_room.discard_projectiles()
		await test.frames(2)
	await clean()
	var burns = load("res://tests/phase_5b_burn_checks.gd").new(test, self)
	await burns.run()
	test.check(burns.completed, "Burn and propagation suite completes")
	await clean()
	for item in pool.relics:
		inventory.add(item)
	fire()
	await test.frames(3)
	test.check(world.current_room.projectiles.get_children().filter(func(node: Node) -> bool: return node is Projectile).size() == 2, "All eight formal relics coexist and still execute actual weapon attacks")
	world.current_room.discard_projectiles()
	await test.frames(2)
	world.player.invulnerability_remaining = 0.0
	world.player.position = Vector2(640, 368)
	var request := AttackRequest.new()
	request.origin = Vector2(540, 368)
	request.direction = Vector2.RIGHT
	request.damage = 12.0
	request.speed = 280.0
	request.lifetime = 3.0
	var hostile := ENEMY_BULLET.instantiate() as EnemyProjectile
	world.current_room.projectiles.add_child(hostile)
	hostile.setup(request)
	hostile.track_player(world.player)
	var before: int = hits[0]
	await test.frames(30)
	test.check(world.player.health.current_hp == 68.0 and not is_instance_valid(hostile) and hits[0] == before, "EnemyProjectile ignores all formal attack modifiers and hit effects")
	inventory.clear()
	test.check(runtime.projectile_hit.get_connections().size() == 1 and runtime.player_damaged.get_connections().is_empty(), "Unloading all formal effects leaves no ghost hit or damage connections")
	inventory.add(definition(&"corpse_oil_lamp"))
	a = enemy(Vector2(850, 368))
	fire()
	await until_hit(a)
	var hp := a.health.current_hp
	world.player.health.take_damage(1000.0)
	await test.frames(66)
	test.check(a.health.current_hp == hp and a.get_children().filter(func(node: Node) -> bool: return node is Burn).is_empty() and inventory.ids().is_empty() and not test.session.rewards.active, "Player death cancels ongoing Burn and reward activity without late damage")
	runtime.projectile_hit.disconnect(collect)
	completed = true
