class_name RangedEnemyDefinition
extends EnemyDefinition
## 远程专用配置；近战定义不承担无关弹丸参数。

@export_range(1, 2000) var projectile_speed: float = 280.0
@export_range(1, 1000) var projectile_damage: float = 12.0
@export_range(0.1, 10) var projectile_lifetime: float = 3.0
@export_range(1, 1000) var preferred_distance: float = 240.0
@export_range(1, 300) var distance_tolerance: float = 40.0
@export_range(1, 500) var minimum_fire_distance: float = 90.0
