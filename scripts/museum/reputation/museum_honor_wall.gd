class_name MuseumHonorWall
extends MuseumInteractable
var state:MuseumState
func _draw()->void:
	draw_rect(Rect2(-42,-66,84,132),Color("61482e"));draw_rect(Rect2(-38,-62,76,124),Color("b29663"),false,3)
	for index in range(6):
		var pos:=Vector2(-30+(index%2)*32,-52+(index/2)*34)
		var earned:bool=index<state.achievements.size()
		draw_rect(Rect2(pos,Vector2(28,27)),Color("c6a754") if earned else Color("6b6251"));draw_rect(Rect2(pos+Vector2(3,3),Vector2(22,21)),Color("4e4231"),false,1)
		draw_line(pos+Vector2(7,10),pos+Vector2(21,10),Color("e4d6a9"),1);draw_line(pos+Vector2(7,17),pos+Vector2(21,17),Color("e4d6a9"),1)
	draw_string(ThemeDB.fallback_font,Vector2(-34,61),"馆史纪念",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("f2e0b2"))
