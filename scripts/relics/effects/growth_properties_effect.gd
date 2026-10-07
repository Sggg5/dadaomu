extends RelicEffect
## 只修饰本次攻击快照和实例移动倍率；共享PlayerStats/Definition保持只读。
func get_attack_stage()->AttackStage:return AttackStage.PROJECTILE_PROPERTY
func modify_attack(context:AttackContext)->void:
	for request in context.requests:
		request.cooldown_multiplier*=float(definition.parameters.get("cooldown",1.0))
		request.speed*=float(definition.parameters.get("speed",1.0))
		request.lifetime*=float(definition.parameters.get("lifetime",1.0))
func movement_multiplier()->float:return float(definition.parameters.get("movement",1.0))
