extends RelicEffect
func modify_attack(context:AttackContext)->void:
	for request in context.requests:
		request.damage*=0.8
		request.cooldown_multiplier/=1.35
