extends RelicEffect
var attacks: int = 0


func get_attack_stage() -> AttackStage:
	return AttackStage.FINAL


func modify_attack(context: AttackContext) -> void:
	attacks += 1
	if attacks % maxi(1, int(definition.parameters.get("period", 3))) != 0:
		return
	var extra: Array[AttackRequest] = []
	for request in context.requests:
		var spread := float(definition.parameters.get("angle_degrees", 20.0))
		for angle in [-spread, spread]:
			var child := request.copy()
			child.direction = child.direction.rotated(deg_to_rad(angle))
			extra.append(child)
	context.requests.append_array(extra)
