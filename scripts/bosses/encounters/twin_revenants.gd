extends Enemy
## 两个独立Health，共享总HUD；总死亡一次清场，交替节奏保留逃生窗口。
var members:Array[TwinAvatar]=[]
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
		child.get_node("Health").changed.connect(_member_changed)
		child.cycle_completed.connect(_advance_turn.bind(i))
		child.cycle_started.connect(_support.bind(i))
		child.killed.connect(_member_dead.bind(i))
		members.append(child)
		add_child(child)
func _member_changed(_current:float,_maximum:float)->void:
	var sum:=0.0
	for actor in members:
		if is_instance_valid(actor) and actor.is_node_ready():sum+=actor.health.current_hp
	if members.size()<2 or not members[1].is_node_ready():return
	if sum<=0:health.take_damage(health.current_hp)
	else:health.restore(sum)
func take_damage(_amount:float)->bool:return false
func combat_targets()->Array[Node2D]:
	var result:Array[Node2D]=[]
	for actor in members:
		if is_instance_valid(actor) and not actor.health.is_dead:result.append(actor)
	return result
func _advance_turn(index:int)->void:
	skills_executed+=1
	if combat_targets().size()==1:return
	turn=1-index
	for i in range(members.size()):
		if is_instance_valid(members[i]):members[i].may_attack=i==turn
func _support(index:int)->void:
	cycles+=1
	if members[index]._cycle_combo:combinations+=1
	phase_actions[2 if members[index].solo else 1]=phase_actions.get(2 if members[index].solo else 1,0)+1
	if combat_targets().size()!=2 or cycles%3!=0:return
	# The secondary body adds one delayed area, without entering a second attack windup.
	var partner:=members[1-index]
	partner.zone(BossTelegraph.Shape.CIRCLE,target.global_position,64,1.1,12)
	support_actions+=1
	combinations+=1
func _member_dead(index:int)->void:
	retired_actions+=members[index].skills_executed
	phase_skip_count+=members[index].phase_skip_count
	phases_seen[2]=true
	var survivor:=members[1-index]
	if is_instance_valid(survivor) and not survivor.health.is_dead:survivor.solo=true;survivor.may_attack=true
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
