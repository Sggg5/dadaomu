extends RelicEffect
func get_attack_stage()->AttackStage:return AttackStage.PROJECTILE_PROPERTY
func modify_attack(context:AttackContext)->void:
	var actors:=CombatGeometry.targets(runtime.room)
	if actors.is_empty():return
	for request in context.requests:
		var nearest:Node2D=actors[0]
		for actor in actors:
			if actor.global_position.distance_to(request.origin)<nearest.global_position.distance_to(request.origin):nearest=actor
		request.homing_target=weakref(nearest)
		request.homing_turn_rate=1.2
		request.damage*=0.85
