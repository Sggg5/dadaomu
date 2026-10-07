extends MechanismBoss
## 有规则的距离决策；70/35两转段，裂隙最多三处，组合后1秒恢复。
var previous:StringName=&""
var fissures:Array[WeakRef]=[]
func _init()->void:phase_thresholds=[0.7,0.35]
func choose_actions(distance:float)->Array:
	var kind:StringName=&"POUNCE" if distance>300 else (&"ROAR" if distance<160 else &"SPIKES")
	if kind==previous:kind=[&"SPIKES",&"ROAR",&"POUNCE"][cycles%3]
	previous=kind
	if phase_index==1 and (pressure_due() or cycles%4==3):return [action(&"SPIKES",0.9,14,{"gap":0.05}),action(&"POUNCE",0.8,18,{"duration":0.5})]
	if phase_index==3:
		fissures=fissures.filter(func(ref:WeakRef)->bool:return is_instance_valid(ref.get_ref()))
		if fissures.size()<3:
			var point:=EncounterGeometry.safe_point(encounter_room,encounter_room.to_local(target.global_position)+Vector2(80,0),50)
			if point.is_finite():fissures.append(weakref(zone(BossTelegraph.Shape.CIRCLE,encounter_room.to_global(point),44,0.9,6,2)))
		if health.current_hp/health.max_hp<=0.25 or cycles%3==0:return [action(&"SPIKES",0.9,14,{"gap":0.05}),action(&"FAN",0.7,12,{"count":7,"gap":0.05}),action(&"POUNCE",0.8,18,{"speed":550,"duration":0.5})]
	if kind==&"SPIKES" and (phase_index>=2 or pressure_due() or cycles%4==3):return [action(&"SPIKES",0.9,14,{"gap":0.05}),action(&"POUNCE",0.8,18,{"duration":0.5})]
	match kind:
		&"POUNCE":return [action(&"POUNCE",0.8,18,{"speed":550,"duration":0.5}),action(&"SPIKES",0.9,14)] if phase_index>=2 else [action(&"POUNCE",0.8,18,{"speed":550,"duration":0.5})]
		&"ROAR":return [action(&"FAN",0.7,12,{"count":7}),action(&"POUNCE",0.8,18,{"speed":550,"duration":0.5})] if phase_index>=2 else [action(&"FAN",0.7,12,{"count":5})]
	return [action(&"SPIKES",0.9,14)]
func _draw_body(color:Color)->void:
	draw_colored_polygon(PackedVector2Array([Vector2(-40,-18),Vector2(-24,-40),Vector2(24,-40),Vector2(40,-18),Vector2(32,30),Vector2(-32,30)]),color)
	for sign_value in [-1,1]:draw_line(Vector2(sign_value*20,-28),Vector2(sign_value*38,-55),Color("c5bd92"),9)
