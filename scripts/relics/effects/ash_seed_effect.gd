extends HitRelicEffect
func _on_hit(context:ProjectileHitContext)->void:
	if not context.target is Node:return
	if context.target.get_children().any(func(node:Node)->bool:return node is Burn and not node.cancelled):CombatGeometry.radius(runtime.room,context.position,48,3)
