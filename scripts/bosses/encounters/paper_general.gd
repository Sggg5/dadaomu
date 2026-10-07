extends PaperGeneral
var rotation_time:float=0
var rotation_tick:float=0
var skills_executed:int=0
var phases_seen:Dictionary={1:true}
var skill_history:Array[StringName]=[]
var cycles:int=0
var combinations:int=0
var transition_remaining:float=0
var transition_pause:float=0
var phase_skip_count:int=0
var phase_index:int=1
var phase_actions:Dictionary={}
var preview:WeakRef
func take_damage(amount:float)->bool:
	var accepted:=super.take_damage(amount*0.5 if transition_remaining>0 else amount)
	if accepted and not health.is_dead:_update_phase()
	return accepted
func _update_phase()->void:
	var next:=3 if health.current_hp/health.max_hp<=0.28 else (2 if health.current_hp/health.max_hp<=0.5 else 1)
	if next<=phase_index:return
	phase_skip_count+=maxi(0,next-phase_index-1)
	phase_index=next
	phases_seen[next]=true
	transition_remaining=0.4
	transition_pause=0.5
	winding=false
	telegraphing=false
	timer=0
	if preview!=null:
		var node:=preview.get_ref() as Node
		if is_instance_valid(node):node.queue_free()
func _tick_ai(delta:float)->void:
	transition_remaining=maxf(0,transition_remaining-delta)
	_update_phase()
	if transition_pause>0:
		transition_pause-=delta
		velocity=Vector2.ZERO
		return
	var previous:=volleys
	var was_winding:=winding
	var previous_decoys:=decoys.size()
	super._tick_ai(delta)
	if winding and not was_winding:
		var marker:=BossTelegraph.new()
		marker.actor=weakref(self)
		marker.player=target
		marker.shape=BossTelegraph.Shape.SECTOR
		marker.direction=aim_direction
		marker.radius=190
		marker.warning=0.65
		marker.damage=0
		encounter_room.add_child(marker)
		marker.global_position=global_position
		preview=weakref(marker)
	var ratio:=health.current_hp/health.max_hp
	if rage:phases_seen[2]=true
	if ratio<=0.28:phases_seen[3]=true
	if volleys>previous:
		phase_actions[phase_index]=phase_actions.get(phase_index,0)+1
		cycles+=1
		if rage:combinations+=1
		timer=1.1 if rage else 1.3
		# Keep two fragile decoys present more often, without changing historical PaperGeneral.
		decoys=decoys.filter(func(ref:WeakRef)->bool:return is_instance_valid(ref.get_ref()))
		if decoys.is_empty():
			for side in [-1,1]:
				var fake:=PaperDecoy.new()
				fake.owner_boss=self
				fake.position=Vector2(side*90,0)
				add_child(fake)
				decoys.append(weakref(fake))
		skills_executed+=1
		skill_history.append(&"FAN")
		if rage:skills_executed+=1;skill_history.append(&"CROSS")
		if decoys.size()>previous_decoys:skills_executed+=1;skill_history.append(&"DECOYS")
		if ratio<=0.28 and not decoys.is_empty():
			rotation_time=0.8
			skills_executed+=1
			skill_history.append(&"ROTATE")
	if rotation_time>0:
		rotation_time-=delta
		rotation_tick-=delta
		if rotation_tick<=0:
			rotation_tick=0.2
			EnemyVolley.fire(self,Vector2.RIGHT.rotated(phase*4),2,PI,7,190)
func _draw()->void:
	super._draw()
	if transition_pause>0:draw_arc(Vector2.ZERO,46+sin(transition_pause*24)*4,0,TAU,48,Color("ffb749"),5)

func _draw_body(color:Color)->void:
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE*body_radius()/32.0)
	super._draw_body(color)
	draw_set_transform(Vector2.ZERO)
