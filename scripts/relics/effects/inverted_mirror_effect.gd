extends RelicEffect
func get_attack_stage()->AttackStage:return AttackStage.FINAL
func get_attack_priority()->int:return 100
func modify_attack(context:AttackContext)->void:
	if context.requests.is_empty():return
	for request in context.requests:request.damage*=0.85
	var back:=context.requests[0].copy()
	back.direction=-back.direction
	back.damage*=0.65
	context.requests.append(back)
