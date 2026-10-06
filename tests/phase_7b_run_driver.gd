extends RefCounted
## 风险流程驾驶：真实Door/武器/E/F/Tab/Delete，无主流程HP或Inventory注入。
var test: SceneTree
var driver: RefCounted
var pressure_exchanges: int = 0
var cache_pickups: int = 0


func _init(context: SceneTree) -> void:
	test = context
	driver = preload("res://tests/phase_5b_run_checks.gd").new(test)


func reset(seed_value: int) -> void:
	test.session._schedule_new_run(DungeonGenerator.generate(seed_value,test.session.config))
	await test.frames(5)
	driver = preload("res://tests/phase_5b_run_checks.gd").new(test)
	pressure_exchanges = 0
	cache_pickups = 0


func collect_floor() -> void:
	var session: DungeonSession = test.session
	var offers := preload("res://tests/phase_7b_plan_checks.gd").offers(session.run_seed,session.floor_number,session.world.layout)
	if session.floor_number == 1:
		offers.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.definition.base_value < b.definition.base_value)
	else:
		offers.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.definition.base_value > b.definition.base_value)
	for offer in offers:
		await driver.visit(offer.room)
		await take_current(offer)


func cheapest_index(items: Array[AntiqueDefinition]) -> int:
	var cheapest: int = 0
	for index in range(items.size()):
		if items[index].base_value < items[cheapest].base_value: cheapest = index
	return cheapest


func take_current(offer: Dictionary) -> void:
	var world: RoomController = test.session.world
	var name := "AntiqueCache" if offer.source == &"combat_cache" else "AntiquePedestal"
	var pickup := world.current_room.get_node_or_null(name) as AntiquePedestal
	if pickup == null: return
	var item := pickup.definition
	test.check(item == offer.definition, "Live pickup equals precomputed official source result")
	world.player.position = pickup.position+Vector2(24,0)
	world.player.velocity = Vector2.ZERO
	var inventory := world.player.antiques
	var before := inventory.items().size()
	if not inventory.can_add(item):
		var held := inventory.items()
		if held.is_empty() or held[cheapest_index(held)].base_value >= item.base_value: return
		test.key(KEY_E)
		test.check(not world.current_room.room_state.is_loot_claimed(offer.source) and inventory.items().size() == before and pickup.label.text.contains("背包空间不足"), "Official higher-value pickup truly fails E at full bag")
		await test.frames(1)
		test.capture("bag_full")
		test.key(KEY_TAB)
		await test.frames(2)
		var discarded_value: int = 0
		while not inventory.can_add(item) and not inventory.items().is_empty():
			var index := cheapest_index(inventory.items())
			var discarded := inventory.items()[index]
			var old_slots := inventory.used_slots()
			var old_value := inventory.total_value()
			discarded_value += discarded.base_value
			world.antique_panel.list.select(index)
			test.key(KEY_DELETE)
			test.check(inventory.used_slots() == old_slots-discarded.slots and inventory.total_value() == old_value-discarded.base_value, "Real Delete releases selected antique slots and exact value")
		await test.frames(2)
		test.capture("value_density_panel")
		test.key(KEY_TAB)
		if item.base_value > discarded_value: pressure_exchanges += 1
		print("[Pressure swap] discard %d -> %s %d, slots %d" % [discarded_value,item.display_name,item.base_value,inventory.used_slots()+item.slots])
	test.key(KEY_E)
	test.check(world.current_room.room_state.is_loot_claimed(offer.source) and inventory.items().back() == item, "Actual E claims official source after any real discard")
	if offer.source == &"combat_cache": cache_pickups += 1
	await test.frames(3)


func defeat_warlord() -> void:
	await driver.visit(test.session.world.layout.boss_id)
	var fight = preload("res://tests/phase_6_floor_checks.gd").new(test)
	await fight.boss_fight()
	test.check(test.session.bosses_defeated == 1 and not test.session.run_ended, "True warlord victory leaves active Run with one explicit Boss")


func descend() -> void:
	var session: DungeonSession = test.session
	var world := session.world
	var exit := world.current_room.get_node("ExpeditionExit") as ExpeditionExit
	world.player.position = exit.position+Vector2(100,0)
	test.check(not exit.request_descend() and not exit.request_extract(), "Expedition E/F both refuse outside64px")
	var old_items := world.player.antiques.items()
	var hp := world.player.health.current_hp
	world.player.position = exit.position+Vector2(24,0)
	await test.frames(1)
	test.capture("expedition_choice")
	test.key(KEY_E)
	test.key(KEY_F)
	test.check(exit.used and not exit.request_extract(), "E atomically disables F choice before floor change")
	await test.frames(5)
	test.check(session.floor_number == 2 and not session.run_ended and session.world.player.antiques.items() == old_items and session.world.player.health.current_hp == hp, "Actual E/F race only descends; HP/cargo carry without extraction")


func die_to_enemy() -> void:
	var world: RoomController = test.session.world
	var target: StringName = &""
	for id in world.layout.rooms:
		if world.layout.rooms[id].room_type == RoomDefinition.Type.COMBAT and world.states[id].status == RoomState.Status.UNVISITED:
			target = id
			break
	if target == &"": target = world.layout.boss_id
	# visit自动驾驶会清目标，故只沿已清路径到目标相邻格，然后真实过门。
	var path: Array[StringName] = []
	var parents: Dictionary[StringName,StringName] = {world.current_id:&""}
	var queue: Array[StringName] = [world.current_id]
	while not parents.has(target):
		var current: StringName = queue.pop_front()
		for next in world.layout.rooms[current].neighbors.values():
			if not parents.has(next):
				parents[next] = current
				queue.append(next)
	var cursor := target
	while cursor != world.current_id:
		path.push_front(cursor)
		cursor = parents[cursor]
	for next in path:
		if world.current_room.room_type == RoomDefinition.Type.COMBAT: await driver.fight()
		await test.walk(world.layout.rooms[world.current_id].neighbors.find_key(next))
	var hostile: Enemy
	for actor in world.current_room.damage_targets():
		if actor is ScarabEnemy:
			hostile = actor
			break
	if hostile == null: hostile = world.current_room.damage_targets()[0] as Enemy
	var before := world.player.health.current_hp
	for frame in range(2400):
		if world.player.health.is_dead: break
		if is_instance_valid(hostile):
			var distance: float = 240 if hostile is BanditShooter else 34
			world.player.position = hostile.position+Vector2(0,distance)
			world.player.velocity = Vector2.ZERO
		await test.frames(1)
	test.check(before > 0 and world.player.health.is_dead and world.player.health.current_hp == 0, "Active real enemy attacks cause fatal damage, without Health cheat")
