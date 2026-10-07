extends HitRelicEffect
func _on_hit(context:ProjectileHitContext)->void:
	if context.hit_count>1 and is_instance_valid(context.target):context.target.take_damage(5)
