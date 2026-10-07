extends HitRelicEffect
func _on_hit(context: ProjectileHitContext) -> void:
	if context.origin.distance_to(context.position) <= 160 and is_instance_valid(context.target): context.target.take_damage(context.damage*0.25)
