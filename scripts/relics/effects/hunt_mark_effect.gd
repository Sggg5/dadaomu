extends RelicEffect
var charged:bool=false
func _on_install()->void:runtime.enemy_killed.connect(_kill)
func _on_uninstall()->void:runtime.enemy_killed.disconnect(_kill)
func _kill(_enemy:Node2D)->void:charged=true
func modify_attack(context:AttackContext)->void:
	if not charged:return
	charged=false
	for request in context.requests:request.damage*=1.35
