extends MechanismBoss
## 距离/上次技能/阶段确定性决策，避免固定冲震交替。
var previous:StringName=&""
func choose_actions(distance:float)->Array:
	var kind:StringName=&"SHOCK" if distance<210 else (&"CHARGE" if distance>380 else &"BURST")
	if kind==previous:kind=[&"BURST",&"SUMMON",&"SHOCK",&"CHARGE"][cycles%4]
	if kind==previous:kind=&"SUMMON" if previous!=&"SUMMON" else &"CHARGE"
	previous=kind
	match kind:
		&"SHOCK":return [action(&"CIRCLE",0.8,16,{"count":1,"spread":0,"centered":true,"radius":180,"gap":0.5}),action(&"CHARGE",0.65,18,{"speed":650,"duration":0.45})] if phase_index==2 else [action(&"CIRCLE",0.8,16,{"count":1,"spread":0,"centered":true,"radius":180})]
		&"CHARGE":return [action(&"CHARGE",0.65,18,{"speed":650,"duration":0.45})]
		&"SUMMON":return [action(&"SUMMON",0.8,0,{"count":2})]
	return [action(&"BURST",0.7,12,{"count":1}),action(&"BURST",0.25,12,{"count":1}),action(&"BURST",0.25,12,{"count":1})]
func _draw_body(color:Color)->void:
	draw_colored_polygon(PackedVector2Array([Vector2(-28,-24),Vector2(28,-24),Vector2(36,30),Vector2(-36,30)]),color)
	draw_rect(Rect2(-30,-36,60,14),Color("302d42"))
