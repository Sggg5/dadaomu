class_name EnemySpawner
extends Node2D
## 每个房间只生成一次。通过 Health.died 追踪存活集合，重复死亡不会重复扣数。
## 任意移除节点不等于死亡；卸载房间时不会错误触发清场。

signal remaining_changed(count: int)
signal all_defeated
signal enemy_killed(enemy: Node2D)

var started: bool = false
var target: Player
var difficulty: EncounterDifficulty = EncounterDifficulty.from_depth(0)
var projectile_parent: Node2D
var _summon_owners: Dictionary[int,int] = {}
const MAX_SUMMONS: int = 4
const MAX_TOTAL_SUMMONS: int = 8
var summons_created: int = 0
var pending_births:int=0
var death_births:int=0
var stopped:bool=false
var _spawning: bool = false
var _failed: bool = false
var _finished: bool = false
var _living: Dictionary[int, Node2D] = {}


func spawn(definition: RoomDefinition) -> void:
	if started:
		return
	started = true
	_spawning = true
	for entry in definition.spawns:
		if entry == null or entry.enemy_scene == null:
			_failed = true
			push_error("Invalid EnemySpawnDefinition")
			continue
		var enemy := entry.enemy_scene.instantiate() as Node2D
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
		enemy.position = entry.position
		if enemy is Enemy:
			enemy.configure_spawn(target, projectile_parent, entry.enemy_definition, difficulty)
			enemy.activation_remaining = definition.entry_grace_time
			enemy.encounter_room = get_parent() as Room
		if enemy.has_signal("summon_requested"): enemy.connect("summon_requested",_request_summon.bind(enemy))
		add_child(enemy)
	_spawning = false
	remaining_changed.emit(get_remaining())
	_check_finished()


func get_remaining() -> int:
	return _living.size()+pending_births


func stop_all(cancel_encounter: bool = false) -> void:
	stopped=cancel_encounter
	for child in get_children():
		if child is Enemy:
			child.stop_ai()


func _on_enemy_died(enemy_id: int) -> void:
	if not _living.has(enemy_id):
		return
	var enemy := _living[enemy_id]
	if enemy is Enemy and not stopped:
		var records:Array[EnemySpawnDefinition]=enemy.death_spawns()
		if not records.is_empty():
			pending_births+=records.size()
			_spawn_death_records.call_deferred(records)
	_living.erase(enemy_id)
	_summon_owners.erase(enemy_id)
	enemy_killed.emit(enemy)
	remaining_changed.emit(get_remaining())
	_check_finished()


func _check_finished() -> void:
	if started and not _spawning and not _failed and not _finished and not stopped and pending_births==0 and _living.is_empty():
		_finished = true
		all_defeated.emit()


func _request_summon(count: int, owner: Enemy) -> void:
	_spawn_summons.call_deferred(count,weakref(owner))

func _spawn_summons(count: int, reference: WeakRef) -> void:
	var owner := reference.get_ref() as Enemy
	if not is_instance_valid(owner) or owner.health.is_dead or not owner.can_act() or _finished: return
	var owner_id := owner.get_instance_id()
	for index in range(mini(count,2)):
		var live_count := 0
		for id in _summon_owners:
			if _living.has(id): live_count+=1
		if live_count>=MAX_SUMMONS or summons_created>=MAX_TOTAL_SUMMONS: return
		var own_count := 0
		for id in _summon_owners:
			if _living.has(id) and _summon_owners[id]==owner_id: own_count+=1
		if own_count>=2: return
		var point := Vector2.INF
		for y in range(224,520,72):
			for x in range(280,1080,80):
				var candidate := Vector2(x,y)
				if candidate.distance_to(target.position)<180: continue
				var room := get_parent() as Room
				if room.definition.obstacles.any(func(rect: Rect2) -> bool: return rect.grow(18).has_point(candidate)): continue
				var near_entry := false
				for side in range(4):
					if room.get_entry_position(side).distance_to(candidate)<180: near_entry=true
				if near_entry: continue
				if _living.values().any(func(actor: Node2D) -> bool: return actor.position.distance_to(candidate)<48): continue
				var ray := PhysicsRayQueryParameters2D.create(candidate,candidate+Vector2(1,0),1)
				if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
				point=candidate
				break
			if point.is_finite(): break
		if not point.is_finite(): return
		var actor := preload("res://scenes/enemies/scarab_enemy.tscn").instantiate() as Enemy
		actor.position=point
		actor.configure_spawn(target,projectile_parent,preload("res://data/enemies/scarab.tres"),difficulty)
		actor.activation_remaining=0.35
		actor.encounter_room=get_parent() as Room
		var id := actor.get_instance_id()
		_living[id]=actor
		_summon_owners[id]=owner_id
		summons_created+=1
		(actor.get_node("Health") as Health).died.connect(_on_enemy_died.bind(id),CONNECT_ONE_SHOT)
		add_child(actor)
	remaining_changed.emit(get_remaining())


func _spawn_death_records(records:Array[EnemySpawnDefinition])->void:
	if stopped or not is_inside_tree() or target.health.is_dead:
		pending_births=maxi(0,pending_births-records.size())
		return
	var room:=get_parent() as Room
	for record in records:
		pending_births-=1
		if death_births>=24:continue
		var reserved:Array[Vector2]=[]
		for actor in _living.values():reserved.append(actor.position)
		var preferred:=record.position
		var point:=EncounterGeometry.safe_point(room,preferred,24,80)
		if not point.is_finite():continue
		# 已占点则用有限横移候选，避免两个子体重叠。
		for offset in [Vector2.ZERO,Vector2(48,0),Vector2(-48,0),Vector2(0,48)]:
			var candidate:=EncounterGeometry.safe_point(room,point+offset,24,80)
			if candidate.is_finite() and reserved.all(func(other:Vector2)->bool:return other.distance_to(candidate)>=40):point=candidate;break
		var actor:=record.enemy_scene.instantiate() as Enemy
		actor.position=point
		actor.configure_spawn(target,projectile_parent,record.enemy_definition,difficulty)
		actor.encounter_room=room
		actor.activation_remaining=0.35
		var id:=actor.get_instance_id()
		_living[id]=actor
		death_births+=1
		(actor.get_node("Health") as Health).died.connect(_on_enemy_died.bind(id),CONNECT_ONE_SHOT)
		add_child(actor)
	remaining_changed.emit(get_remaining())
	_check_finished()
