class_name RoomDefinition
extends Resource
## 房间只读内容。五个测试资源复用同一场景和行为，只改变布局与生成数据。
## room_id 是历史命名的模板 ID；map_position 仅用于旧测试夹具。
## 随机图的位置、身份与类型属于 DungeonRoom，不从这些模板元数据读取。

enum Type { COMBAT, ANTIQUE, MERCHANT, TRAP, SECRET, BOSS, START }

@export var room_id: StringName
@export var title: String
@export var room_type: Type = Type.COMBAT
@export var map_position: Vector2i
@export var floor_color: Color = Color("20292c")
@export var enemy_scene: PackedScene
@export var enemy_positions: PackedVector2Array
@export var obstacles: Array[Rect2] = []
