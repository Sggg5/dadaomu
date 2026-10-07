class_name BossEgg
extends Enemy
var encounter:BossEncounter
var timer:float=3.0
var hatched:bool=false
func _tick_ai(delta:float)->void:
	timer-=delta
	if timer<=0:
		hatched=true
		encounter._summon(1)
		health.take_damage(health.max_hp)
func _draw_body(color:Color)->void:
	draw_circle(Vector2.ZERO,12,color)
	draw_arc(Vector2.ZERO,16,0,TAU*(1-timer/3),20,Color("ffc06b"),2)
