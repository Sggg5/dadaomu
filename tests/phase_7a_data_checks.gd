extends RefCounted
var test: SceneTree
var completed: bool = false
const POOL: AntiquePool = preload("res://data/antiques/formal_pool.tres")


func _init(context: SceneTree) -> void: test = context


func run() -> void:
	test.check(POOL.antiques.size() == 8 and POOL.is_valid(), "Eight formal antiques have unique valid IDs/positive value/slots")
	var expected: Array = [[120,1,0],[350,2,0],[600,2,1],[900,1,1],[1200,2,2],[1600,3,2],[2200,1,3],[3000,3,3]]
	for index in range(8):
		var item := POOL.antiques[index]
		test.check(item.base_value == expected[index][0] and item.slots == expected[index][1] and item.rarity == expected[index][2], "Formal antique exact data: " + item.display_name)
	var inventory := AntiqueInventory.new()
	test.check(inventory.capacity == 8 and inventory.used_slots() == 0 and inventory.free_slots() == 8 and inventory.total_value() == 0, "Default capacity8 has zero slots/value")
	test.check(not inventory.can_add(null) and not inventory.add(null) and not inventory.remove_at(-1), "Invalid additions/removal rejected")
	var invalid := AntiqueDefinition.new()
	invalid.id = &"bad"
	invalid.display_name = "错误资源"
	invalid.slots = 0
	test.check(not inventory.can_add(invalid), "Invalid zero-slot definition rejected")
	var coin := POOL.antiques[0]
	for index in range(8): test.check(inventory.can_add(coin) and inventory.add(coin), "Each coin occupies one slot, including duplicates " + str(index))
	test.check(inventory.used_slots() == 8 and inventory.free_slots() == 0 and inventory.total_value() == 960 and not inventory.can_add(coin) and not inventory.add(coin), "Full inventory rejects overflow without changing contents")
	var copy := inventory.items()
	copy.clear()
	test.check(inventory.items().size() == 8, "items returns detached array, not internal storage")
	test.check(inventory.remove(coin.id) and inventory.used_slots() == 7 and inventory.free_slots() == 1 and inventory.total_value() == 840, "ID removal frees one duplicate's slots/value")
	test.check(inventory.remove_at(0) and inventory.used_slots() == 6 and not inventory.remove(&"missing") and not inventory.remove_at(99), "Indexed removal and invalid indices correct")
	inventory.clear()
	test.check(inventory.items().is_empty() and inventory.used_slots() == 0 and inventory.free_slots() == 8 and inventory.total_value() == 0, "Clear empties antique inventory")
	inventory.add(POOL.antiques[5])
	inventory.add(POOL.antiques[7])
	inventory.add(POOL.antiques[1])
	test.check(inventory.used_slots() == 8 and inventory.free_slots() == 0 and inventory.total_value() == 4950 and not inventory.can_add(coin), "Mixed3/3/2-slot antiques correctly fill capacity and sum values")
	inventory.remove_at(1)
	test.check(inventory.used_slots() == 5 and inventory.free_slots() == 3 and inventory.total_value() == 1950 and inventory.can_add(POOL.antiques[4]), "Removing3-slot item frees actual slot count, not one item slot")
	inventory.add(POOL.antiques[4])
	test.check(inventory.used_slots() == 7 and not inventory.can_add(POOL.antiques[1]) and inventory.can_add(coin), "One remaining slot refuses2-slot antique but accepts1-slot antique")
	var seen: Dictionary[StringName,bool] = {}
	for seed_value in range(100):
		var item := POOL.pick(seed_value,1,&"ROOM_003")
		seen[item.id] = true
		test.check(item == POOL.pick(seed_value,1,&"ROOM_003") and POOL.antiques.has(POOL.pick(seed_value,2,&"ROOM_003")), "Independent selection deterministic and valid on both floors Seed " + str(seed_value))
	test.check(seen.size() >= 6, "100 different Seeds vary across formal antique pool")
	await integration_boundaries()
	completed = true


func integration_boundaries() -> void:
	var world: RoomController = test.session.world
	var player := world.player
	var relic_ids := player.relics.inventory.ids()
	var stats := player.stats
	var snapshot: Array = [stats.max_hp,stats.move_speed,stats.attack_damage,stats.attack_speed,stats.projectile_speed]
	for index in range(8): player.antiques.add(POOL.antiques[0])
	test.check(player.relics.inventory.ids() == relic_ids and snapshot == [stats.max_hp,stats.move_speed,stats.attack_damage,stats.attack_speed,stats.projectile_speed] and player.health.current_hp == 80, "Antiques independent from RelicInventory and all Player combat stats/HP")
	world._switch_room(world.layout.antique_id,-1)
	await test.frames(2)
	var room := world.current_room
	var pedestal := room.get_node("AntiquePedestal") as AntiquePedestal
	var selected := pedestal.definition
	player.position = pedestal.position
	test.key(KEY_E)
	test.check(not room.room_state.antique_claimed and player.antiques.used_slots() == 8 and pedestal.label.text.contains("背包空间不足"), "Full bag real E refuses pickup and explains insufficient space")
	var before := world.current_id
	await test.walk(world.layout.rooms[before].neighbors.keys()[0])
	test.check(world.current_id != before and player.antiques.used_slots() == 8, "Unpicked antique does not prevent actual Door traversal")
	world._switch_room(before,-1)
	await test.frames(2)
	pedestal = world.current_room.get_node("AntiquePedestal") as AntiquePedestal
	test.check(pedestal.definition == selected, "Unclaimed antique returns as same selection on revisit")
	var panel := world.antique_panel
	test.key(KEY_TAB)
	panel.list.select(0)
	test.key(KEY_DELETE)
	test.check(panel.panel.visible and panel.list.item_count == 7 and player.antiques.used_slots() == 7 and player.antiques.total_value() == 840 and world.hud.antique_label.text.contains("7 / 8格"), "Real Tab/Delete discards permanently and refreshes Panel/HUD/slots/value")
	test.key(KEY_TAB)
	# 丢弃真正释放足够格数后重试，不用clear模拟腾出空间。
	while player.antiques.free_slots() < selected.slots: player.antiques.remove_at(0)
	player.position = pedestal.position
	test.key(KEY_E)
	test.check(player.antiques.items().back() == selected and world.states[before].antique_claimed, "Discard-freed space allows actual E retry pickup")
	player.antiques.remove_at(player.antiques.items().size()-1)
	world._switch_room(world.layout.start_id,-1)
	world._switch_room(before,-1)
	test.check(not world.current_room.has_node("AntiquePedestal"), "Discarded collected antique never regenerates on the floor")
	player.antiques.add(selected)
	await test.reset(KEY_R)
	test.check(test.session.world.player.antiques.items().is_empty(), "R creates empty antique bag")
	test.session.world.player.antiques.add(selected)
	test.session._seed_rng.seed = 20261006
	await test.reset(KEY_N)
	test.check(test.session.world.player.antiques.items().is_empty(), "N creates empty antique bag")
