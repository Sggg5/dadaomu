extends MechanismBoss
## 虫卵/虫群教学→换位错拍→有限虫卵与慢环收尾。
func _init()->void:phase_thresholds=[0.65,0.3]
func choose_actions(_distance:float)->Array:
	if phase_index==3:return [action(&"RING",0.7,7),action(&"CHARGE",0.6,12,{"speed":260,"duration":0.6})] if cycles%2==0 else [action(&"EGGS",0.7,0,{"count":1})]
	match cycles%3:
		0:return [action(&"EGGS",0.7,0,{"count":3}),action(&"CHARGE",0.6,10,{"speed":260,"duration":0.4})] if phase_index==2 else [action(&"EGGS",0.7,0,{"count":3})]
		1:return [action(&"FAN",0.7,7,{"count":5,"speed":240})]
	return [action(&"SUMMON",0.7,0,{"count":2})]
func _draw_body(color:Color)->void:
	draw_circle(Vector2.ZERO,30,color)
	for i in range(8):draw_circle(Vector2.RIGHT.rotated(i*TAU/8)*26,8,Color("77884a"))
