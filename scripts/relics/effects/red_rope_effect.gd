extends RelicEffect
var attacks: int = 0
func get_attack_stage() -> AttackStage: return AttackStage.FINAL
func modify_attack(context: AttackContext) -> void:
	attacks += 1
	if attacks % 6 != 0 or context.requests.is_empty(): return
	for i in range(8):
		var extra := context.requests[0].copy()
		extra.direction = Vector2.RIGHT.rotated(i*TAU/8)
		extra.damage *= 0.45
		context.requests.append(extra)
