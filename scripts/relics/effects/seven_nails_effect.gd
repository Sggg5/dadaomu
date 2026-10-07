extends RelicEffect
var attacks: int = 0
func get_attack_stage() -> AttackStage: return AttackStage.FINAL
func modify_attack(context: AttackContext) -> void:
	attacks += 1
	if attacks % 5 != 0 or context.requests.is_empty(): return
	for i in range(5):
		var extra := context.requests[0].copy()
		extra.direction = extra.direction.rotated((i-2)*0.2)
		extra.damage *= 0.5
		context.requests.append(extra)
