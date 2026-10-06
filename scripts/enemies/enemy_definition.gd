class_name EnemyDefinition
extends Resource
## 共享只读属性，不包含 AI 类型分支；运行时生命和计时器属于敌人实例。

@export var id: StringName
@export var display_name: String
@export_range(1, 1000) var max_hp: float = 50.0
@export_range(0, 1000) var move_speed: float = 150.0
@export_range(0, 1000) var contact_damage: float = 10.0
@export_range(0.1, 10) var attack_cooldown: float = 1.0
@export_range(0.05, 3) var windup_time: float = 0.22
@export_range(0, 3) var recovery_time: float = 0.28
@export_range(1, 1000) var attack_range: float = 42.0
@export_range(0.05, 1) var death_duration: float = 0.16
@export_range(1, 100) var obstacle_probe_distance: float = 32.0
@export_range(0.05, 1) var avoidance_hold_time: float = 0.35
@export var body_color: Color = Color("98b568")
