extends MechanismBoss
## 固定直线/扇扫/轻减速钩后突进；半血禁区最多两条。
var zones:Array[WeakRef]=[]
func choose_actions(_distance:float)->Array:
	if pressure_due() or cycles%4==3:
		return [action(&"HOOK",0.9,10,{"width":40,"gap":0.0}),action(&"SWEEP",0.55,14)]
	if phase_index==2 and cycles%3==0:
		zones=zones.filter(func(ref:WeakRef)->bool:return is_instance_valid(ref.get_ref()))
		if zones.size()<2:
			var node:=zone(BossTelegraph.Shape.RECT,global_position,0,0.7,10,2)
			node.direction=aim_direction
			node.length=340
			node.width=32
			zones.append(weakref(node))
	match cycles%3:
		0:return [action(&"LINE",0.7,14,{"gap":0.05}),action(&"SWEEP",0.8,14)] if phase_index==2 else [action(&"LINE",0.7,14)]
		1:return [action(&"SWEEP",0.8,14)]
	return [action(&"HOOK",0.9,10,{"width":40,"gap":0.0}),action(&"SWEEP",0.55,14)]
func _draw_body(color:Color)->void:
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE*body_radius()/25.0)
	draw_circle(Vector2.ZERO,25,color)
	for i in range(5):draw_arc(Vector2(-36+i*18,0),8,0,TAU,12,Color("b8bec2"),3)
	draw_set_transform(Vector2.ZERO)
