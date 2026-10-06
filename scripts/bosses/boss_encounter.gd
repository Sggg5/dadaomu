class_name BossEncounter
extends Node2D
## Boss本体/一次召唤的局部所有者；死亡清召唤物不计额外击杀。
signal defeated
signal enemy_killed(enemy: Node2D)
signal remaining_changed(count: int)
const BOSS: PackedScene = preload("res://scenes/enemies/warlord_boss.tscn")
const SCARAB: PackedScene = preload("res://scenes/enemies/scarab_enemy.tscn")
const SCARAB_DATA: EnemyDefinition = preload("res://data/enemies/scarab.tres")
var room: Room
var definition: BossDefinition
var boss: WarlordBoss
var started: bool = false
var finished: bool = false
var summons: Array[Enemy] = []


func safe_point(preferred: Vector2, radius: float, reserved: Array[Vector2], distance: float) -> Vector2:
	var candidates: Array[Vector2] = [preferred]
	for y in range(192, 552, 48):
		for x in range(160, 1150, 48): candidates.append(Vector2(x,y))
	candidates.sort_custom(func(a: Vector2,b: Vector2) -> bool: return a.distance_squared_to(preferred) < b.distance_squared_to(preferred))
	for point in candidates:
		if not Room.ROOM_RECT.grow(-radius).has_point(point): continue
		if point.distance_to(room.combat_target.position) < distance: continue
		if room.definition.obstacles.any(func(rect: Rect2) -> bool: return rect.grow(radius + 2).has_point(point)): continue
		if reserved.any(func(other: Vector2) -> bool: return point.distance_to(other) < radius * 2 + 20): continue
		return point
	return Vector2.INF


func start() -> void:
	if started: return
	started = true
	boss = BOSS.instantiate() as WarlordBoss
	boss.position = safe_point(Room.ROOM_RECT.get_center(), 34, [], 120)
	assert(boss.position.is_finite(), "Boss requires a safe point")
	boss.configure_spawn(room.combat_target, room.projectiles, definition, room.difficulty)
	boss.killed.connect(_on_defeated)
	boss.summon_requested.connect(_summon)
	add_child(boss)
	remaining_changed.emit(targets().size())


func _summon(count: int) -> void:
	var reserved: Array[Vector2] = [boss.position]
	for index in range(count):
		var preferred := boss.position + Vector2.RIGHT.rotated(index * TAU / count) * 110
		var point := safe_point(preferred, 16, reserved, 100)
		if not point.is_finite(): continue
		reserved.append(point)
		var actor := SCARAB.instantiate() as Enemy
		actor.position = point
		actor.configure_spawn(room.combat_target, room.projectiles, SCARAB_DATA, room.difficulty)
		actor.activation_remaining = 0.35
		actor.killed.connect(func() -> void:
			enemy_killed.emit(actor)
			remaining_changed.emit(targets().size()))
		add_child(actor)
		summons.append(actor)
	remaining_changed.emit(targets().size())


func targets() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for actor in get_children():
		if actor is Enemy and not actor.health.is_dead and not actor.is_queued_for_deletion(): result.append(actor)
	return result


func stop() -> void:
	for actor in get_children():
		if actor is Enemy: actor.stop_ai()


func _on_defeated() -> void:
	if finished: return
	finished = true
	stop()
	for actor in summons:
		if is_instance_valid(actor): actor.queue_free()
	room.discard_projectiles()
	remaining_changed.emit(0)
	enemy_killed.emit(boss)
	defeated.emit()
