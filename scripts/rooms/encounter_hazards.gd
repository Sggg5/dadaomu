class_name EncounterHazards
extends Node2D
## 当前房危险与减速所有者。Room退出/死亡统一取消；有限区域不进入清房计数。
const MAX_TRANSIENT:int=12
const MAX_POISON:int=4
var room:Room
var stopped:bool=false
func _ready()->void:
	if room.room_type!=RoomDefinition.Type.COMBAT:return
	for data in room.environments():create(data)
func create(definition:EncounterHazardDefinition,guard:WeakRef=null)->EncounterHazard:
	if stopped:return null
	var live:=get_children().filter(func(node:Node)->bool:return not node.is_queued_for_deletion())
	if live.size()>=MAX_TRANSIENT:return null
	if definition.kind==EncounterHazardDefinition.Kind.POISON and live.filter(func(node:EncounterHazard)->bool:return node.data.kind==EncounterHazardDefinition.Kind.POISON).size()>=MAX_POISON:return null
	var node:=EncounterHazard.new()
	node.room=room
	node.data=definition.duplicate() as EncounterHazardDefinition
	node.data.damage*=room.difficulty.damage_multiplier
	node.owner_guard=guard
	add_child(node)
	return node
func blast(point:Vector2,delay:float,radius:float,damage:float,guard:WeakRef=null)->EncounterHazard:
	var data:=EncounterHazardDefinition.new()
	data.kind=EncounterHazardDefinition.Kind.BLAST
	data.position=point
	data.warning_time=delay
	data.radius=radius
	data.damage=damage
	data.periodic=false
	data.combat_only=false
	return create(data,guard)
func spill(point:Vector2,damage:float)->EncounterHazard:
	var data:=EncounterHazardDefinition.new()
	data.kind=EncounterHazardDefinition.Kind.POISON
	data.position=point
	data.radius=52
	data.damage=damage
	data.duration=4
	data.periodic=false
	data.combat_only=false
	return create(data)
func ring(point:Vector2,damage:float)->EncounterHazard:
	var data:=EncounterHazardDefinition.new()
	data.kind=EncounterHazardDefinition.Kind.RING
	data.position=point
	data.warning_time=0.4
	data.damage=damage
	data.projectile_speed=180
	data.periodic=false
	data.combat_only=false
	return create(data)
func _physics_process(_delta:float)->void:
	if not is_instance_valid(room.combat_target):return
	var factor:=1.0
	if not stopped and room.room_state.status==RoomState.Status.ACTIVE:
		for node in get_children():
			if node is EncounterHazard and node.data.kind==EncounterHazardDefinition.Kind.WATER and node.position.distance_to(room.combat_target.position)<node.data.radius:factor=0.75
	room.combat_target.environment_speed_multiplier=factor
func danger_at(point:Vector2)->float:
	var danger:=0.0
	for node in get_children():
		if node is EncounterHazard and not node.is_queued_for_deletion() and node.phase!=EncounterHazard.Phase.OFF and node.position.distance_to(point)<node.data.radius+28:danger+=1
	return danger
func stop()->void:
	stopped=true
	for node in get_children():node.set_physics_process(false);node.queue_free()
	if is_instance_valid(room.combat_target):room.combat_target.environment_speed_multiplier=1
func _exit_tree()->void:
	if is_instance_valid(room.combat_target):room.combat_target.environment_speed_multiplier=1
