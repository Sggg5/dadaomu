class_name MechanismBoss
extends Enemy
## 共享有限技能执行器。子类决定阶段/决策/组合；不读取Build或奖励，不用全局RNG。
signal summon_requested(count:int)
signal cycle_completed
signal cycle_started
var phase_index:int=1
var phases_seen:Dictionary={1:true}
var phase_actions:Dictionary={}
var skills_executed:int=0
var skill_history:Array[StringName]=[]
var combinations:int=0
var cycles:int=0
var phase_thresholds:Array[float]=[0.5]
var may_attack:bool=true
var state:StringName=&"INTRO"
var timer:float=1.0
var current:Dictionary={}
var pending:Array=[]
var locked:Vector2
var endpoint:Vector2
var dash_hit:bool=false
var wall_hit:bool=false
var path_points:PackedVector2Array=[]
var path_time:float=0
var dash_origin:Vector2
var owned:Array[WeakRef]=[]
var cycle_history:Array[bool]=[]
var pressure_cycles:int=0
var _cycle_combo:bool=false
var transition_remaining:float=0
var transition_count:int=0
var phase_skip_count:int=0
## Recent cycles belong to this actor, independent of Player Build and global randomness.
func pressure_due()->bool:
	return cycle_history.size()>=3 and not cycle_history.slice(-3).has(true)
func recovery_duration()->float:
	var data:=definition as BossDefinition
	return data.combo_recovery_time if _cycle_combo else data.boss_recovery_time
func take_damage(amount:float)->bool:
	var accepted:=super.take_damage(amount*0.5 if transition_remaining>0 else amount)
	if accepted and not health.is_dead:_update_phase()
	return accepted
func _update_phase()->void:
	var next:=1
	for threshold in phase_thresholds:
		if health.current_hp/health.max_hp<=threshold:next+=1
	if next<=phase_index:return
	phase_skip_count+=maxi(0,next-phase_index-1)
	phase_index=next
	phases_seen[next]=true
	transition_count+=1
	transition_remaining=0.4
	# Discard in-flight warnings and dash plans together, so an expired warning never resumes damage.
	for ref in owned:
		var node:=ref.get_ref() as Node
		if is_instance_valid(node):node.queue_free()
	owned.clear()
	pending.clear()
	state=&"TRANSITION"
	timer=0.5
	telegraphing=false
	velocity=Vector2.ZERO
func action(kind:StringName,warning:float=0.8,damage:float=14,args:Dictionary={})->Dictionary:
	var value:Dictionary={"kind":kind,"warning":warning,"damage":damage}
	value.merge(args,true)
	return value
func choose_actions(_distance:float)->Array:return [action(&"FAN")]
func _tick_ai(delta:float)->void:
	transition_remaining=maxf(0,transition_remaining-delta)
	_update_phase()
	timer-=delta
	match state:
		&"TRANSITION":
			if timer<=0:state=&"RECOVERY";timer=0.05
		&"INTRO",&"RECOVERY":
			velocity=Vector2.ZERO
			if timer<=0 and may_attack:
				pending=choose_actions(global_position.distance_to(target.global_position))
				cycles+=1
				_cycle_combo=pending.size()>1
				if _cycle_combo:combinations+=1;pressure_cycles+=1
				cycle_history.append(_cycle_combo)
				if cycle_history.size()>8:cycle_history.pop_front()
				cycle_started.emit()
				_next_action()
		&"WINDUP":
			velocity=Vector2.ZERO
			if timer<=0:_execute()
		&"DASH":_dash(delta)
		&"WAIT":
			if timer<=0:_next_action()
func _next_action()->void:
	if pending.is_empty():
		state=&"RECOVERY"
		timer=recovery_duration()
		telegraphing=false
		velocity=Vector2.ZERO
		cycle_completed.emit()
		return
	current=pending.pop_front()
	state=&"WINDUP"
	telegraphing=true
	timer=current.get("warning",0.8)
	locked=(target.global_position-global_position).normalized()
	endpoint=target.global_position
	var kind:StringName=current.kind
	if kind in [&"CIRCLE",&"HANDS",&"SPIKES",&"ROCKS"]:
		var count:int=current.get("count",3)
		for i in range(count):
			var offset:=Vector2.ZERO
			if current.get("sides",false):offset=Vector2.RIGHT.rotated(i*TAU/count)*float(current.get("spread",90))
			elif i>0:offset=Vector2.RIGHT.rotated((i-1)*TAU/maxi(1,count-1))*float(current.get("spread",90))
			var preferred:=encounter_room.to_local(global_position if current.get("centered",false) else endpoint)+offset
			var point:=EncounterGeometry.safe_point(encounter_room,preferred,60)
			if point.is_finite():zone(BossTelegraph.Shape.CIRCLE,encounter_room.to_global(point),current.get("radius",64),timer,current.damage)
	elif kind in [&"LINE",&"SLAM",&"SWEEP",&"HOOK"]:
		var shape:=BossTelegraph.Shape.SECTOR if kind==&"SWEEP" else BossTelegraph.Shape.RECT
		var node:=zone(shape,global_position,current.get("radius",170),timer,current.damage)
		node.direction=locked
		node.length=current.get("length",360)
		node.width=current.get("width",64)
		node.slow=kind==&"HOOK"
	elif kind in [&"CHARGE",&"POUNCE",&"CURVE"]:
		var node:=zone(BossTelegraph.Shape.PATH,global_position,0,timer,0)
		var extent:float=current.get("extent",float(current.get("speed",650))*float(current.get("duration",0.45)))
		if kind==&"POUNCE":
			var point:=EncounterGeometry.safe_point(encounter_room,encounter_room.to_local(endpoint),maxf(70,body_radius()+12))
			endpoint=encounter_room.to_global(point) if point.is_finite() else global_position
			extent=global_position.distance_to(endpoint)
			locked=(endpoint-global_position).normalized()
			zone(BossTelegraph.Shape.CIRCLE,endpoint,maxf(70,body_radius()*1.9),timer,0,float(current.get("duration",0.5))+0.1)
		path_points=[]
		for i in range(25):
			var t:=i/24.0
			var point:=locked*extent*t
			if kind==&"CURVE":point+=locked.orthogonal()*sin(t*TAU)*60
			path_points.append(point)
		node.path=path_points
		node.width=maxf(50,body_radius()*2)
	else:
		var node:=zone(BossTelegraph.Shape.SECTOR,global_position,180,timer,0)
		node.direction=locked
