class_name PaperSpirit
extends Enemy
## 中距横移，三发纸符散射，与枪手定向单发区分。
var timer: float = 1.0
var phase: float = 0
var winding: bool = false
var volleys: int = 0
func _tick_ai(delta: float) -> void:
	phase+=delta
	timer-=delta
	if winding:
		velocity=Vector2.ZERO
		if timer<=0:
			if has_line_to_target():
				EnemyVolley.fire(self,aim_direction,3,0.2,8,270)
				volleys+=1
			winding=false
			telegraphing=false
			timer=definition.attack_cooldown
	else:
		var distance := position.distance_to(target.position)
		var movement := aim_direction.rotated(PI/2)*(1 if sin(phase)>0 else -1)
		if distance>340: movement=aim_direction
		elif distance<180: movement=-aim_direction
		move_actor(movement,delta)
		if timer<=0 and has_line_to_target():
			winding=true
			telegraphing=true
			timer=definition.windup_time
func _draw_body(color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(0,-20),Vector2(15,0),Vector2(10,18),Vector2(-10,18),Vector2(-15,0)]),color)
	draw_line(Vector2(-7,-4),Vector2(7,-4),Color("a63736"),3)
