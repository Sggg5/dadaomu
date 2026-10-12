class_name ProfessionCorpsePlan
extends RefCounted
## Independent VERSION2 stream. No initial-faction guarantee or global RNG.
const VERSION: int = 2
var assigned: Dictionary = {}
static func build(seed_value: int, floor: int, layout: DungeonLayout, config: Dictionary = {}) -> ProfessionCorpsePlan:
	var plan := ProfessionCorpsePlan.new()
	if config.is_empty(): config = JSON.parse_string(FileAccess.get_file_as_string("res://data/professions/corpse_distribution.json"))
	var rooms: Array[StringName] = []
	for id in layout.ordered_ids():
		if layout.rooms[id].room_type == RoomDefinition.Type.COMBAT and id != layout.terminal_id: rooms.append(id)
	if rooms.is_empty(): return plan
	var rng := RandomNumberGenerator.new()
	rng.seed = AntiquePool.stable_score(seed_value, floor, &"CORPSES", &"profession-corpses", VERSION)
	if floor > 1 and rng.randf() >= clampf(float(config.get("later_floor_chance",.5)),0,1): return plan
	if floor > 1 and int(config.get("max_per_floor",1)) < 1: return plan
	var room_id: StringName = rooms[rng.randi_range(0,rooms.size()-1)]
	plan.assigned[room_id] = ProfessionRunState.IDS[rng.randi_range(0,ProfessionRunState.IDS.size()-1)]
	return plan
