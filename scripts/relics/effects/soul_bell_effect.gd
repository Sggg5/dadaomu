extends RelicEffect
var souls: int = 0
func _on_install() -> void:
	runtime.enemy_killed.connect(_kill)
	runtime.room_cleared.connect(_clear)
func _on_uninstall() -> void:
	runtime.enemy_killed.disconnect(_kill)
	runtime.room_cleared.disconnect(_clear)
func _clear(_context: RoomClearContext) -> void: souls = 0
func _kill(enemy: Node2D) -> void:
	if souls >= 12 or not is_instance_valid(runtime.room): return
	for actor in CombatGeometry.targets(runtime.room):
		if actor == enemy: continue
		souls += 1
		var request := AttackRequest.new()
		request.origin = enemy.global_position
		request.direction = (actor.global_position-request.origin).normalized()
		request.damage = 5
		request.speed = 300
		request.lifetime = 1.5
		request.homing_target = weakref(actor)
		request.homing_turn_rate = 3
		request.tags.append(&"soul")
		runtime.weapon.attack_requested.emit(request)
		return
