class_name PaperGeneral
extends Enemy
var timer: float = 1
var winding: bool = false
var volleys: int = 0
var rage: bool = false
var phase: float = 0
var decoys: Array[WeakRef] = []
func _tick_ai(delta: float) -> void:
	rage=health.current_hp<health.max_hp*0.5
	phase+=delta
	if not winding: move_actor(aim_direction.rotated(PI/2)*(1 if sin(phase)>0 else -1),delta)
	timer-=delta
	if timer>0: return
	if not winding:
		winding=true
		telegraphing=true
		timer=0.65
	else:
		winding=false
		telegraphing=false
		volleys+=1
		EnemyVolley.fire(self,aim_direction,5,0.2,9,290)
		if rage:
			EnemyVolley.fire(self,aim_direction.rotated(PI/2),3,0.2,7,250)
			EnemyVolley.fire(self,aim_direction.rotated(-PI/2),3,0.2,7,250)
		if volleys%2==0:
			decoys=decoys.filter(func(reference: WeakRef) -> bool: return is_instance_valid(reference.get_ref()))
			if decoys.is_empty():
				for sign_value in [-1,1]:
					var fake := PaperDecoy.new()
					fake.owner_boss=self
					fake.position=Vector2(sign_value*90,0)
					add_child(fake)
					decoys.append(weakref(fake))
		timer=1.5
func stop_ai() -> void:
	super.stop_ai()
	for reference in decoys:
		var fake := reference.get_ref() as Node
		if is_instance_valid(fake): fake.queue_free()
func _draw_body(color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(0,-30),Vector2(24,0),Vector2(18,28),Vector2(-18,28),Vector2(-24,0)]),color)
	draw_rect(Rect2(-15,-32,30,8),Color("cf5147"))
