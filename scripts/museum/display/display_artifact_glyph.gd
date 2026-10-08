class_name DisplayArtifactGlyph
extends RefCounted
## Original miniature silhouettes, no museum photograph implies ownership.
static func draw_icon(canvas: Node2D, id: StringName, at: Vector2, scale: float = 1) -> void:
	var index := MuseumState.POOL.antiques.find(MuseumState.POOL.find_by_id(id))
	var color := Color.from_hsv(maxi(0,index)/8.0,.45,.92)
	if id == &"republic_silver_coin":
		canvas.draw_circle(at,8*scale,Color("c9cdd0"))
		canvas.draw_arc(at,5*scale,0,TAU,16,Color("858c8e"),1)
	elif id in [&"han_jade_disc", &"inlaid_bronze_mirror"]:
		canvas.draw_circle(at,10*scale,Color("8cac8d") if id == &"han_jade_disc" else Color("b6a369"))
		canvas.draw_circle(at,3*scale,Color("24343e"))
	elif id == &"blue_white_jar":
		canvas.draw_circle(at+Vector2(0,2)*scale,8*scale,Color("d4e4e3"))
		canvas.draw_rect(Rect2(at+Vector2(-5,-10)*scale,Vector2(10,5)*scale),Color("789dbd"))
		canvas.draw_line(at+Vector2(-5,2)*scale,at+Vector2(5,2)*scale,Color("537fb0"),2)
	elif id == &"tang_sancai_horse":
		canvas.draw_rect(Rect2(at+Vector2(-10,-3)*scale,Vector2(16,8)*scale),Color("c89955"))
		canvas.draw_line(at+Vector2(5,0)*scale,at+Vector2(7,-10)*scale,Color("d5b572"),4*scale)
		for x in [-7,4]: canvas.draw_line(at+Vector2(x,4)*scale,at+Vector2(x,11)*scale,Color("996d36"),2)
	elif id == &"gilt_buddha":
		canvas.draw_circle(at+Vector2(0,-6)*scale,4*scale,Color("d4b65c"))
		canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(0,-2)*scale,at+Vector2(9,9)*scale,at+Vector2(-9,9)*scale]),Color("d4b65c"))
	elif MuseumState.POOL.find_by_id(id).category!=&"":
		var item:=MuseumState.POOL.find_by_id(id)
		if item.category in [&"COIN",&"JADE",&"BRONZE"]:
			canvas.draw_circle(at,9*scale,color)
			canvas.draw_arc(at,6*scale,0,TAU,20,Color("ddcc9a"),1)
			canvas.draw_circle(at,2*scale,Color("28343a"))
		elif item.category==&"CERAMIC":
			canvas.draw_circle(at+Vector2(0,3)*scale,8*scale,Color("ba9673"))
			canvas.draw_rect(Rect2(at+Vector2(-4,-9)*scale,Vector2(8,5)*scale),Color("d1ae87"))
		elif item.category==&"CERAMIC_SCULPTURE":
			canvas.draw_circle(at+Vector2(0,-7)*scale,4*scale,Color("c79e65"))
			canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(-7,9)*scale,at+Vector2(0,-3)*scale,at+Vector2(7,9)*scale]),Color("9c804b"))
		elif item.category==&"JEWELRY":
			canvas.draw_rect(Rect2(at-Vector2(8,6)*scale,Vector2(16,12)*scale),Color("d7bd70"))
			canvas.draw_circle(at,3*scale,Color("f1dda2"))
		else:canvas.draw_rect(Rect2(at-Vector2(8,5)*scale,Vector2(16,10)*scale),Color("9d8b70"))
	else:
		canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(-8,-8)*scale,at+Vector2(8,-5)*scale,at+Vector2(5,8)*scale,at+Vector2(-4,10)*scale]),color)
