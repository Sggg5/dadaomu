extends RelicEffect
var attacks: int = 0


func get_attack_stage() -> AttackStage:
	return AttackStage.FINAL


func get_attack_priority() -> int:
	return 10


func modify_attack(context: AttackContext) -> void:
	attacks += 1
	if attacks % maxi(1, int(definition.parameters.get("period", 5))) != 0 or context.requests.is_empty():
		return
	var heavy := context.requests[0].copy()
	heavy.damage *= float(definition.parameters.get("damage_multiplier", 2.2))
	heavy.speed *= float(definition.parameters.get("speed_multiplier", 1.3))
	heavy.lifetime = float(definition.parameters.get("lifetime", 0.22))
	heavy.projectile_scale *= float(definition.parameters.get("scale", 1.8))
	heavy.tags.append(&"heavy")
	context.requests.append(heavy)
