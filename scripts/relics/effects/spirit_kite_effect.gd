extends RelicEffect
var charged: bool = false


func get_attack_stage() -> AttackStage:
	return AttackStage.DIRECTION


func _on_install() -> void:
	runtime.player_damaged.connect(_charge)


func _on_uninstall() -> void:
	if runtime.player_damaged.is_connected(_charge):
		runtime.player_damaged.disconnect(_charge)
	charged = false


func _charge(_amount: float) -> void:
	charged = true


func modify_attack(context: AttackContext) -> void:
	if not charged or context.requests.is_empty():
		return
	charged = false
	var base := context.requests[0]
	var spread := float(definition.parameters.get("angle_degrees", 15.0))
	for angle in [-spread, spread]:
		var child := base.copy()
		child.direction = child.direction.rotated(deg_to_rad(angle))
		context.requests.append(child)
