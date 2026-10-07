class_name BossDefinition
extends EnemyDefinition
@export var boss_scene: PackedScene
@export var intro_duration: float = 1.0
@export var charge_damage: float = 18.0
@export var charge_speed: float = 650.0
@export var charge_windup: float = 0.65
@export var charge_duration: float = 0.45
@export var shockwave_damage: float = 16.0
@export var shockwave_radius: float = 180.0
@export var shockwave_windup: float = 0.8
@export var summon_count: int = 3
@export var phase_two_threshold: float = 0.5
@export var decision_cooldown: float = 1.0
@export var phase_two_cooldown_multiplier: float = 0.8
## Production mechanism rhythm; historical Boss actors retain their original cooldown fields.
@export_range(0.45, 1.3) var boss_recovery_time: float = 0.8
@export_range(0.9, 1.3) var combo_recovery_time: float = 1.05
@export var compatible_arena_tags:Array[StringName]=[&"OPEN"]
