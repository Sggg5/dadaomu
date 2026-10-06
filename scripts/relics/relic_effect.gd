class_name RelicEffect
extends RefCounted
## 幂等生命周期；具体效果拥有自己的连接并在 _on_uninstall 中断开。
var definition: RelicDefinition
var runtime: RelicRuntime
var installed: bool = false
var install_count: int = 0
var uninstall_count: int = 0


func install(context: RelicRuntime, data: RelicDefinition) -> bool:
	if installed or context == null or not context.is_active() or data == null:
		return false
	runtime = context
	definition = data
	installed = true
	install_count += 1
	_on_install()
	return true


func uninstall() -> bool:
	if not installed:
		return false
	installed = false
	uninstall_count += 1
	_on_uninstall()
	runtime = null
	definition = null
	return true


func modify_attack(_context: AttackContext) -> void:
	pass


func _on_install() -> void:
	pass


func _on_uninstall() -> void:
	pass
