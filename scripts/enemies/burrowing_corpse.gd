class_name BurrowingCorpse
extends Enemy
## 地下期有2.4秒硬上限；恢复只取消攻击/合法放置，不修改Health或清房账本。
enum State{SURFACE,BURIED,WARNING}
const SUBMERGED_LIMIT:float=2.4
var state:State=State.SURFACE
var timer:float=2.0
var landing:Vector2=Vector2.INF
var marker:EncounterHazard
var eruptions:int=0
var last_surface_position:Vector2
var submerged_elapsed:float=0
var recoveries:int=0
var recovery_failed:bool=false
var recovery_reason:StringName
var _submerged_status:int=-1
func _ready()->void:
	super._ready()
	last_surface_position=encounter_room.to_local(global_position) if encounter_room!=null else position
func reserved_world_position()->Vector2:
	return encounter_room.to_global(landing) if state==State.WARNING and landing.is_finite() else global_position
func take_damage(amount:float)->bool:
	return super.take_damage(amount) if state==State.SURFACE else false
func _cancel_marker()->void:
	if is_instance_valid(marker):marker.set_physics_process(false);marker.queue_free()
	marker=null
func _valid_surface(point:Vector2)->bool:
	return point.is_finite() and Room.ROOM_RECT.grow(-14).has_point(point) and encounter_room.obstacles().all(func(rect:Rect2)->bool:return not rect.grow(14).has_point(point))
func force_surface_recovery(reason:StringName=&"MANUAL")->void:
	_cancel_marker()
	recoveries+=1
	recovery_reason=reason
	state=State.SURFACE
	timer=2.0
	submerged_elapsed=0
	_submerged_status=-1
	landing=Vector2.INF
	velocity=Vector2.ZERO
	recovery_failed=false
	if is_instance_valid(encounter_room) and is_inside_tree() and not health.is_dead:
		var point:=EncounterGeometry.safe_reachable_point(encounter_room,last_surface_position,last_surface_position,24,0,get_rid())
		if not point.is_finite() and not _valid_surface(last_surface_position):point=EncounterGeometry.safe_point(encounter_room,last_surface_position,24,40)
		if point.is_finite():global_position=encounter_room.to_global(point);last_surface_position=point
		else:recovery_failed=not _valid_surface(last_surface_position)
	$CollisionShape2D.set_deferred("disabled",health.is_dead or dying)
	queue_redraw()
func _physics_process(delta:float)->void:
	if state!=State.SURFACE and not health.is_dead:
		if _submerged_status<0:_submerged_status=encounter_room.room_state.status
		submerged_elapsed+=delta
		if not ai_enabled or target.health.is_dead or encounter_room.hazards.stopped:force_surface_recovery(&"STOPPED")
		elif encounter_room.room_state.status!=_submerged_status:force_surface_recovery(&"ROOM_CHANGED")
		elif submerged_elapsed>=SUBMERGED_LIMIT:force_surface_recovery(&"TIMEOUT")
		elif state==State.WARNING and (not is_instance_valid(marker) or marker.is_queued_for_deletion()):force_surface_recovery(&"MARKER_LOST")
	super._physics_process(delta)
	if state==State.SURFACE and not health.is_dead and encounter_room!=null:
		var point:=encounter_room.to_local(global_position)
		if _valid_surface(point):last_surface_position=point
		else:force_surface_recovery(&"INVALID_SURFACE")
func _tick_ai(delta:float)->void:
	timer-=delta
	match state:
		State.SURFACE:
			move_actor(aim_direction,delta)
			if timer<=0 and encounter_room!=null:
				state=State.BURIED
				timer=0.6
				submerged_elapsed=0
				_submerged_status=encounter_room.room_state.status
				$CollisionShape2D.set_deferred("disabled",true)
		State.BURIED:
			velocity=Vector2.ZERO
			if timer<=0:
				var predicted:=encounter_room.to_local(target.global_position+target.velocity*0.45)
				landing=EncounterGeometry.safe_reachable_point(encounter_room,predicted,encounter_room.to_local(global_position),72,0,get_rid())
				if not landing.is_finite():force_surface_recovery(&"NO_LANDING");return
				marker=encounter_room.hazards.blast(landing,0.8,52,definition.contact_damage,weakref(self))
				if not is_instance_valid(marker):force_surface_recovery(&"HAZARD_CAP");return
				state=State.WARNING
				timer=0.8
		State.WARNING:
			velocity=Vector2.ZERO
			if timer<=0:
				var resolved:=EncounterGeometry.safe_reachable_point(encounter_room,landing,encounter_room.to_local(global_position),72,0,get_rid())
				if not resolved.is_finite() or not resolved.is_equal_approx(landing):force_surface_recovery(&"LANDING_CHANGED");return
				global_position=encounter_room.to_global(landing)
				state=State.SURFACE
				timer=3.0
				submerged_elapsed=0
				_submerged_status=-1
				eruptions+=1
				$CollisionShape2D.set_deferred("disabled",false)
func stop_ai()->void:
	if state!=State.SURFACE:force_surface_recovery(&"STOPPED")
	_cancel_marker()
	super.stop_ai()
func _exit_tree()->void:_cancel_marker()
func _draw()->void:
	if state==State.SURFACE:super._draw()
	else:draw_circle(Vector2.ZERO,8,Color("796d52"))
func _draw_body(color:Color)->void:
	draw_circle(Vector2.ZERO,16,color)
	draw_line(Vector2(-12,-7),Vector2(12,7),Color("453930"),4)
