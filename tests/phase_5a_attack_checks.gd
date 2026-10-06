extends RefCounted
## 快照、组合与真实弹丸碰撞；暂时停 AI 是为了隔离攻击管线。
const DAMAGE: RelicDefinition = preload("res://data/relics/test_damage_relic.tres")
const DOUBLE: RelicDefinition = preload("res://data/relics/test_double_shot.tres")
const HEAL: RelicDefinition = preload("res://data/relics/test_kill_heal.tres")
const SCARAB: PackedScene = preload("res://scenes/enemies/scarab_enemy.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
var test: SceneTree
var completed: bool = false


func _init(context: SceneTree) -> void:
	test = context


func base_request(player: Player) -> AttackRequest:
	var request := AttackRequest.new()
	request.origin = Vector2(640, 368)
	request.direction = Vector2.RIGHT
	request.damage = player.stats.attack_damage
	request.speed = player.stats.projectile_speed
	request.lifetime = player.stats.projectile_lifetime
	return request


func shots_to_kill(player: Player, world: RoomController, capture_name: String) -> int:
	var enemy := SCARAB.instantiate() as Enemy
	enemy.position = Vector2(850, 368)
	enemy.configure_spawn(player, world.current_room.projectiles)
	world.current_room.enemy_spawner.add_child(enemy)
	enemy.stop_ai()
	player.position = Vector2(640, 368)
	var count: int = 0
	for attempt in range(5):
		if not is_instance_valid(enemy) or enemy.health.is_dead:
			break
		player.weapon.cooldown_remaining = 0.0
		player.weapon.try_attack(player.position, Vector2.RIGHT, player.stats)
		count += 1
		await test.frames(4)
		if attempt == 0:
			test.capture(capture_name)
		await test.frames(18)
	if is_instance_valid(enemy):
		enemy.queue_free()
	await test.frames(2)
	return count


func run() -> void:
	var world: RoomController = test.session.world
	var player := world.player
	var runtime := player.relics
	var inventory := runtime.inventory
	var original_damage := player.stats.attack_damage
	var request := base_request(player)
	var output := runtime.prepare_attack(request)
	test.check(output.size() == 1 and output[0].damage == original_damage and output[0].direction == request.direction and output[0].speed == request.speed, "No relic keeps Phase 4 single attack values")
	test.check(DAMAGE.id == &"test_damage_relic" and DOUBLE.display_name == "双生铜钱" and HEAL.effect_script != null, "Three read-only relic definitions load")
	test.check(inventory.add(DAMAGE) and inventory.has(DAMAGE.id), "Inventory adds and queries unique relic")
	var effect := inventory.get_effect(DAMAGE.id)
	test.check(not inventory.add(DAMAGE) and not effect.install(runtime, DAMAGE) and effect.install_count == 1, "Duplicate obtain and install rejected without stacking")
	output = runtime.prepare_attack(request)
	test.check(output[0].damage == original_damage * 1.5 and request.damage == original_damage, "Damage relic multiplies snapshot by 1.5 only")
	test.check(inventory.remove(DAMAGE.id) and not inventory.remove(DAMAGE.id) and not effect.uninstall() and effect.uninstall_count == 1, "Remove and uninstall execute exactly once")
	test.check(runtime.prepare_attack(request)[0].damage == original_damage and player.stats.attack_damage == original_damage, "Removal restores damage without mutating PlayerStats")
	var normal_shots := await shots_to_kill(player, world, "baseline_single")
	inventory.add(DAMAGE)
	var boosted_shots := await shots_to_kill(player, world, "damage_only")
	test.check(normal_shots == 4 and boosted_shots == 3, "Damage relic reduces real scarab kill from four shots to three")
	inventory.clear()
	test.check(inventory.add(DOUBLE), "Double shot installs")
	output = runtime.prepare_attack(request)
	test.check(output.size() == 2 and output[0].direction != output[1].direction and is_equal_approx(output[0].direction.length(), 1.0), "One attack expands into two distinct normalized directions")
	var spawned: Array[Projectile] = []
	var collect := func(projectile: Projectile) -> void: spawned.append(projectile)
	runtime.projectile_spawned.connect(collect)
	player.weapon.cooldown_remaining = 0.0
	test.check(player.weapon.try_attack(request.origin, request.direction, player.stats) and spawned.size() == 2, "Actual weapon emits two room-owned projectiles for one input")
	test.check(not player.weapon.try_attack(request.origin, request.direction, player.stats) and spawned.size() == 2, "Double shot still uses one weapon cooldown")
	await test.frames(4)
	test.capture("double_shot")
	world.current_room.discard_projectiles()
	await test.frames(2)
	test.check(inventory.remove(DOUBLE.id) and runtime.prepare_attack(request).size() == 1, "Removing double shot restores single request")
	inventory.add(DAMAGE)
	inventory.add(DOUBLE)
	var forward := runtime.prepare_attack(request)
	inventory.clear()
	inventory.add(DOUBLE)
	inventory.add(DAMAGE)
	var reverse := runtime.prepare_attack(request)
	test.check(forward.size() == 2 and reverse.size() == 2 and forward[0].damage == original_damage * 1.5 and reverse[1].damage == original_damage * 1.5 and forward[0].direction == reverse[0].direction, "Combined damage and double shot are independent of obtain order")
	test.check(DAMAGE.parameters["multiplier"] == 1.5 and DOUBLE.parameters["spread_degrees"] == 6.0 and player.stats.attack_damage == original_damage, "Definitions and initial stats remain read-only")
	var hits: Array[ProjectileHitContext] = []
	var on_hit := func(context: ProjectileHitContext) -> void: hits.append(context)
	runtime.projectile_hit.connect(on_hit)
	# 分离两条轨迹靶点，让两枚真实弹丸各自命中独立敌人。
	var enemies: Array[Enemy] = []
	for modified in reverse:
		var enemy := SCARAB.instantiate() as Enemy
		enemy.position = request.origin + modified.direction * 210.0
		enemy.configure_spawn(player, world.current_room.projectiles)
		world.current_room.enemy_spawner.add_child(enemy)
		enemy.stop_ai()
		enemies.append(enemy)
	spawned.clear()
	player.weapon.cooldown_remaining = 0.0
	player.weapon.try_attack(request.origin, request.direction, player.stats)
	await test.frames(24)
	test.check(hits.size() == 2 and enemies.all(func(enemy: Enemy) -> bool: return enemy.health.current_hp == enemy.definition.max_hp - original_damage * 1.5), "Both combined projectiles collide and each issue one hit context")
	test.check(hits.all(func(context: ProjectileHitContext) -> bool: return context.target is Enemy and context.damage == original_damage * 1.5), "Hit context carries actual target and snapshot damage")
	test.check(world.current_room.projectiles.get_child_count() == 0, "Consumed dual bullets leave no projectile residue")
	test.capture("combined_hit")
	for enemy in enemies:
		enemy.queue_free()
	await test.frames(2)
	inventory.clear()
	spawned.clear()
	player.weapon.cooldown_remaining = 0.0
	player.weapon.try_attack(request.origin, request.direction, player.stats)
	test.check(spawned.size() == 1 and spawned[0].damage == original_damage, "Uninstalled build restores actual single projectile damage")
	world.current_room.discard_projectiles()
	await test.frames(2)
	runtime.projectile_spawned.disconnect(collect)
	runtime.projectile_hit.disconnect(on_hit)
	# 暂时持有旧实例检查 uninstall 后的连接和触发次数，不依赖垃圾回收。
	var base_connections := runtime.enemy_killed.get_connections().size()
	var marker := Node2D.new()
	world.current_room.add_child(marker)
	for cycle in range(5):
		player.health.take_damage(10.0)
		inventory.add(HEAL)
		var heal_effect := inventory.get_effect(HEAL.id)
		test.check(runtime.enemy_killed.get_connections().size() == base_connections + 1 and heal_effect.install_count == 1, "Heal installs exactly one signal connection cycle %d" % cycle)
		var hp := player.health.current_hp
		runtime.notify_enemy_killed(marker)
		test.check(player.health.current_hp == hp + 5.0 and heal_effect.get("triggers") == 1, "One local kill Hook produces one heal cycle %d" % cycle)
		inventory.remove(HEAL.id)
		test.check(runtime.enemy_killed.get_connections().size() == base_connections and heal_effect.uninstall_count == 1, "Heal removes all its connections cycle %d" % cycle)
		hp = player.health.current_hp
		runtime.notify_enemy_killed(marker)
		test.check(player.health.current_hp == hp and heal_effect.get("triggers") == 1, "Removed effect never responds to subsequent Hook cycle %d" % cycle)
		player.health.heal(100.0)
	marker.queue_free()
	inventory.add(HEAL)
	test.check(inventory.get_effect(HEAL.id).get("triggers") == 0, "New effect has independent fresh runtime state")
	inventory.clear()
	var independent := PLAYER_SCENE.instantiate() as Player
	world.current_room.add_child(independent)
	independent.position = Vector2(400, 368)
	inventory.add(DAMAGE)
	test.check(independent.stats == player.stats and independent.relics.inventory != inventory and independent.relics.prepare_attack(request)[0].damage == original_damage and runtime.prepare_attack(request)[0].damage == original_damage * 1.5, "Separate Player runtime shares read-only stats but never shares Build state")
	inventory.clear()
	independent.queue_free()
	await test.frames(2)
	completed = true
