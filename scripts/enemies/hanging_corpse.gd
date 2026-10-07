class_name HangingCorpse
extends Enemy
## 固定悬棺尸，使用本房合法点与弱引用预警；死亡取消尚未落下的攻击。
var timer:float=1.2
var drops:int=0
func _tick_ai(delta:float)->void:
	velocity=Vector2.ZERO
	timer-=delta
	if timer>0 or encounter_room==null:return
	var point:=EncounterGeometry.safe_point(encounter_room,target.position,64)
	if point.is_finite():
		encounter_room.hazards.blast(point,1.0,60,definition.contact_damage,weakref(self))
		drops+=1
	timer=3.0
func _draw_body(color:Color)->void:
	draw_line(Vector2(0,-42),Vector2(0,-14),Color("a89576"),3)
	draw_colored_polygon(PackedVector2Array([Vector2(-12,-12),Vector2(12,-12),Vector2(6,20),Vector2(-6,20)]),color)
