class_name AntiquePool
extends Resource
## 与地图/遗物RNG独立；稳定字符混合与稳定ID排序，不用全局随机或String.hash。
@export var antiques: Array[AntiqueDefinition] = []
const VERSION: int = 2


func find_by_id(id: StringName) -> AntiqueDefinition:
	for item in antiques:
		if item.id == id: return item
	return null


func is_valid() -> bool:
	var seen: Dictionary[StringName,bool] = {}
	for item in antiques:
		if item == null or not item.is_valid() or seen.has(item.id): return false
		seen[item.id] = true
	return not antiques.is_empty()


static func stable_score(run_seed: int, floor_number: int, room_id: StringName, source_id: StringName, version: int) -> int:
	var key := "%d|%d|%d|%s|%s" % [version,run_seed,floor_number,room_id,source_id]
	var mixed: int = 17
	for index in range(key.length()): mixed = (mixed*131+key.unicode_at(index))%2147483647
	return mixed


func pick(run_seed: int, floor_number: int, room_id: StringName, source_id: StringName = &"antique_room") -> AntiqueDefinition:
	assert(is_valid(), "Antique pool requires valid unique definitions")
	var rng := RandomNumberGenerator.new()
	rng.seed = stable_score(run_seed,floor_number,room_id,source_id,VERSION)
	var ordered: Array[AntiqueDefinition] = []
	for item in antiques:
		if floor_number < 2 or item.rarity >= AntiqueDefinition.Rarity.UNCOMMON: ordered.append(item)
	assert(not ordered.is_empty(), "Floor2 requires UNCOMMON+ antiques")
	ordered.sort_custom(func(a: AntiqueDefinition,b: AntiqueDefinition) -> bool: return str(a.id) < str(b.id))
	return ordered[rng.randi_range(0,ordered.size()-1)]


func pick_profiled(run_seed: int, floor_number: int, room_id: StringName, source_id: StringName, profile: AntiqueRewardProfile) -> AntiqueDefinition:
	assert(is_valid() and profile != null and profile.validation_error().is_empty())
	var groups: Array[Array] = [[], [], [], []]
	for item in antiques: groups[item.rarity].append(item)
	var total := 0.0
	for index in range(4):
		groups[index].sort_custom(func(a: AntiqueDefinition, b: AntiqueDefinition) -> bool: return str(a.id) < str(b.id))
		if not groups[index].is_empty(): total += profile.rarity_weights[index]
	# A sparse custom pool may contain only zero-weight groups: fall back to those existing groups.
	var fallback := total <= 0
	if fallback:
		for group in groups:
			if not group.is_empty(): total += 1
	var rng := RandomNumberGenerator.new()
	rng.seed = stable_score(run_seed, floor_number, room_id, StringName("profile:%s" % source_id), 1)
	var roll := rng.randf() * total
	for index in range(4):
		if groups[index].is_empty(): continue
		roll -= 1.0 if fallback else profile.rarity_weights[index]
		if roll < 0: return groups[index][rng.randi_range(0, groups[index].size() - 1)]
	for index in range(3, -1, -1):
		if not groups[index].is_empty() and (fallback or profile.rarity_weights[index] > 0): return groups[index][0]
	return null