func zone(shape:BossTelegraph.Shape,point:Vector2,radius:float,warning:float,damage:float,duration:float=0.25)->BossTelegraph:
	if shape in [BossTelegraph.Shape.CIRCLE,BossTelegraph.Shape.RECT]:
		var legal:=EncounterGeometry.safe_point(encounter_room,encounter_room.to_local(point),24)
		assert(legal.is_finite(),"Boss danger zone requires legal Arena space")
		point=encounter_room.to_global(legal)
	owned=owned.filter(func(ref:WeakRef)->bool:return is_instance_valid(ref.get_ref()))
	if owned.size()>=32:
		var oldest:=owned.pop_front().get_ref() as Node
		if is_instance_valid(oldest):oldest.queue_free()
	var node:=BossTelegraph.new()
	node.actor=weakref(self)
	node.player=target
	node.shape=shape
	node.radius=radius
	node.warning=warning
	node.duration=duration
	node.damage=scaled_damage(damage)
	encounter_room.add_child(node)
	node.global_position=point
	owned.append(weakref(node))
	return node
func _execute()->void:
	telegraphing=false
	skills_executed+=1
	phase_actions[phase_index]=phase_actions.get(phase_index,0)+1
	skill_history.append(current.kind)
	var kind:StringName=current.kind
	match kind:
		&"FAN",&"BURST":EnemyVolley.fire(self,locked,current.get("count",5),current.get("spread",0.2),current.damage,current.get("speed",300))
		&"RING",&"ROTATE":
			for i in range(10):EnemyVolley.fire(self,Vector2.RIGHT.rotated(i*TAU/10+cycles*0.15),1,0,current.damage,190)
		&"SUMMON":summon_requested.emit(current.get("count",2))
		&"EGGS":
			if encounter_room.boss_encounter!=null:encounter_room.boss_encounter.create_eggs(current.get("count",3),current.get("egg_cap",4))
		&"BARRIER":
			for i in [-1,1]:
				var point:=encounter_room.to_global(Vector2(640+i*160,220))
				var node:=zone(BossTelegraph.Shape.RECT,point,0,0.8,10,3)
				node.direction=Vector2.DOWN
				node.length=290
				node.width=24
		&"CHARGE",&"POUNCE",&"CURVE":
			state=&"DASH"
			timer=current.get("duration",0.45)
			path_time=0
			dash_origin=global_position
			dash_hit=false
			wall_hit=false
			return
	_on_skill_finished(kind)
	state=&"WAIT"
	timer=current.get("gap",0.35)
func _dash(delta:float)->void:
	var duration:float=current.get("duration",0.45)
	var speed:float=current.get("speed",650)
	var movement:=locked*speed*delta
	if current.kind==&"POUNCE":
		var offset:=endpoint-global_position
		movement=offset.normalized()*minf(offset.length(),dash_origin.distance_to(endpoint)/duration*delta)
	if current.kind==&"CURVE":
		path_time+=delta
		var progress:=clampf(path_time/duration*24,0,24)
		var index:=mini(23,int(progress))
		var next:=path_points[index].lerp(path_points[index+1],progress-index)
		movement=dash_origin+next-global_position
	var collision:=move_and_collide(movement)
	if collision:
		var collider:=collision.get_collider() as CollisionObject2D
		wall_hit=collider!=null and (collider.collision_layer&1)!=0
		if collider==target and not dash_hit:target.take_damage(scaled_damage(current.damage));dash_hit=true
		_finish_dash()
	elif current.kind==&"POUNCE" and global_position.distance_to(endpoint)<2:_finish_dash()
	elif not dash_hit and global_position.distance_to(target.global_position)<body_radius()+16 and has_line_to_target():
		target.take_damage(scaled_damage(current.damage))
		dash_hit=true
	elif timer<=0:_finish_dash()
func _finish_dash()->void:
	if current.kind==&"POUNCE" and not dash_hit and global_position.distance_to(target.global_position)<maxf(70,body_radius()*1.9) and has_line_to_target():
		target.take_damage(scaled_damage(current.damage))
		dash_hit=true
	_on_skill_finished(current.kind)
	state=&"WAIT"
	timer=current.get("gap",0.35)
	velocity=Vector2.ZERO
func _on_skill_finished(_kind:StringName)->void:pass
func stop_ai()->void:
	super.stop_ai()
	for ref in owned:
		var node:=ref.get_ref() as Node
		if is_instance_valid(node):node.queue_free()
	owned.clear()
func _draw()->void:
	super._draw()
	if state==&"TRANSITION":draw_arc(Vector2.ZERO,48+sin(timer*24)*5,0,TAU,48,Color("ffb749"),5)
func _draw_body(color:Color)->void:
	draw_circle(Vector2.ZERO,body_radius(),color)
	draw_arc(Vector2.ZERO,body_radius()+6,-PI/2,-PI/2+TAU*(health.current_hp/health.max_hp),32,Color("cfa471"),3)
