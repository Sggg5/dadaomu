extends RelicEffect
func get_attack_stage() -> AttackStage: return AttackStage.COUNT
func modify_attack(context: AttackContext) -> void:
	if context.requests.is_empty(): return
	for request in context.requests: request.damage *= 0.85
	var extra := context.requests[0].copy()
	extra.direction = extra.direction.rotated(0.08)
	context.requests.append(extra)
