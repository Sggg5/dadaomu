class_name PlayerStats
extends Resource
## 只读的初始配置；CurrentHP 由每个角色自己的 Health 管理。

@export_range(1.0, 1000.0) var max_hp: float = 100.0
@export_range(1.0, 1000.0) var move_speed: float = 280.0
@export_range(1.0, 10000.0) var acceleration: float = 1800.0
@export_range(1.0, 10000.0) var deceleration: float = 2200.0
@export_range(1.0, 1000.0) var attack_damage: float = 20.0
## 每秒攻击次数，不是冷却秒数。
@export_range(0.1, 30.0) var attack_speed: float = 5.0
@export_range(1.0, 5000.0) var projectile_speed: float = 750.0
@export_range(0.1, 10.0) var projectile_lifetime: float = 2.0
@export_range(0.0, 3.0) var hurt_invulnerability: float = 0.35
