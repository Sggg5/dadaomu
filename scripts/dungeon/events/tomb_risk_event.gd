class_name TombRiskEvent
extends Resource
## 只读事件配置；权重顺序为古董、伏击、机关、空棺，不持运行状态。
enum Kind { COFFIN, ALTAR, HIDDEN_REWARD }
@export var id: StringName
@export var display_name: String
@export var kind: Kind = Kind.COFFIN
@export var weights: PackedInt32Array = [35, 25, 20, 20]
@export var hp_cost: float = 20.0
@export var ambush_reward: bool = false
@export var high_value_reward: bool = false
@export var wave: RoomDefinition
