extends RefCounted
## 不用 inventory.add 模拟完整奖励局：活跃 AI、真实 Weapon/Door/E 底座。
var test: SceneTree
var completed: bool = false
var picked: Array[StringName] = []
var pool: RelicPool = RelicRewardService.DEFAULT_POOL


func _init(context: SceneTree) -> void:
	test = context


func player_count(node: Node) -> int:
	var total: int = int(node is Player)
	for child in node.get_children():
		total += player_count(child)
	return total


func reward_signature(service: RelicRewardService) -> String:
	return ",".join(service.sequence.map(func(item: RelicDefinition) -> String: return str(item.id)))


func claim() -> void:
	var world: RoomController = test.session.world
	var pedestal := world.current_room.get_node_or_null("RelicPedestal") as RelicPedestal
	if pedestal == null:
		return
	var before := world.player.relics.inventory.ids().size()
	world.player.position = pedestal.global_position + Vector2(24, 0)
	world.player.velocity = Vector2.ZERO
	await test.frames(1)
	test.check(pedestal.label.text.contains("[E]") and pedestal.can_pickup(), "Reward pedestal shows name/description/E within reach")
	test.capture("reward_%d" % (picked.size() + 1))
	var id := pedestal.definition.id
	test.key(KEY_E)
	test.check(pedestal.claimed and not pedestal.try_pickup() and world.player.relics.inventory.has(id) and world.player.relics.inventory.ids().size() == before + 1, "Real interact input picks one formal relic exactly once")
	picked.append(id)
	await test.frames(2)
	test.check(not is_instance_valid(pedestal), "Claimed pedestal releases from Room")
	print("[Run] clear %d -> %s" % [test.session.rewards.combat_clears, id])


func fight() -> void:
	var world: RoomController = test.session.world
	if world.current_room.room_state.status != RoomState.Status.ACTIVE:
		return
	var original := world.current_room.enemy_spawner.get_children()
	test.check(original.all(func(enemy: Enemy) -> bool: return is_equal_approx(enemy.health.max_hp, enemy.definition.max_hp * world.current_room.difficulty.hp_multiplier)) and world.current_room.difficulty.depth == world.layout.rooms[world.current_id].distance_from_start + world.floor_offset, "Controller injects actual layout depth into live enemy HP")
	for enemy in original:
		for attempt in range(32):
			if not is_instance_valid(enemy) or enemy.health.is_dead or world.player.health.is_dead:
				break
			# 测试驾驶主动选更安全的射击点，不靠加血/停AI通过更高致死性。
			var safest := world.player.position
			var best_score: float = -INF
			for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2(1,1).normalized(), Vector2(-1,1).normalized(), Vector2(1,-1).normalized(), Vector2(-1,-1).normalized()]:
				var origin: Vector2 = enemy.global_position + direction * 180.0
				var ray := PhysicsRayQueryParameters2D.create(enemy.global_position, origin, 5, [enemy.get_rid()])
				if Room.ROOM_RECT.grow(-20).has_point(origin) and enemy.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
					var score: float = 500.0
					for other in CombatGeometry.targets(world.current_room):
						if other != enemy:
							score = minf(score, origin.distance_to(other.global_position))
					for projectile in world.current_room.projectiles.get_children():
						if projectile is EnemyProjectile:
							var closest := Geometry2D.get_closest_point_to_segment(origin, projectile.global_position, projectile.global_position + projectile.velocity * 0.3)
							score = minf(score, origin.distance_to(closest) * 2.0)
					if score > best_score:
						best_score = score
						safest = origin
			world.player.position = safest
			world.player.velocity = Vector2.ZERO
			world.player.weapon.try_attack(world.player.position, (enemy.global_position - world.player.position).normalized(), world.player.stats)
			await test.frames(14)
	await test.frames(14)
	test.check(not world.player.health.is_dead and world.current_room.room_state.status == RoomState.Status.CLEARED and world.current_room.enemy_spawner.get_remaining() == 0, "Active AI room clears using actual Player projectiles at " + str(world.current_id))
	await claim()


func visit(target: StringName) -> void:
	var world: RoomController = test.session.world
	var parent: Dictionary[StringName, StringName] = {world.current_id: &""}
	var queue: Array[StringName] = [world.current_id]
	while not queue.is_empty() and not parent.has(target):
		var id: StringName = queue.pop_front()
		for next_id in world.layout.rooms[id].neighbors.values():
			if not parent.has(next_id):
				parent[next_id] = id
				queue.append(next_id)
	var path: Array[StringName] = []
	var id := target
	while id != world.current_id:
		path.push_front(id)
		id = parent[id]
	for next_id in path:
		await fight()
		var side: int = world.layout.rooms[world.current_id].neighbors.find_key(next_id)
		await test.walk(side)
		if world.current_room.room_state.status == RoomState.Status.CLEARED:
			test.check(world.current_room.enemy_spawner.get_child_count() == 0, "Revisit CLEARED never spawns strengthened enemies")
		test.check(player_count(test.root) == 1 and world.player.relics.inventory.ids().size() == picked.size(), "Formal Build and unique Player survive traversal")
		if world.current_room.room_type == RoomDefinition.Type.COMBAT:
			await fight()


