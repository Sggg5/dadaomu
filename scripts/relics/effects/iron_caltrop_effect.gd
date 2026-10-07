extends RelicEffect
func get_attack_stage() -> AttackStage: return AttackStage.PROJECTILE_PROPERTY
func modify_attack(context: AttackContext) -> void:
	for request in context.requests:
		request.projectile_scale *= 1.6
		request.speed *= 0.75
		request.pierce_count += 2
		request.tags.append(&"heavy")
