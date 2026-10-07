extends MechanismBoss
## 长条棺盖/尸手/锁向冲撞，半血拍击追加两侧手。
func choose_actions(_distance:float)->Array:
	if pressure_due() or cycles%4==3 or (phase_index==2 and cycles%2==1):
		return [action(&"CHARGE",0.8,16,{"speed":400,"duration":0.55,"gap":0.1}),action(&"HANDS",0.8,12,{"count":2,"sides":true,"centered":true,"spread":90})]
	match cycles%3:
		0:return [action(&"SLAM",0.8,16,{"length":240,"width":100}),action(&"HANDS",0.8,12,{"count":2,"sides":true})] if phase_index==2 else [action(&"SLAM",0.8,16,{"length":240,"width":100})]
		1:return [action(&"SLAM",0.8,16,{"length":240,"width":100,"gap":0.1}),action(&"HANDS",0.8,12,{"count":3})] if phase_index==2 else [action(&"HANDS",0.8,12,{"count":3})]
	return [action(&"CHARGE",0.8,16,{"speed":400,"duration":0.55})]
func _draw_body(color:Color)->void:
	draw_rect(Rect2(-26,-42,52,84),Color("705139"))
	draw_rect(Rect2(-20,-34,40,68),color)
	if state==&"WINDUP":draw_line(Vector2(-20,-34),Vector2(32,-52),Color("cfa471"),6)
