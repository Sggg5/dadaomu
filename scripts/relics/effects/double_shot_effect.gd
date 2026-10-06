extends RelicEffect
## 每个输入仍只有一次冷却；批次展开与 Player 无关。
func modify_attack(context: AttackContext) -> void:
	var expanded: Array[AttackRequest] = []
	var spread := deg_to_rad(float(definition.parameters.get("spread_degrees", 6.0)))
	for request in context.requests:
		for sign_value in [-1.0, 1.0]:
			var child := request.copy()
			child.direction = child.direction.rotated(spread * sign_value)
			expanded.append(child)
	context.requests = expanded
