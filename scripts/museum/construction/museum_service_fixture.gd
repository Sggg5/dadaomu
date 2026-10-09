class_name MuseumServiceFixture
extends Node2D
## Visible public service, instantiated only for the current hall and purchased levels.
var kind:StringName
var level:int
func _ready()->void:
	var label:=Label.new()
	label.position=Vector2(-70,24)
	label.size=Vector2(140,35)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",13)
	label.text="%s · %d级"%[{&"GUIDE":"导览牌",&"REST":"休息区",&"RECEPTION":"接待台"}.get(kind,""),level]
	add_child(label)
func _draw()->void:
	if kind==&"GUIDE":
		draw_rect(Rect2(-27,-23,54,43),Color("645c44"))
		draw_rect(Rect2(-23,-19,46,32),Color("e1d6b6"))
		for i in range(level+2):draw_line(Vector2(-16,-12+i*6),Vector2(16,-12+i*6),Color("47645d"),2)
		draw_line(Vector2(-17,20),Vector2(-17,30),Color("9c794d"),4)
	elif kind==&"REST":
		draw_rect(Rect2(-43,-7,86,20),Color("8d6e46"))
		draw_rect(Rect2(-43,-20,86,8),Color("b39b68"))
		for i in range(level):draw_rect(Rect2(-35+i*25,-6,20,13),Color("627c75"))
		for x in [-34,30]:draw_line(Vector2(x,13),Vector2(x,24),Color("a58354"),4)
	else:
		draw_rect(Rect2(-42,-18,84,37),Color("766046"))
		draw_rect(Rect2(-38,-14,76,10),Color("d1b786"))
		draw_circle(Vector2(25,-6),5+level,Color("dcca8b"))
		for i in range(level):draw_rect(Rect2(-29+i*14,-10,10,15),Color("e2dac6"))
