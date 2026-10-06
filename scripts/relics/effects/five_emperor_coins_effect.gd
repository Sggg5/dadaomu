extends RelicEffect
func get_attack_stage() -> AttackStage:
	return AttackStage.COUNT


func modify_attack(context: AttackContext) -> void:
	var expanded: Array[AttackRequest] = []
	for request in context.requests:
		var spread := float(definition.parameters.get("angle_degrees", 5.0))
		for angle in [-spread, spread]:
			var child := request.copy()
			child.damage *= float(definition.parameters.get("damage_multiplier", 0.8))
			child.direction = child.direction.rotated(deg_to_rad(angle))
			expanded.append(child)
	context.requests = expanded
