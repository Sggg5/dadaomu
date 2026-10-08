class_name EncounterHazardDefinition
extends Resource
## 只读静态环境数据；动态死亡区域使用新的实例数据，绝不持有Node。
enum Kind { SPIKES, ARROW_HOLE, WATER, BLAST, POISON, RING, GATE_SWEEP, FIRE_FAN }
@export var kind: Kind = Kind.SPIKES
@export var position: Vector2
@export var radius: float = 48
@export var warning_time: float = 0.8
@export var initial_delay: float = 1.2
@export var interval: float = 4
@export var duration: float = 0.25
@export var damage: float = 8
@export var projectile_speed: float = 700
@export var direction: Vector2 = Vector2.RIGHT
@export var periodic: bool = true
@export var combat_only: bool = true

@export var strip_length:float=320
@export var strip_width:float=32
