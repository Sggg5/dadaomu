extends HitRelicEffect
var explosions: int = 0


func _on_hit(context: ProjectileHitContext) -> void:
	explosions += 1
	var radius := float(definition.parameters.get("radius", 72.0))
	CombatGeometry.radius(runtime.room, context.position, radius, context.damage * float(definition.parameters.get("damage_multiplier", 0.5)))
	var pulse := CombatPulse.new()
	pulse.position = runtime.room.projectiles.to_local(context.position)
	pulse.radius = radius
	runtime.room.projectiles.add_child(pulse)
	own(pulse)
