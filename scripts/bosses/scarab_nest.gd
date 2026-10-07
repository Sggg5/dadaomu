class_name ScarabNest
extends Enemy
signal summon_requested(count: int)
var timer: float = 1.0
var winding: bool = false
var cycles: int = 0
var rage: bool = false
var dashing: bool = false
var dash_time: float = 0
var dash_direction: Vector2
func _tick_ai(delta: float) -> void:
	rage = health.current_hp<=health.max_hp*0.5
	if dashing:
		dash_time-=delta
		if move_and_collide(dash_direction*260*delta) or dash_time<=0: dashing=false
		return
	timer-=delta
	if timer>0: return
	if not winding:
		winding=true
		telegraphing=true
		timer=0.7
	else:
		winding=false
		telegraphing=false
		cycles+=1
		summon_requested.emit(3 if rage else 2)
		EnemyVolley.fire(self,aim_direction,5,0.2,7,240,1.3)
		if rage and cycles%2==0:
			dashing=true
			dash_time=0.6
			dash_direction=Vector2.LEFT if position.x>640 else Vector2.RIGHT
		timer=2.8 if rage else 4.0
func _draw_body(color: Color) -> void:
	draw_circle(Vector2.ZERO,30,color)
	for i in range(8): draw_circle(Vector2.RIGHT.rotated(i*TAU/8)*26,8,Color("77884a"))
