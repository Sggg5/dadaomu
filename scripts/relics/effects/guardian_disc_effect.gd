extends RelicEffect
func get_attack_stage()->AttackStage:return AttackStage.PROJECTILE_PROPERTY
func modify_attack(context:AttackContext)->void:
	for request in context.requests:
		request.orbit_owner=weakref(runtime.health.get_parent())
		request.orbit_time=0.5
