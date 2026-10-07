class_name AntiqueLootService
extends RefCounted
## 本层纯配置：按稳定评分选前三COMBAT；不监听战斗、进入顺序或奖励服务。
const VERSION: int = 1
var selected_rooms: Array[StringName] = []


func configure(run_seed: int, floor_number: int, layout: DungeonLayout) -> void:
	selected_rooms.clear()
	var candidates: Array[StringName] = []
	for id in layout.rooms:
		if id != layout.terminal_id and layout.rooms[id].room_type == RoomDefinition.Type.COMBAT: candidates.append(id)
	candidates.sort_custom(func(a: StringName,b: StringName) -> bool:
		var first := AntiquePool.stable_score(run_seed,floor_number,a,&"cache_room",VERSION)
		var second := AntiquePool.stable_score(run_seed,floor_number,b,&"cache_room",VERSION)
		return str(a) < str(b) if first == second else first < second)
	for index in range(mini(3,candidates.size())): selected_rooms.append(candidates[index])


func has_cache(room_id: StringName) -> bool: return room_id in selected_rooms
