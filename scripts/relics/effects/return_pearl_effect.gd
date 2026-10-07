extends RelicEffect
func get_attack_stage()->AttackStage:return AttackStage.PROJECTILE_PROPERTY
func modify_attack(context:AttackContext)->void:
	for request in context.requests:request.bounce_count+=1
