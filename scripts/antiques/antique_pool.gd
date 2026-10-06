class_name AntiquePool
extends Resource
## 与地图/遗物RNG独立；稳定字符混合与稳定ID排序，不用全局随机或String.hash。
@export var antiques: Array[AntiqueDefinition] = []
const VERSION: int = 1


func is_valid() -> bool:
	var seen: Dictionary[StringName,bool] = {}
	for item in antiques:
		if item == null or not item.is_valid() or seen.has(item.id): return false
		seen[item.id] = true
	return not antiques.is_empty()


func pick(run_seed: int, floor_number: int, room_id: StringName) -> AntiqueDefinition:
	assert(is_valid(), "Antique pool requires valid unique definitions")
	var key := "%d|%d|%d|%s" % [VERSION,run_seed,floor_number,room_id]
	var mixed: int = 17
	for index in range(key.length()): mixed = (mixed*131+key.unicode_at(index))%2147483647
	var rng := RandomNumberGenerator.new()
	rng.seed = mixed
	var ordered := antiques.duplicate()
	ordered.sort_custom(func(a: AntiqueDefinition,b: AntiqueDefinition) -> bool: return str(a.id) < str(b.id))
	return ordered[rng.randi_range(0,ordered.size()-1)]
