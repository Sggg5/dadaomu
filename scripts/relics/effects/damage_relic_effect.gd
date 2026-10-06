extends RelicEffect
## 只修改本次攻击快照，卸载无需反向修复共享属性。
func modify_attack(context: AttackContext) -> void:
	for request in context.requests:
		request.damage *= float(definition.parameters.get("multiplier", 1.5))
