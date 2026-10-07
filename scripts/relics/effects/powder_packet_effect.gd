extends HitRelicEffect
func get_attack_stage() -> AttackStage: return AttackStage.PROJECTILE_PROPERTY
func modify_attack(context: AttackContext) -> void:
	for request in context.requests: request.speed *= 0.8
func _on_hit(context: ProjectileHitContext) -> void:
	CombatGeometry.radius(runtime.room,context.position,105,context.damage*0.25)
	var pulse := CombatPulse.new()
	pulse.position = runtime.room.projectiles.to_local(context.position)
	pulse.radius = 105
	runtime.room.projectiles.add_child(pulse)
	own(pulse)
