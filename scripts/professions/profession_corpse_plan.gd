class_name ProfessionCorpsePlan
extends RefCounted
const VERSION: int = 1
var assigned: Dictionary = {}
static func build(seed_value: int, floor: int, layout: DungeonLayout) -> ProfessionCorpsePlan:
	var plan := ProfessionCorpsePlan.new()
	var rooms: Array[StringName] = []
	for id in layout.ordered_ids():
		if layout.rooms[id].room_type == RoomDefinition.Type.COMBAT and id != layout.terminal_id: rooms.append(id)
	var rng := RandomNumberGenerator.new()
	rng.seed = AntiquePool.stable_score(seed_value, floor, &"CORPSES", &"profession-corpses", VERSION)
	var factions := ProfessionRunState.IDS.duplicate()
	for array in [rooms, factions]:
		for index in range(array.size()-1, 0, -1):
			var other := rng.randi_range(0,index)
			var old = array[index]; array[index] = array[other]; array[other] = old
	var count: int = mini(4 if floor == 1 else 1, rooms.size())
	for index in range(count): plan.assigned[rooms[index]] = factions[index]
	return plan
