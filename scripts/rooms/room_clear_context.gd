class_name RoomClearContext
extends RefCounted
## Controller 生成的首次清场快照；类型不可由模板名猜测。
var room_id: StringName
var room_type: RoomDefinition.Type
var was_combat: bool = false
var enemy_count: int = 0
