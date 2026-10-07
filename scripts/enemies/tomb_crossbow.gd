class_name TombCrossbow
extends Enemy
## 固定锁点0.8s，发射前复查世界LOS；不追踪，不穿墙预锁。
var winding:bool=false
var timer:float=1.0
var locked_direction:Vector2
var locked_point:Vector2
var shots:int=0
func _tick_ai(delta:float)->void:
	timer-=delta
	if winding:
		velocity=Vector2.ZERO
		if timer<=0:
			var ray:=PhysicsRayQueryParameters2D.create(global_position,locked_point,1,[get_rid()])
			if get_world_2d().direct_space_state.intersect_ray(ray).is_empty():EnemyVolley.fire(self,locked_direction,1,0,definition.contact_damage,760);shots+=1
			winding=false
			telegraphing=false
			timer=2.4
	elif not has_line_to_target():move_actor(aim_direction,delta)
	elif timer<=0:
		locked_point=target.global_position
		locked_direction=(locked_point-global_position).normalized()
		winding=true
		telegraphing=true
		timer=0.8
func _draw_body(color:Color)->void:
	draw_rect(Rect2(-14,-14,28,28),color)
	draw_line(Vector2(-16,0),Vector2(16,0),Color("cfa471"),5)
	if winding:draw_line(Vector2.ZERO,locked_direction*900,Color(1,0.4,0.2,0.6),2)
