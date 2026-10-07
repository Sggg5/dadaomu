class_name BurrowingCorpse
extends Enemy
## 短地下期→0.8s合法落点预警→出土单次伤害→可攻击追击，不能永久无敌。
enum State{SURFACE,BURIED,WARNING}
var state:State=State.SURFACE
var timer:float=2.0
var landing:Vector2
var marker:EncounterHazard
var eruptions:int=0
func reserved_world_position()->Vector2:
	return encounter_room.to_global(landing) if state==State.WARNING else global_position
func take_damage(amount:float)->bool:
	return super.take_damage(amount) if state==State.SURFACE else false
func _tick_ai(delta:float)->void:
	timer-=delta
	match state:
		State.SURFACE:
			move_actor(aim_direction,delta)
			if timer<=0 and encounter_room!=null:
				state=State.BURIED
				timer=0.6
				$CollisionShape2D.set_deferred("disabled",true)
		State.BURIED:
			velocity=Vector2.ZERO
			if timer<=0:
				# Player/Enemy可能不与Room同父节点；世界预测先转换为Room局部坐标。
				var predicted:=encounter_room.to_local(target.global_position+target.velocity*0.45)
				var origin:=encounter_room.to_local(global_position)
				landing=EncounterGeometry.safe_reachable_point(encounter_room,predicted,origin,72,0,get_rid())
				if not landing.is_finite():state=State.SURFACE;timer=2;$CollisionShape2D.set_deferred("disabled",false);return
				marker=encounter_room.hazards.blast(landing,0.8,52,definition.contact_damage,weakref(self))
				state=State.WARNING
				timer=0.8
		State.WARNING:
			velocity=Vector2.ZERO
			if timer<=0:
				# 预警期间其他实体可能占位；出土前再找同侧合法点，不能重叠启用碰撞。
				var resolved:=EncounterGeometry.safe_reachable_point(encounter_room,landing,encounter_room.to_local(global_position),72,0,get_rid())
				if not resolved.is_finite():state=State.SURFACE;timer=2;$CollisionShape2D.set_deferred("disabled",false);return
				landing=resolved
				global_position=encounter_room.to_global(landing)
				state=State.SURFACE
				timer=3.0
				eruptions+=1
				$CollisionShape2D.set_deferred("disabled",false)
func _draw()->void:
	if state==State.SURFACE:super._draw()
	else:draw_circle(Vector2.ZERO,8,Color("796d52"))
func _draw_body(color:Color)->void:
	draw_circle(Vector2.ZERO,16,color)
	draw_line(Vector2(-12,-7),Vector2(12,7),Color("453930"),4)
