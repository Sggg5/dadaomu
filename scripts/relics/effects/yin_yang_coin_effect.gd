extends RelicEffect
var attacks: int = 0
func modify_attack(context: AttackContext) -> void:
	attacks += 1
	for request in context.requests: request.damage *= 1.35 if attacks % 2 == 0 else 0.85
