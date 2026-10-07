class_name DisplayCase
extends MuseumInteractable
var case_id: StringName
var state: MuseumState


func refresh() -> void:
	var definition := state.definition_for(case_id)
	title = "%s\n%s" % [str(case_id).replace("CASE_","展柜"), definition.display_name if definition != null else "空柜"]
	super.refresh()


func _draw() -> void:
	draw_rect(Rect2(-52,-30,104,60),Color("465765"))
	draw_rect(Rect2(-52,-30,104,60),Color("bcb09a"),false,3)
	var definition := state.definition_for(case_id)
	if definition == null: return
	# 八件原型图标由池内稳定序号派生，仅呈现，不决定玩法。
	var index := MuseumState.POOL.antiques.find(definition)
	var color := Color.from_hsv(float(index)/8.0, .55, .95)
	if index % 3 == 0: draw_circle(Vector2.ZERO,16,color)
	elif index % 3 == 1: draw_rect(Rect2(-15,-15,30,30),color)
	else: draw_colored_polygon(PackedVector2Array([Vector2(0,-18),Vector2(18,14),Vector2(-18,14)]),color)
