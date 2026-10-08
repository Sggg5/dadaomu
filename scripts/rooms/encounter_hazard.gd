class_name EncounterHazard
extends Node2D
## 可见预警→有限攻击；不使用异步Timer，离房随Room释放，不延迟追伤。
enum Phase { OFF, WARN, ACTIVE }
var room:Room
var data:EncounterHazardDefinition
var phase:Phase=Phase.OFF
var remaining:float
var age:float=0
var tick_remaining:float=0.75
var hit_player:bool=false
var owner_guard:WeakRef
func _ready()->void:
	position=data.position
	remaining=data.initial_delay if data.periodic else data.warning_time
	phase=Phase.OFF if data.periodic else Phase.WARN
	if data.kind==EncounterHazardDefinition.Kind.POISON:phase=Phase.ACTIVE
func _physics_process(delta:float)->void:
	if owner_guard!=null:
		var actor:=owner_guard.get_ref() as Enemy
		if not is_instance_valid(actor) or actor.health.is_dead:queue_free();return
	if data.kind==EncounterHazardDefinition.Kind.WATER:queue_redraw();return
	if data.combat_only and room.room_state.status!=RoomState.Status.ACTIVE:
		phase=Phase.OFF
		queue_redraw()
		return
	if data.kind==EncounterHazardDefinition.Kind.POISON:
		age+=delta
		tick_remaining-=delta
		if tick_remaining<=0:
			tick_remaining+=0.75
			_hurt()
		if age>=data.duration:queue_free()
	else:
		remaining-=delta
		if phase==Phase.ACTIVE and data.kind in [EncounterHazardDefinition.Kind.BLAST,EncounterHazardDefinition.Kind.SPIKES,EncounterHazardDefinition.Kind.GATE_SWEEP,EncounterHazardDefinition.Kind.FIRE_FAN] and not hit_player:hit_player=_hurt()
		if remaining<=0:
			match phase:
				Phase.OFF:phase=Phase.WARN;remaining=data.warning_time
				Phase.WARN:
					phase=Phase.ACTIVE
					remaining=data.duration
					hit_player=false
					if data.kind==EncounterHazardDefinition.Kind.ARROW_HOLE:_bullet(data.direction)
					elif data.kind==EncounterHazardDefinition.Kind.RING:
						for i in range(8):_bullet(Vector2.RIGHT.rotated(i*TAU/8))
				Phase.ACTIVE:
					if not data.periodic:queue_free()
					else:phase=Phase.OFF;remaining=data.interval
	queue_redraw()
func contains_point(point:Vector2,margin:float=0)->bool:
	var local:=point-position
	if data.kind==EncounterHazardDefinition.Kind.GATE_SWEEP:
		return Rect2(Vector2(-data.strip_length/2,-data.strip_width/2),Vector2(data.strip_length,data.strip_width)).grow(margin).has_point(local)
	if data.kind==EncounterHazardDefinition.Kind.FIRE_FAN:
		return local.length()<=data.radius+margin and (local.length()<margin+1 or local.normalized().dot(data.direction.normalized())>=0.65)
	return local.length()<=data.radius+margin
func _hurt()->bool:
	var player:=room.combat_target
	if not player.controls_enabled or player.health.is_dead or not contains_point(player.position):return false
	var ray:=PhysicsRayQueryParameters2D.create(global_position,player.global_position,1)
	if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():return false
	return player.take_damage(data.damage)
func _bullet(direction:Vector2)->void:
	if room.combat_target.health.is_dead or not room.combat_target.controls_enabled or room.projectiles.get_child_count()>=256:return
	var request:=AttackRequest.new()
	request.origin=global_position
	request.direction=direction.normalized()
	request.damage=data.damage
	request.speed=data.projectile_speed
	request.lifetime=1.6
	request.tags.append(&"arrow")
	var bullet:=preload("res://scenes/enemies/enemy_projectile.tscn").instantiate() as EnemyProjectile
	room.projectiles.add_child(bullet)
	bullet.setup(request)
	bullet.track_player(room.combat_target)
func _draw()->void:
	if data.kind in [EncounterHazardDefinition.Kind.GATE_SWEEP,EncounterHazardDefinition.Kind.FIRE_FAN]:
		var color:=Color("d6ba72") if data.kind==EncounterHazardDefinition.Kind.GATE_SWEEP else Color("e77c42")
		color.a=0.1 if phase==Phase.OFF else (0.28 if phase==Phase.WARN else 0.8)
		if data.kind==EncounterHazardDefinition.Kind.GATE_SWEEP:
			var rect:=Rect2(Vector2(-data.strip_length/2,-data.strip_width/2),Vector2(data.strip_length,data.strip_width))
			draw_rect(rect,color)
			draw_rect(rect,Color("bf9a55"),false,2)
		else:
			var points:=PackedVector2Array([Vector2.ZERO])
			for index in range(13):points.append(data.direction.rotated(-0.85+index*1.7/12)*data.radius)
			draw_colored_polygon(points,color)
			draw_polyline(points,Color("c98454"),2)
		return
	var poison:=data.kind==EncounterHazardDefinition.Kind.POISON
	var water:=data.kind==EncounterHazardDefinition.Kind.WATER
	var color:=Color("749b63") if poison or water else Color("ef964e")
	if water or poison:
		draw_circle(Vector2.ZERO,data.radius,Color(color,0.25))
		draw_arc(Vector2.ZERO,data.radius,0,TAU,32,color,2)
	elif phase==Phase.WARN:
		draw_circle(Vector2.ZERO,data.radius,Color(color,0.12))
		draw_arc(Vector2.ZERO,data.radius,0,TAU,32,color,3)
		if data.kind==EncounterHazardDefinition.Kind.ARROW_HOLE:draw_line(Vector2.ZERO,data.direction*1000,Color(1,0.55,0.25,0.5),2)
	elif phase==Phase.ACTIVE:draw_circle(Vector2.ZERO,data.radius,Color(1,0.3,0.16,0.45))
	elif data.periodic:draw_arc(Vector2.ZERO,data.radius,0,TAU,20,Color("655644"),1)
