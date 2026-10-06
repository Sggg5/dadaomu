extends RefCounted
## 只测纯评分/数据；另以正式结果寻找真实满包交换Seed，不更改掉落。
const POOL: AntiquePool = preload("res://data/antiques/formal_pool.tres")
var test: SceneTree
var completed: bool = false
var pressure_seed: int = -1
var pressure_slots: int


func _init(context: SceneTree) -> void: test = context


static func offers(seed_value: int, floor_number: int, layout: DungeonLayout) -> Array[Dictionary]:
	var service := AntiqueLootService.new()
	service.configure(seed_value,floor_number,layout)
	var result: Array[Dictionary] = [{"room":layout.antique_id,"source":&"antique_room","definition":POOL.pick(seed_value,floor_number,layout.antique_id)}]
	for id in service.selected_rooms: result.append({"room":id,"source":&"combat_cache","definition":POOL.pick(seed_value,floor_number,id,&"combat_cache")})
	return result


func run() -> void:
	var reward_signature: Array[RelicDefinition] = test.session.rewards.sequence.duplicate()
	var all_rarities: Dictionary[int,bool] = {}
	var changed_sources: bool = false
	var changed_floors: bool = false
	var selected_variants: Dictionary[String,bool] = {}
	for seed_value in range(100):
		var layout := DungeonGenerator.generate(seed_value,test.session.config)
		var first := AntiqueLootService.new()
		first.configure(seed_value,1,layout)
		var repeated := AntiqueLootService.new()
		repeated.configure(seed_value,1,layout)
		var other_floor := AntiqueLootService.new()
		other_floor.configure(seed_value,2,layout)
		changed_floors = changed_floors or first.selected_rooms != other_floor.selected_rooms
		selected_variants[str(first.selected_rooms)] = true
		test.check(first.selected_rooms.size() == 3 and first.selected_rooms == repeated.selected_rooms and first.selected_rooms.all(func(id: StringName) -> bool: return layout.rooms[id].room_type == RoomDefinition.Type.COMBAT), "Seed %d selects exactly3 distinct COMBAT, excludes all special types, deterministic" % seed_value)
		var unique: Dictionary[StringName,bool] = {}
		for id in first.selected_rooms: unique[id] = true
		test.check(unique.size() == 3, "Cache rooms unique Seed " + str(seed_value))
		var item := POOL.pick(seed_value,1,&"ROOM_001",&"combat_cache")
		all_rarities[item.rarity] = true
		changed_sources = changed_sources or item != POOL.pick(seed_value,1,&"ROOM_001",&"antique_room")
		for source in [&"antique_room",&"combat_cache"]:
			var second := POOL.pick(seed_value,2,&"ROOM_001",source)
			test.check(second.rarity >= AntiqueDefinition.Rarity.UNCOMMON and second == POOL.pick(seed_value,2,&"ROOM_001",source) and second in POOL.antiques, "Floor2 %s UNCOMMON+ stable original Definition Seed%d" % [source,seed_value])
	test.check(all_rarities.size() == 4 and changed_sources and changed_floors and selected_variants.size() > 3, "Floor1 all rarity/source independence/floor independence/new Seed variation")
	test.check(test.session.rewards.sequence == reward_signature, "Cache/antique generation does not change RelicRewardService sequence")
	var original := DungeonGenerator.generate(192034,test.session.config)
	var reordered := DungeonLayout.new()
	var keys := original.ordered_ids()
	keys.reverse()
	for id in keys: reordered.rooms[id] = original.rooms[id]
	var sorted_service := AntiqueLootService.new()
	var reverse_service := AntiqueLootService.new()
	sorted_service.configure(192034,1,original)
	reverse_service.configure(192034,1,reordered)
	test.check(sorted_service.selected_rooms == reverse_service.selected_rooms, "Input room insertion/order does not affect selected cache set")
	var source := FileAccess.get_file_as_string("res://scripts/antiques/antique_loot_service.gd")
	test.check(not source.contains("randi(") and not source.contains("randomize(") and not source.contains("Time."), "Loot scoring uses no global RNG or time")
	var small := DungeonLayout.new()
	for index in range(2):
		var node := DungeonRoom.new()
		node.room_id = StringName("small%d" % index)
		node.coordinate = Vector2i(index,0)
		node.room_type = RoomDefinition.Type.COMBAT
		small.add_room(node)
	var shortage := AntiqueLootService.new()
	shortage.configure(1,1,small)
	test.check(shortage.selected_rooms.size() == 2, "Under3 COMBAT degrades to available count")
	shortage.configure(1,1,DungeonLayout.new())
	test.check(shortage.selected_rooms.is_empty(), "Zero candidates safely gives zero caches")
	var state := RoomState.new()
	test.check(state.claim_loot(&"antique_room") and not state.claim_loot(&"antique_room") and not state.is_loot_claimed(&"combat_cache") and state.claim_loot(&"combat_cache") and state.claimed_loot_sources.size() == 2, "Unified sources independently claim exactly once")
	find_pressure_seed()
	test.check(pressure_seed >= 0 and pressure_slots > 8, "Official eight opportunities have slots>8 and an actual higher-value exchange path")
	print("[Pressure plan] Seed=%d, eight opportunity slots=%d" % [pressure_seed,pressure_slots])
	completed = true


func find_pressure_seed() -> void:
	var detached := preload("res://scenes/main/dungeon_test.tscn").instantiate() as DungeonSession
	var seeds: Array[int] = [192034]
	for number in range(100): seeds.append(number)
	for seed_value in seeds:
		detached.run_seed = seed_value
		var first := offers(seed_value,1,DungeonGenerator.generate(seed_value,detached.config))
		var second := offers(seed_value,2,detached.next_floor_layout())
		first.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.definition.base_value < b.definition.base_value)
		second.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.definition.base_value > b.definition.base_value)
		var held: Array[AntiqueDefinition] = []
		var used: int = 0
		var total: int = 0
		var upgraded: bool = false
		for offer in first+second:
			var item: AntiqueDefinition = offer.definition
			total += item.slots
			if used+item.slots > 8 and not held.is_empty():
				held.sort_custom(func(a: AntiqueDefinition,b: AntiqueDefinition) -> bool: return a.base_value < b.base_value)
				if held[0].base_value >= item.base_value: continue
				upgraded = true
				while used+item.slots > 8 and not held.is_empty(): used -= held.pop_front().slots
			if used+item.slots <= 8:
				held.append(item)
				used += item.slots
		if total > 8 and upgraded:
			pressure_seed = seed_value
			pressure_slots = total
			break
	detached.free()
