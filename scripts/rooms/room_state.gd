class_name RoomState
extends RefCounted
## 地图持有的运行状态，不写回共享 RoomDefinition；只允许单向转换。

signal changed(status: Status)

enum Status { UNVISITED, ACTIVE, CLEARED }

var status: Status = Status.UNVISITED
var claimed_loot_sources: Dictionary[StringName,bool] = {}
# 旧回归夹具兼容入口；真实领取逻辑只操作统一source，不维护第二份bool。
var antique_claimed: bool:
	get: return is_loot_claimed(&"antique_room")
	set(value):
		if value: claim_loot(&"antique_room")
		else: claimed_loot_sources.erase(&"antique_room")


func is_loot_claimed(source_id: StringName) -> bool: return claimed_loot_sources.has(source_id)


func claim_loot(source_id: StringName) -> bool:
	if source_id == &"" or is_loot_claimed(source_id): return false
	claimed_loot_sources[source_id] = true
	return true


func activate() -> bool:
	if status != Status.UNVISITED:
		return false
	status = Status.ACTIVE
	changed.emit(status)
	return true


func clear() -> bool:
	if status != Status.ACTIVE:
		return false
	status = Status.CLEARED
	changed.emit(status)
	return true


func get_label() -> String:
	return ["未探索", "战斗中 · 门已关闭", "已清场 · 门已打开"][status]