func run() -> void:
	var world: RoomController = test.session.world
	var signature := reward_signature(test.session.rewards)
	var player_id := world.player.get_instance_id()
	var combat_ids: Array[StringName] = []
	for id in world.layout.rooms:
		if world.layout.rooms[id].room_type == RoomDefinition.Type.COMBAT:
			combat_ids.append(id)
	combat_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return str(a) < str(b))
	for id in combat_ids:
		await visit(id)
		if test.session.rewards.combat_clears >= 7:
			break
	test.check(picked.size() == 3 and world.player.relics.inventory.ids().size() == 3 and picked[0] == test.session.rewards.sequence[0].id and picked[2] == test.session.rewards.sequence[2].id, "Normal Seed run obtains three formal relics through clear 2/4/7 pedestals")
	test.check(world.player.get_instance_id() == player_id and world.player.health.current_hp > 0.0, "Full reward flow preserves the same living Player")
	test.capture("three_relic_build")
	for id in combat_ids:
		if world.states[id].status == RoomState.Status.UNVISITED:
			await visit(id)
			break
	test.check(test.session.rewards.combat_clears >= 8 and picked.size() == 3 and world.player.relics.inventory.ids().size() == 3, "Normal three-relic Build continues fighting beyond seventh clear")
	var progress: int = test.session.rewards.combat_clears
	var clear_count: int = test.contexts.size()
	world.current_room.enter()
	test.check(test.session.rewards.combat_clears == progress and test.contexts.size() == clear_count, "Revisiting CLEARED never repeats clear contexts or rewards")
	await visit(world.layout.antique_id)
	var antiques: Array = test.contexts.filter(func(context: RoomClearContext) -> bool: return context.room_type == RoomDefinition.Type.ANTIQUE)
	test.check(not antiques.is_empty() and not antiques[0].was_combat and antiques[0].enemy_count == 0, "Real ANTIQUE emits non-combat RoomClearContext")
	var combats: Array = test.contexts.filter(func(context: RoomClearContext) -> bool: return context.room_type == RoomDefinition.Type.COMBAT)
	test.check(combats.size() >= 7 and combats.all(func(context: RoomClearContext) -> bool: return context.was_combat and context.enemy_count > 0), "Real COMBAT contexts carry original enemy counts")
	# 正式完整流程已验证；以下单独验证充能跨房与新局生命周期。
	await fight()
	world.player.relics.inventory.clear()
	var kite_data: RelicDefinition
	for item in pool.relics:
		if item.id == &"spirit_kite": kite_data = item
	world.player.relics.inventory.add(kite_data)
	var kite := world.player.relics.inventory.get_effect(kite_data.id)
	world.player.health.take_damage(10.0)
	await test.walk(world.layout.rooms[world.current_id].neighbors.keys()[0])
	test.check(kite.get("charged") and kite.install_count == 1, "Unconsumed kite charge survives Room change without reinstall")
	var old_world := world
	var old_service: RelicRewardService = test.session.rewards
	await test.reset(KEY_R)
	world = test.session.world
	test.check(world.player.relics.inventory.ids().is_empty() and reward_signature(test.session.rewards) == signature and not is_instance_valid(old_world) and not is_instance_valid(old_service) and kite.uninstall_count == 1, "R empties formal Build and repeats reward sequence without ghost world/service")
	await test.walk(world.layout.rooms[world.current_id].neighbors.keys()[0])
	test.check(world.current_room.enemy_spawner.get_children().all(func(enemy: Enemy) -> bool: return is_equal_approx(enemy.health.max_hp, enemy.definition.max_hp * world.current_room.difficulty.hp_multiplier)), "R rebuilds fresh multipliers without accumulating previous tier")
	var before_seed: int = test.session.seed_value
	old_world = world
	test.session._seed_rng.seed = 20261006
	await test.reset(KEY_N)
	world = test.session.world
	test.check(test.session.seed_value != before_seed and world.player.relics.inventory.ids().is_empty() and not is_instance_valid(old_world) and test.session.rewards.combat_clears == 0, "N resets Build and creates new reward progress")
	test.check(reward_signature(test.session.rewards) != signature and player_count(test.root) == 1, "Selected new Seed has different sequence and one Player")
	world.player.relics.inventory.add(kite_data)
	kite = world.player.relics.inventory.get_effect(kite_data.id)
	world.player.health.take_damage(1000.0)
	var progress_before: int = test.session.rewards.combat_clears
	var clear := RoomClearContext.new()
	clear.room_id = &"late_clear"
	clear.room_type = RoomDefinition.Type.COMBAT
	clear.was_combat = true
	test.session.rewards.on_room_cleared(clear)
	test.check(not kite.get("charged") and kite.uninstall_count == 1 and not test.session.rewards.active and test.session.rewards.combat_clears == progress_before, "Fatal damage creates no kite charge or post-death rewards")
	completed = true
