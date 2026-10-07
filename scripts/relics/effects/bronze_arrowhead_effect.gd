extends RelicEffect
func get_attack_stage() -> AttackStage: return AttackStage.PROJECTILE_PROPERTY
func modify_attack(context: AttackContext) -> void:
	for request in context.requests:
		request.speed *= 1.5
		request.projectile_scale *= 0.7
		request.pierce_count += 1
