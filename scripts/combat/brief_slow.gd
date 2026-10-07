class_name BriefSlow
extends Node
## 单目标有限减速，不写EnemyDefinition；独立键可正确卸载。
var target: Enemy
var remaining: float = 0.7
var factor: float = 0.75
func _ready()->void:target.movement_modifiers[get_instance_id()]=factor
func cancel()->void:
	if is_instance_valid(target):target.movement_modifiers.erase(get_instance_id())
	set_physics_process(false)
	queue_free()
func _physics_process(delta:float)->void:
	remaining-=delta
	if remaining<=0 or not is_instance_valid(target) or target.health.is_dead:cancel()
func _exit_tree()->void:
	if is_instance_valid(target):target.movement_modifiers.erase(get_instance_id())
