extends HitRelicEffect
var _burns: Dictionary[int, WeakRef] = {}


func _on_hit(context: ProjectileHitContext) -> void:
	if not is_instance_valid(context.target) or not context.target is Node2D:
		return
	var target := context.target as Node2D
	var health := target.get_node_or_null("Health") as Health
	if health == null or health.is_dead:
		return
	var id := target.get_instance_id()
	var existing: Burn = _burns[id].get_ref() as Burn if _burns.has(id) else null
	if is_instance_valid(existing) and not existing.cancelled:
		existing.refresh()
		return
	var burn := Burn.new()
	burn.runtime = runtime
	burn.target = target
	burn.damage = float(definition.parameters.get("damage", 3.0))
	burn.interval = float(definition.parameters.get("interval", 0.35))
	burn.max_ticks = int(definition.parameters.get("ticks", 3))
	burn.refresh()
	target.add_child(burn)
	_burns[id] = weakref(burn)
	own(burn)
	for old_id in _burns.keys():
		if not is_instance_valid(_burns[old_id].get_ref()):
			_burns.erase(old_id)


func _on_uninstall() -> void:
	super._on_uninstall()
	_burns.clear()
