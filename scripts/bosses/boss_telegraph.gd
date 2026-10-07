class_name BossTelegraph
extends Node2D
## 所有者弱引用，世界1 LOS，预警高于玩家特效。有限时钟，死亡/卸载无延迟伤害。
enum Shape { CIRCLE, RECT, SECTOR, PATH }
var actor:WeakRef
var player:Player
var shape:Shape=Shape.CIRCLE
var radius:float=70
var length:float=300
var width:float=48
var angle:float=2.4
var direction:Vector2=Vector2.RIGHT
var path:PackedVector2Array=[]
var warning:float=0.8
var duration:float=0.25
var damage:float=12
var slow:bool=false
var elapsed:float=0
var hit:bool=false
var tick:float=0
func _ready()->void:z_index=300
func contains(point:Vector2)->bool:
	var relative:=point-global_position
	match shape:
		Shape.CIRCLE:return relative.length()<=radius
		Shape.RECT:return relative.dot(direction)>=0 and relative.dot(direction)<=length and absf(relative.dot(direction.orthogonal()))<=width*0.5
		Shape.SECTOR:return relative.length()<=radius and absf(direction.angle_to(relative))<=angle*0.5
		Shape.PATH:
			for i in range(1,path.size()):
				if Geometry2D.get_closest_point_to_segment(point,to_global(path[i-1]),to_global(path[i])).distance_to(point)<width*0.5:return true
	return false
func _physics_process(delta:float)->void:
	var owner:=actor.get_ref() as Enemy if actor!=null else null
	if not is_instance_valid(owner) or not owner.can_act():queue_free();return
	elapsed+=delta
	if damage>0 and elapsed>=warning and (not hit or duration>0.5):
		tick-=delta
		if tick<=0 and contains(player.global_position):
			var ray:=PhysicsRayQueryParameters2D.create(global_position,player.global_position,1)
			if get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
				if player.take_damage(damage):
					hit=true
					if slow:
						var status:=BossSlow.new()
						status.player=player
						owner.add_child(status)
						if owner is MechanismBoss:owner.owned.append(weakref(status))
					tick=0.75
	if elapsed>=warning+duration:queue_free()
	queue_redraw()
func _draw()->void:
	var color:=Color("ffc06b") if elapsed<warning else Color("ff7754")
	match shape:
		Shape.CIRCLE:
			draw_circle(Vector2.ZERO,radius,Color(color,0.08))
			draw_arc(Vector2.ZERO,radius,0,TAU,48,color,4)
		Shape.RECT:
			var side:=direction.orthogonal()*width*0.5
			var points:=PackedVector2Array([-side,direction*length-side,direction*length+side,side,-side])
			draw_polyline(points,color,4)
		Shape.SECTOR:
			draw_arc(Vector2.ZERO,radius,direction.angle()-angle*0.5,direction.angle()+angle*0.5,32,color,4)
			for sign_value in [-1,1]:draw_line(Vector2.ZERO,direction.rotated(angle*0.5*sign_value)*radius,color,4)
		Shape.PATH:
			if path.size()>1:draw_polyline(path,color,width if elapsed>=warning else 4)
