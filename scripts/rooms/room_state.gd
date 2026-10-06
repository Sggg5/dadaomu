class_name RoomState
extends RefCounted
## 地图持有的运行状态，不写回共享 RoomDefinition；只允许单向转换。

signal changed(status: Status)

enum Status { UNVISITED, ACTIVE, CLEARED }

var status: Status = Status.UNVISITED


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
