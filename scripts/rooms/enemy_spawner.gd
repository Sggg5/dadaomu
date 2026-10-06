class_name EnemySpawner
extends Node2D
## 每个房间只生成一次。通过 Health.died 追踪存活集合，重复死亡不会重复扣数。
## 任意移除节点不等于死亡；卸载房间时不会错误触发清场。

signal remaining_changed(count: int)
signal all_defeated

var started: bool = false
var _spawning: bool = false
var _failed: bool = false
var _living: Dictionary[int, Node2D] = {}


func spawn(definition: RoomDefinition) -> void:
	if started:
		return
	started = true
	_spawning = true
	for spawn_position in definition.enemy_positions:
		var enemy := definition.enemy_scene.instantiate() as Node2D
		var health := enemy.get_node_or_null("Health") as Health if enemy else null
		if enemy == null or health == null:
			_failed = true
			if enemy:
				enemy.free()
			push_error("Enemy scene requires Node2D and a Health child")
			continue
		var enemy_id := enemy.get_instance_id()
		_living[enemy_id] = enemy
		health.died.connect(_on_enemy_died.bind(enemy_id), CONNECT_ONE_SHOT)
		enemy.position = spawn_position
		add_child(enemy)
	_spawning = false
	remaining_changed.emit(get_remaining())
	_check_finished()


func get_remaining() -> int:
	return _living.size()


func _on_enemy_died(enemy_id: int) -> void:
	if not _living.has(enemy_id):
		return
	_living.erase(enemy_id)
	remaining_changed.emit(get_remaining())
	_check_finished()


func _check_finished() -> void:
	if started and not _spawning and not _failed and _living.is_empty():
		all_defeated.emit()
