extends RelicEffect
func modify_attack(context:AttackContext)->void:
	if runtime.health.current_hp>=40:return
	for request in context.requests:request.damage*=1.45
