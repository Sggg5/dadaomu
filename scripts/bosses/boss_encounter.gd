class_name BossEncounter
extends Node2D
## Boss本体/一次召唤的局部所有者；死亡清召唤物不计额外击杀。
signal defeated
signal enemy_killed(enemy: Node2D)
signal remaining_changed(count: int)
const SCARAB: PackedScene = preload("res://scenes/enemies/scarab_enemy.tscn")
const SCARAB_DATA: EnemyDefinition = preload("res://data/enemies/scarab.tres")
var room: Room
var definition: BossDefinition
var boss: Enemy
var started: bool = false
var finished: bool = false
var stopped:bool=false
var summons: Array[Enemy] = []
var total_summons:int=0
var eggs:Array[BossEgg]=[]


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
	assert(definition != null and definition.boss_scene != null, "Boss requires a configured scene")
	started = true
	boss = definition.boss_scene.instantiate() as Enemy
	assert(boss != null, "Boss scene root must implement Enemy")
	boss.position = safe_point(Room.ROOM_RECT.get_center(), 34, [], 120)
	assert(boss.position.is_finite(), "Boss requires a safe point")
	boss.configure_spawn(room.combat_target, room.projectiles, definition, room.difficulty)
	boss.encounter_room=room
	boss.killed.connect(_on_defeated)
	if boss.has_signal("summon_requested"): boss.connect("summon_requested", _summon)
	add_child(boss)
	remaining_changed.emit(targets().size())


func _summon(count: int) -> void:
	if stopped or finished or not is_instance_valid(boss) or boss.health.is_dead: return
	var alive: Array[Enemy] = []
	for actor in summons:
		if is_instance_valid(actor) and not actor.health.is_dead: alive.append(actor)
	summons = alive
	var cap:int=definition.parameters.get("summon_cap",6)
	if alive.size() >= cap or total_summons>=definition.parameters.get("summon_total",18): return
	var reserved: Array[Vector2] = [boss.position]
	for actor in alive: reserved.append(actor.position)
	for index in range(mini(count,mini(cap-alive.size(),int(definition.parameters.get("summon_total",18))-total_summons))):
		var preferred := boss.position + Vector2.RIGHT.rotated(index * TAU / count) * 110
		var point := safe_point(preferred, 16, reserved, 100)
		if not point.is_finite(): continue
		reserved.append(point)
		var actor := SCARAB.instantiate() as Enemy
		actor.position = point
		var data:EnemyDefinition=SCARAB_DATA
		if definition.parameters.get("weak_summons",false):
			data=SCARAB_DATA.duplicate() as EnemyDefinition
			data.max_hp=22
			data.contact_damage=6
		actor.configure_spawn(room.combat_target, room.projectiles, data, room.difficulty)
		total_summons+=1
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
		if actor is Enemy and not actor.health.is_dead and not actor.is_queued_for_deletion():
			if actor.has_method("combat_targets"):result.append_array(actor.combat_targets())
			else:result.append(actor)
	return result


func stop() -> void:
	stopped=true
	for actor in get_children():
		if actor is Enemy: actor.stop_ai()


func _on_defeated() -> void:
	if finished: return
	finished = true
	stop()
	for actor in summons+eggs:
		if is_instance_valid(actor): actor.queue_free()
	room.discard_projectiles()
	remaining_changed.emit(0)
	enemy_killed.emit(boss)
	defeated.emit()

func create_eggs(count:int,cap:int=4)->void:
	if stopped or finished or not is_instance_valid(boss) or boss.health.is_dead:return
	var alive_eggs:Array[BossEgg]=[]
	for egg in eggs:
		if is_instance_valid(egg) and not egg.health.is_dead:alive_eggs.append(egg)
	eggs=alive_eggs
	cap=clampi(cap,0,4)
	# Phase-specific cap retires excess eggs without kills/rewards or deferred hatch.
	while eggs.size()>cap:
		var extra:BossEgg=eggs.pop_back()
		extra.stop_ai()
		extra.queue_free()
	var reserved:Array[Vector2]=[boss.position]
	for egg in eggs:reserved.append(egg.position)
	for i in range(mini(count,cap-eggs.size())):
		var point:=safe_point(boss.position+Vector2.RIGHT.rotated(i*TAU/maxi(1,count))*130,18,reserved,80)
		if not point.is_finite():continue
		reserved.append(point)
		var egg:=preload("res://scenes/bosses/boss_egg.tscn").instantiate() as BossEgg
		egg.encounter=self
		egg.encounter_room=room
		egg.position=point
		egg.configure_spawn(room.combat_target,room.projectiles,preload("res://data/bosses/egg.tres"),room.difficulty)
		egg.killed.connect(func()->void:
			if not egg.hatched:enemy_killed.emit(egg)
			remaining_changed.emit(targets().size()))
		add_child(egg)
		eggs.append(egg)
	remaining_changed.emit(targets().size())
