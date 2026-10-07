class_name RottingCorpse
extends ScarabEnemy
## 近战复用尸蟞状态机；死亡污水归本房管理，四秒到期且最多四池。
func _on_died()->void:
	if dying:return
	if encounter_room!=null:encounter_room.hazards.spill(position,4)
	super._on_died()
func _draw_body(color:Color)->void:
	draw_circle(Vector2.ZERO,16,color)
	for point in [Vector2(-7,-4),Vector2(5,7)]:draw_circle(point,4,Color("495d35"))
