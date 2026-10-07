extends HitRelicEffect
var hits: int = 0
var charge: int = 0
func _on_hit(context: ProjectileHitContext) -> void:
	if context.target is Enemy and context.target.definition is BossDefinition:
		hits += 1
		if hits % 6 == 0: charge = mini(5,charge+1)
func modify_attack(context: AttackContext) -> void:
	if charge == 0: return
	for request in context.requests: request.damage *= 1.0+charge*0.12
	charge = 0
