class_name TwinAvatar
extends MechanismBoss
var ranged:bool=false
var solo:bool=false
func choose_actions(_distance:float)->Array:
	if ranged:
		if solo and cycles%3==0:return [action(&"CHARGE",0.8,14,{"speed":380})]
		return [action(&"BURST",0.7,12,{"count":3,"spread":0.15})] if cycles%2==0 else [action(&"CIRCLE",1.0,14,{"count":2})]
	if solo and cycles%3==0:return [action(&"FAN",0.8,12,{"count":3})]
	return [action(&"CHARGE",0.8,16,{"speed":450})] if cycles%2==0 else [action(&"SWEEP",0.8,16)]
func _draw_body(color:Color)->void:
	draw_circle(Vector2.ZERO,24,Color("9b719a") if ranged else color)
	draw_line(Vector2(-10,0),Vector2(10,0),Color("ffc06b"),4)
	if solo:draw_arc(Vector2.ZERO,32,0,TAU,32,Color("ff8654"),3)
