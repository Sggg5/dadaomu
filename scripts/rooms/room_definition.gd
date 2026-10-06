class_name RoomDefinition
extends Resource
## 房间只读内容。五个测试资源复用同一场景和行为，只改变布局与生成数据。
## 非战斗类型仅预留标识；相应内容与规则未在 Phase 2 实现。

enum Type { COMBAT, ANTIQUE, MERCHANT, TRAP, SECRET, BOSS }

@export var room_id: StringName
@export var title: String
@export var room_type: Type = Type.COMBAT
@export var map_position: Vector2i
@export var floor_color: Color = Color("20292c")
@export var enemy_scene: PackedScene
@export var enemy_positions: PackedVector2Array
@export var obstacles: Array[Rect2] = []
