extends RefCounted
## 实际地宫清房/过门/重开：Build 属于唯一 Player，不属于 Room。
const DAMAGE: RelicDefinition = preload("res://data/relics/test_damage_relic.tres")
const DOUBLE: RelicDefinition = preload("res://data/relics/test_double_shot.tres")
const HEAL: RelicDefinition = preload("res://data/relics/test_kill_heal.tres")
var test: SceneTree
var completed: bool = false


func _init(context: SceneTree) -> void:
	test = context


func count_players(node: Node) -> int:
	var result: int = int(node is Player)
	for child in node.get_children():
		result += count_players(child)
	return result


func run() -> void:
	var world: RoomController = test.session.world
	var player := world.player
	var runtime := player.relics
	var inventory := runtime.inventory
	var player_id := player.get_instance_id()
	# 用真实开发期键位添加，不直接模拟效果结果。
	test.key(KEY_1)
	test.key(KEY_2)
	test.key(KEY_3)
	await test.frames(1)
	test.check(inventory.ids().size() == 3 and world.get_node("RelicDebugPanel").label.text.contains("双生铜钱"), "Debug keys install three relics and panel shows current inventory")
	var effects: Array[RelicEffect] = []
	for id in inventory.ids():
		effects.append(inventory.get_effect(id))
	var killed := [0]
	var damaged := [0]
	var cleared := [0]
	runtime.enemy_killed.connect(func(_enemy: Node2D) -> void: killed[0] += 1)
	runtime.player_damaged.connect(func(_amount: float) -> void: damaged[0] += 1)
	runtime.room_cleared.connect(func(_context: RoomClearContext) -> void: cleared[0] += 1)
	player.health.take_damage(25.0)
	test.check(damaged[0] == 1 and player.health.current_hp == 75.0, "Nonlethal player damage reaches local Hook exactly once")
	var start_side: int = world.layout.rooms[world.current_id].neighbors.keys()[0]
	await test.walk(start_side)
	var room := world.current_room
	var combat_id := world.current_id
	test.check(room.room_type == RoomDefinition.Type.COMBAT and inventory.ids().size() == 3 and player.get_instance_id() == player_id and effects.all(func(effect: RelicEffect) -> bool: return effect.install_count == 1), "Build crosses actual Door without reinstalling or recreating Player")
	# 生命周期测试冻结敌人移动；Phase 4 独立回归验证活跃 AI 与红弹。
	room.enemy_spawner.stop_all()
	var first := room.enemy_spawner.get_child(0) as Enemy
	var first_id := first.get_instance_id()
	player.position = first.position + Vector2(0, 64)
	player.weapon.cooldown_remaining = 0.0
	player.weapon.try_attack(player.position, Vector2.UP, player.stats)
	await test.frames(14)
	if is_instance_valid(first) and not first.health.is_dead:
		player.weapon.try_attack(player.position, Vector2.UP, player.stats)
		await test.frames(14)
	test.check((not is_instance_valid(first) or first.health.is_dead) and killed[0] == 1 and player.health.current_hp == 80.0, "Real combined bullets kill scarab and heal five HP once")
	var heal_effect := inventory.get_effect(HEAL.id)
	room.enemy_spawner._on_enemy_died(first_id)
	test.check(heal_effect.get("triggers") == 1 and killed[0] == 1, "Repeated death callback cannot repeat killed Hook or heal")
	player.health.heal(1000.0)
	var second := room.enemy_spawner.get_child(1) as Enemy
	second.take_damage(1000.0)
	test.check(player.health.current_hp == player.health.max_hp and killed[0] == 2, "Kill heal clamps at max HP")
	for enemy in room.enemy_spawner.get_children():
		if not enemy.health.is_dead:
			enemy.take_damage(1000.0)
	await test.frames(14)
	test.check(room.room_state.status == RoomState.Status.CLEARED and cleared[0] == 1 and inventory.ids().size() == 3, "Room clears once and Build remains installed")
	room.enter()
	test.check(cleared[0] == 1, "Repeated enter never repeats room-cleared Hook")
	await test.walk(Door.opposite(start_side))
	test.check(world.current_id == &"START" and inventory == player.relics.inventory and count_players(test.root) == 1, "Room unload preserves inventory and unique Player")
	await test.walk(start_side)
	test.check(world.current_id == combat_id and world.current_room.enemy_spawner.get_remaining() == 0 and effects.all(func(effect: RelicEffect) -> bool: return effect.install_count == 1), "Revisit CLEARED never reinstalls effects")
	player.position = Vector2(640, 368)
	player.weapon.cooldown_remaining = 0.0
	player.weapon.try_attack(player.position, Vector2.RIGHT, player.stats)
	test.check(world.current_room.projectiles.get_child_count() == 2 and world.current_room.projectiles.get_children().all(func(projectile: Projectile) -> bool: return projectile.damage == player.stats.attack_damage * 1.5), "Combined Build still changes real attacks after clear and revisit")
	await test.frames(4)
	test.capture("build_after_traversal")
	test.key(KEY_BACKSPACE)
	test.check(inventory.ids().is_empty() and effects.all(func(effect: RelicEffect) -> bool: return effect.uninstall_count == 1), "Debug removal uninstalls all effects exactly once")
	world.current_room.discard_projectiles()
	await test.frames(2)
	player.weapon.cooldown_remaining = 0.0
	player.weapon.try_attack(player.position, Vector2.RIGHT, player.stats)
	test.check(world.current_room.projectiles.get_child_count() == 1 and world.current_room.projectiles.get_child(0).damage == player.stats.attack_damage, "Actual attacks restore ordinary single shot after debug removal")
	await test.frames(4)
	test.capture("removed_single")
	inventory.add(DAMAGE)
	inventory.add(HEAL)
	var old_effect := inventory.get_effect(HEAL.id)
	var signature := world.layout.signature()
	test.key(KEY_R)
	await test.frames(5)
	world = test.session.world
	test.check(world.layout.signature() == signature and world.player.relics.inventory.ids().is_empty() and old_effect.uninstall_count == 1 and not is_instance_valid(player), "R reproduces Seed and removes old effects with fresh empty inventory")
	player = world.player
	runtime = player.relics
	inventory = runtime.inventory
	inventory.add(HEAL)
	inventory.add(DOUBLE)
	old_effect = inventory.get_effect(HEAL.id)
	var before_seed: int = test.session.seed_value
	test.session._seed_rng.seed = 20261006
	test.key(KEY_N)
	await test.frames(5)
	world = test.session.world
	test.check(test.session.seed_value != before_seed and world.player.relics.inventory.ids().is_empty() and old_effect.uninstall_count == 1 and count_players(test.root) == 1, "N creates new Seed and clean Build with one Player")
	player = world.player
	runtime = player.relics
	inventory = runtime.inventory
	inventory.add(HEAL)
	inventory.add(DAMAGE)
	old_effect = inventory.get_effect(HEAL.id)
	start_side = world.layout.rooms[world.current_id].neighbors.keys()[0]
	await test.walk(start_side)
	var enemy := world.current_room.enemy_spawner.get_child(0) as Enemy
	var hit_count := [0]
	runtime.projectile_hit.connect(func(_context: ProjectileHitContext) -> void: hit_count[0] += 1)
	player.health.take_damage(1000.0)
	var triggers_before: int = old_effect.get("triggers")
	enemy.take_damage(1000.0)
	await test.frames(14)
	test.check(inventory.ids().is_empty() and old_effect.uninstall_count == 1 and not runtime.is_active() and player.health.current_hp == 0.0 and not player.health.heal(5.0), "Death clears all relics and cannot revive dead Player")
	test.check(old_effect.get("triggers") == triggers_before and runtime.enemy_killed.get_connections().is_empty() and hit_count[0] == 0, "Post-death kills cannot trigger stale heal connections or hits")
	test.check(not inventory.add(DAMAGE) and world.current_room.projectiles.get_child_count() == 0 and world.current_room.enemy_spawner.get_children().all(func(actor: Enemy) -> bool: return not actor.ai_enabled), "Dead runtime rejects new installs and keeps Phase 4 death cleanup")
	test.capture("death_empty")
	completed = true
