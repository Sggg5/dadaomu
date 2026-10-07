extends RefCounted
const TOMB: TombDefinition = preload("res://data/tombs/default_tomb.tres")
const POOL: AntiquePool = preload("res://data/antiques/formal_pool.tres")
var test: SceneTree
func _init(context: SceneTree) -> void: test = context

func run() -> void:
	test.check(TOMB.validation_error().is_empty() and TOMB.floors.size() == 5, "Default valid five-floor tomb")
	var sums := [0, 0, 0, 0, 0]
	var rarity_sums := [0.0, 0.0, 0.0, 0.0, 0.0]
	var values := [0.0, 0.0, 0.0, 0.0, 0.0]
	var common5 := 0
	var treasure5 := 0
	for seed_value in range(1000):
		for number in range(1, 6):
			var data := TOMB.floor_at(number)
			var layout := TombFloorGenerator.generate(seed_value, number, TOMB)
			var cfg := data.dungeon_config
			test.check(layout != null and layout.rooms.size() >= cfg.min_rooms and layout.rooms.size() <= cfg.max_rooms, "Floor%d room range seed%d" % [number, seed_value])
			sums[number-1] += layout.rooms.size()
			var loot := AntiqueLootService.new()
			loot.configure(seed_value,number,layout,data.combat_cache_count)
			test.check(data.combat_cache_count == 1 and loot.selected_rooms.size() == 1, "Each production floor has exactly one cache across 1000 Seeds")
			var distances := {layout.start_id: 0}
			var queue: Array[StringName] = [layout.start_id]
			while not queue.is_empty():
				var id: StringName = queue.pop_front()
				for neighbor in layout.rooms[id].neighbors.values():
					if not distances.has(neighbor):
						distances[neighbor] = distances[id] + 1
						queue.append(neighbor)
			test.check(distances.size() == layout.rooms.size() and distances[layout.terminal_id] >= cfg.min_terminal_distance and layout.antique_id not in [layout.start_id, layout.terminal_id], "Reachable terminal and distinct antique")
			test.check((layout.boss_id == layout.terminal_id) if number in [2, 5] else (layout.boss_id == &"" and layout.rooms[layout.terminal_id].room_type == RoomDefinition.Type.COMBAT), "Real Boss identity distinct from combat terminal")
			test.check(layout.signature() == TombFloorGenerator.generate(seed_value, number, TOMB).signature(), "All floor Seed reproducibility")
			var item := POOL.pick_profiled(seed_value, number, &"ROOM", &"antique_room", data.antique_reward_profile)
			test.check(item == POOL.pick_profiled(seed_value, number, &"ROOM", &"antique_room", data.antique_reward_profile), "Profile RNG deterministic")
			rarity_sums[number-1] += item.rarity
			values[number-1] += item.base_value
			if number == 5:
				common5 += int(item.rarity == AntiqueDefinition.Rarity.COMMON)
				treasure5 += int(item.rarity == AntiqueDefinition.Rarity.TREASURE)
	for index in range(5):
		print("[9B statistics] Floor%d rooms=%.3f rarity=%.3f value=%.2f" % [index+1, sums[index]/1000.0, rarity_sums[index]/1000.0, values[index]/1000.0])
		if index > 0:
			test.check(rarity_sums[index] > rarity_sums[index-1] and values[index] > values[index-1], "Increasing reward quality expectation")
		if index > 0 and index < 4: test.check(sums[index] > sums[index-1], "F1 through F4 average map growth")
	test.check(sums[4] < sums[3] and common5 > 0 and treasure5 > 0, "F5 contraction with both COMMON and TREASURE")
	var legacy: TombDefinition = preload("res://tests/fixtures/legacy_two_floor_tomb.tres")
	test.check(legacy.floors.size() == 2 and legacy.validation_error().is_empty(), "Explicit legacy valid two-floor fixture")
	for number in range(1, 3):
		var loot := AntiqueLootService.new()
		var layout := TombFloorGenerator.generate(33,number,legacy)
		loot.configure(33,number,layout,legacy.floor_at(number).combat_cache_count)
		test.check(legacy.floor_at(number).combat_cache_count == 3 and loot.selected_rooms.size() == 3, "Legacy three-cache semantics preserved")
	await custom_terminal_comparison()
	var empty := TombDefinition.new()
	test.check(not empty.validation_error().is_empty(), "Reject missing tomb ID and floors")
	var invalid := AntiqueRewardProfile.new()
	for weights in [PackedFloat32Array([1, 2]), PackedFloat32Array([0, 0, 0, 0]), PackedFloat32Array([-1, 1, 1, 1])]:
		invalid.rarity_weights = weights
		test.check(not invalid.validation_error().is_empty(), "Reject invalid reward weights")
	var sparse := AntiquePool.new()
	sparse.antiques = [POOL.antiques[0]]
	test.check(sparse.pick_profiled(1, 5, &"R", &"S", TOMB.floor_at(5).antique_reward_profile) == sparse.antiques[0], "Sparse rarity pool renormalizes")
	for number in range(1, 6):
		var layout := TombFloorGenerator.generate(33, number, TOMB)
		print("[9B sample] Run33 floor%d seed=%d rooms=%d terminal=%s" % [number, layout.seed_value, layout.rooms.size(), layout.terminal_id])
	test.check(MuseumProfileStore.VERSION == 4, "No Profile v5 or mid-run save")


func custom_terminal_comparison() -> void:
	var tomb := TombDefinition.new()
	tomb.id = &"OVERRIDE_TERMINAL_TEST"
	var first := TOMB.floor_at(1).duplicate() as TombFloorDefinition
	first.dungeon_config = first.dungeon_config.duplicate() as DungeonConfig
	first.dungeon_config.terminal_is_boss = true
	first.terminal_mode = TombFloorDefinition.TerminalMode.COMBAT
	first.dungeon_config.min_rooms = 4
	first.dungeon_config.max_rooms = 4
	var second := first.duplicate() as TombFloorDefinition
	var saw_retry := false
	tomb.floors.assign([first,second])
	for seed_value in range(100):
		var actual_first := TombFloorGenerator.generate(seed_value,1,tomb)
		test.check(actual_first.boss_id == &"" and actual_first.rooms[actual_first.terminal_id].room_type == RoomDefinition.Type.COMBAT and first.dungeon_config.terminal_is_boss, "Floor mode overrides raw config without mutating Resource")
		var expected: DungeonLayout
		var config := second.dungeon_config.duplicate() as DungeonConfig
		config.terminal_is_boss = false
		for attempt in range(16):
			var candidate := DungeonGenerator.generate((seed_value ^ (2*104729))+attempt*7919,config)
			if candidate.spatial_signature() != actual_first.spatial_signature():
				expected = candidate
				saw_retry = saw_retry or attempt > 0
				break
		test.check(TombFloorGenerator.generate(seed_value,2,tomb).signature() == expected.signature(), "Floor2 compares against actual assembled Floor1 with finite legacy Seed algorithm")

	test.check(saw_retry, "Custom same-size combat floors exercise an actual rejected identical first candidate")
