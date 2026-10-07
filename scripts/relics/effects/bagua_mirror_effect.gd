extends RelicEffect
var attacks: int = 0
func get_attack_stage() -> AttackStage: return AttackStage.FINAL
func modify_attack(context: AttackContext) -> void:
	attacks += 1
	if attacks % 4 != 0: return
	var originals := context.requests.duplicate()
	for request: AttackRequest in originals:
		var extra := request.copy()
		extra.direction = -extra.direction
		context.requests.append(extra)
