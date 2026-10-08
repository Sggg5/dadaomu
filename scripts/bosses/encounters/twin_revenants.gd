extends Enemy
## 两个独立Health，共享总HUD；总死亡一次清场，交替节奏保留逃生窗口。
var members:Array[TwinAvatar]=[]
# Fixed slots survive queue_free. Only observed Health/killed signals establish death.
var member_initialized:Array[bool]=[false,false]
var member_dead:Array[bool]=[false,false]
var member_retired:Array[bool]=[false,false]
var initializing:bool=true
var turn:int=0
var skills_executed:int=0
var cycles:int=0
var combinations:int=0
var support_actions:int=0
var retired_actions:int=0
var phase_skip_count:int=0
var phase_actions:Dictionary={}
var phases_seen:Dictionary={1:true}
func _ready()->void:
	super._ready()
	collision_layer=0
	collision_mask=0
	var reserved:Array[Vector2]=[]
	for i in range(2):
		var child:=preload("res://scenes/bosses/twin_avatar.tscn").instantiate() as TwinAvatar
		var data:=definition.duplicate() as BossDefinition
		data.max_hp=definition.max_hp*0.5
		data.display_name="阴尸" if i==1 else "阳尸"
		child.ranged=i==1
		var point:=encounter_room.boss_encounter.safe_point(position+Vector2(-100 if i==0 else 100,0),child.body_radius(),reserved,80)
		assert(point.is_finite(),"Twin bodies need legal distinct positions")
		reserved.append(point)
		child.position=to_local(encounter_room.to_global(point))
		child.encounter_room=encounter_room
		child.configure_spawn(target,projectile_parent,data,difficulty)
		child.may_attack=i==0
		child.get_node("Health").changed.connect(_member_changed.bind(i))
		child.cycle_completed.connect(_advance_turn.bind(i))
		child.cycle_started.connect(_support.bind(i))
		child.killed.connect(_member_dead.bind(i))
		members.append(child)
		add_child(child)
	initializing=false
	_sync_health()
func _member_changed(current:float,_maximum:float,index:int)->void:
	member_initialized[index]=true
	# changed precedes died/killed synchronously; record zero before final settlement.
	if current<=0:member_dead[index]=true
	_sync_health()
func _living(index:int)->bool:
	return index>=0 and index<members.size() and member_initialized[index] and not member_dead[index] and is_instance_valid(members[index]) and not members[index].health.is_dead
func _sync_health()->void:
	if initializing or not member_initialized[0] or not member_initialized[1] or health.is_dead:return
	var sum:=0.0
	for index in range(2):
		if member_dead[index]:continue
		# Unexpected removal is not proof of death; never award a clear for it.
		if not is_instance_valid(members[index]):return
		sum+=members[index].health.current_hp
	if member_dead[0] and member_dead[1]:health.take_damage(health.current_hp)
	else:health.restore(sum)
func take_damage(_amount:float)->bool:return false
func combat_targets()->Array[Node2D]:
	var result:Array[Node2D]=[]
	for index in range(members.size()):
		if _living(index):result.append(members[index])
	return result
func _advance_turn(index:int)->void:
	if not _living(index):return
	skills_executed+=1
	if combat_targets().size()==1:return
	turn=1-index
	for i in range(members.size()):
		if _living(i):members[i].may_attack=i==turn
func _support(index:int)->void:
	if not _living(index):return
	cycles+=1
	if members[index]._cycle_combo:combinations+=1
	phase_actions[2 if members[index].solo else 1]=phase_actions.get(2 if members[index].solo else 1,0)+1
	if combat_targets().size()!=2 or cycles%3!=0:return
	# The secondary body adds one delayed area, without entering a second attack windup.
	if not _living(1-index):return
	var partner:=members[1-index]
	partner.zone(BossTelegraph.Shape.CIRCLE,target.global_position,64,1.1,12)
	support_actions+=1
	combinations+=1
func _member_dead(index:int)->void:
	if index<0 or index>=members.size() or member_retired[index] or not is_instance_valid(members[index]):return
	member_retired[index]=true
	member_dead[index]=true
	retired_actions+=members[index].skills_executed
	phase_skip_count+=members[index].phase_skip_count
	phases_seen[2]=true
	var survivor:=members[1-index]
	if _living(1-index):
		turn=1-index
		survivor.solo=true
		survivor.may_attack=true
	_sync_health()
func _tick_ai(_delta:float)->void:
	velocity=Vector2.ZERO
	skills_executed=retired_actions
	for actor in members:
		if is_instance_valid(actor) and not actor.health.is_dead:skills_executed+=actor.skills_executed
func stop_ai()->void:
	super.stop_ai()
	for actor in members:
		if is_instance_valid(actor):actor.stop_ai()
func _draw_body(_color:Color)->void:pass
