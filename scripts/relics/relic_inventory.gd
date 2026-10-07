class_name RelicInventory
extends RefCounted
## 单局唯一遗物；按稳定 ID 排序处理效果，安装顺序不决定组合结果。
signal changed
var _runtime: RelicRuntime
var _effects: Dictionary[StringName, RelicEffect] = {}


func _init(context: RelicRuntime) -> void:
	_runtime = context


func add(definition: RelicDefinition) -> bool:
	if not _runtime.is_active() or definition == null or definition.id == &"" or has(definition.id) or definition.effect_script == null:
		return false
	if not definition.effect_script.can_instantiate() or definition.effect_script.get_instance_base_type() != &"RefCounted":
		return false
	var effect := definition.effect_script.new() as RelicEffect
	if effect == null or not effect.install(_runtime, definition):
		return false
	_effects[definition.id] = effect
	changed.emit()
	return true


func has(id: StringName) -> bool:
	return _effects.has(id)


func get_effect(id: StringName) -> RelicEffect:
	return _effects.get(id)


func ids() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(_effects.keys())
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return str(a) < str(b))
	return result


func remove(id: StringName) -> bool:
	if not has(id):
		return false
	var effect := _effects[id]
	_effects.erase(id)
	effect.uninstall()
	changed.emit()
	return true


func clear() -> void:
	for id in ids():
		remove(id)


func modify_attack(context: AttackContext) -> void:
	for id in attack_order():
		var effect := get_effect(id)
		if effect != null and effect.installed:
			effect.modify_attack(context)
			if context.requests.size() > AttackContext.MAX_PROJECTILES: context.requests.resize(AttackContext.MAX_PROJECTILES)


func attack_order() -> Array[StringName]:
	var result := ids()
	result.sort_custom(func(a: StringName, b: StringName) -> bool:
		var left := get_effect(a)
		var right := get_effect(b)
		if left.get_attack_stage() != right.get_attack_stage():
			return left.get_attack_stage() < right.get_attack_stage()
		if left.get_attack_priority() != right.get_attack_priority():
			return left.get_attack_priority() < right.get_attack_priority()
		return str(a) < str(b))
	return result
