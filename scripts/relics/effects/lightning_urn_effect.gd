extends HitRelicEffect
var hits:int=0
func _on_hit(context:ProjectileHitContext)->void:
	hits+=1
	if hits%4!=0:return
	var count:=0
	for actor in CombatGeometry.targets(runtime.room):
		if actor!=context.target and actor.global_position.distance_to(context.position)<140:
			actor.take_damage(8)
			var pulse:=CombatPulse.new()
			pulse.position=runtime.room.projectiles.to_local(actor.global_position)
			pulse.radius=20
			runtime.room.projectiles.add_child(pulse)
			own(pulse)
			count+=1
			if count>=2:return
