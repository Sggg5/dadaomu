class_name RoomDefinition
extends Resource
## 房间只读内容。五个测试资源复用同一场景和行为，只改变布局与生成数据。
## room_id 是历史命名的模板 ID；map_position 仅用于旧测试夹具。
## 随机图的位置、身份与类型属于 DungeonRoom，不从这些模板元数据读取。

enum Type { COMBAT, ANTIQUE, MERCHANT, TRAP, SECRET, BOSS, START, RELIC }

@export_range(1,5) var threat_rating: int = 2
@export_range(1,100) var selection_weight: int = 1
@export var coffin_style: bool = false
## 仅旧测试/历史模板保留空间字段。正式variety Encounter的空间由Geometry独立注入。
@export var environments: Array[EncounterHazardDefinition] = []
@export var room_id: StringName
@export var title: String
@export var room_type: Type = Type.COMBAT
@export var map_position: Vector2i
@export var floor_color: Color = Color("20292c")
@export var spawns: Array[EnemySpawnDefinition] = []
## 入房观察期仍立即生成敌人，但暂缓移动和攻击，避免持键过门遭先手。
@export_range(0.0, 3.0) var entry_grace_time: float = 0.35
@export var obstacles: Array[Rect2] = []
