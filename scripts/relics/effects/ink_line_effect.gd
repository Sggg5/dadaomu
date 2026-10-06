extends HitRelicEffect
var sweeps: int = 0


func _on_hit(context: ProjectileHitContext) -> void:
	sweeps += 1
	CombatGeometry.line(runtime.room, context.origin, context.position, float(definition.parameters.get("width", 24.0)), float(definition.parameters.get("damage", 6.0)), context.target)
	var pulse := CombatPulse.new()
	pulse.position = runtime.room.projectiles.to_local(context.origin)
	pulse.end = context.position - context.origin
	pulse.remaining = float(definition.parameters.get("duration", 0.3))
	runtime.room.projectiles.add_child(pulse)
	own(pulse)
