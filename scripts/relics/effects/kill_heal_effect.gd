extends RelicEffect
## Spawner 只通知实际存活集合里的首次死亡；效果不持有已死敌人的引用。
var triggers: int = 0


func _on_install() -> void:
	runtime.enemy_killed.connect(_on_enemy_killed)


func _on_uninstall() -> void:
	if runtime.enemy_killed.is_connected(_on_enemy_killed):
		runtime.enemy_killed.disconnect(_on_enemy_killed)


func _on_enemy_killed(_enemy: Node2D) -> void:
	if installed and runtime.is_active():
		triggers += 1
		runtime.health.heal(float(definition.parameters.get("heal_amount", 5.0)))
