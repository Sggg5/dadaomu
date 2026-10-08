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
	else:
		canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(-8,-8)*scale,at+Vector2(8,-5)*scale,at+Vector2(5,8)*scale,at+Vector2(-4,10)*scale]),color)
