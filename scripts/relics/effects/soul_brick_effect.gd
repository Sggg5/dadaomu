extends RelicEffect
func get_attack_stage()->AttackStage:return AttackStage.COUNT
func get_attack_priority()->int:return 100
func modify_attack(context:AttackContext)->void:
	if context.requests.is_empty():return
	context.requests.resize(1)
	var request:=context.requests[0]
	request.damage*=1.7
	request.speed*=0.65
	request.projectile_scale*=2.2
	request.pierce_count+=3
