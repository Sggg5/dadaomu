class_name HitRelicEffect
extends RelicEffect
## 命中型效果共用连接/局部对象卸载，不选择具体遗物行为。
var _owned: Array[WeakRef] = []


func _on_install() -> void:
	runtime.projectile_hit.connect(_receive_hit)


func _on_uninstall() -> void:
	if runtime.projectile_hit.is_connected(_receive_hit):
		runtime.projectile_hit.disconnect(_receive_hit)
	for reference in _owned:
		var node := reference.get_ref() as Node
		if is_instance_valid(node):
			if node.has_method("cancel"):
				node.call("cancel")
			else:
				node.queue_free()
	_owned.clear()


func own(node: Node) -> void:
	_owned = _owned.filter(func(reference: WeakRef) -> bool: return is_instance_valid(reference.get_ref()))
	_owned.append(weakref(node))


func _receive_hit(context: ProjectileHitContext) -> void:
	if installed and runtime.is_active() and is_instance_valid(runtime.room):
		_on_hit(context)


func _on_hit(_context: ProjectileHitContext) -> void:
	pass
