extends MechanismBoss
## 墓室命令与本体攻击配合；60/30阶段，低血停止召兵以裂隙收尾。
var collapse:Array[WeakRef]=[]
func _init()->void:phase_thresholds=[0.6,0.3]
func choose_actions(_distance:float)->Array:
	if phase_index==3:
		collapse=collapse.filter(func(ref:WeakRef)->bool:return is_instance_valid(ref.get_ref()))
		for i in range(3-collapse.size()):
			var preferred:=encounter_room.to_local(target.global_position)+Vector2((i-1)*120,0)
			var point:=EncounterGeometry.safe_point(encounter_room,preferred,60)
			if point.is_finite():collapse.append(weakref(zone(BossTelegraph.Shape.CIRCLE,encounter_room.to_global(point),54,0.9,6,2)))
		return [action(&"CHARGE",0.7,18),action(&"FAN",0.7,14,{"count":7})]
	match cycles%5:
		0:return [action(&"BARRIER",0.8,0),action(&"FAN",0.7,14)] if phase_index==2 else [action(&"BARRIER",0.8,0)]
		1:return [action(&"SUMMON",0.8,0,{"count":2})]
		2:return [action(&"ROCKS",1.0,16,{"radius":80}),action(&"CHARGE",0.7,18)] if phase_index==2 else [action(&"ROCKS",1.0,16,{"radius":80})]
		3:return [action(&"FAN",0.7,14,{"count":5})]
	return [action(&"CHARGE",0.7,18)]
func _draw_body(color:Color)->void:
	draw_colored_polygon(PackedVector2Array([Vector2(0,-42),Vector2(30,30),Vector2(-30,30)]),color)
	draw_line(Vector2(-26,-30),Vector2(26,-30),Color("e0b554"),8)
