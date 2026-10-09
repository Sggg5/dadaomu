class_name MuseumOfficeDesk
extends MuseumInteractable
## Physical desk silhouette, lamp and open ledger; not a generic interaction square.
func _draw() -> void:
	z_index = int(global_position.y+34) if ArtRenderSettings.active() else 0
	if MuseumDisplayVisual.furniture(self,"馆长办公室"): return
	draw_rect(Rect2(-55,-29,110,58),Color("443122"))
	draw_rect(Rect2(-51,-25,102,48),Color("977246"))
	draw_rect(Rect2(-51,-25,102,48),Color("d2b67a"),false,2)
	for x in [-43,32]: draw_rect(Rect2(x,25,11,10),Color("4d3524"))
	draw_rect(Rect2(-20,-17,40,29),Color("e5d6af"))
	draw_line(Vector2(0,-17),Vector2(0,12),Color("877155"),1)
	for y in [-9,-3,3,9]: draw_line(Vector2(-15,y),Vector2(-4,y),Color("9b8c70"),1)
	draw_circle(Vector2(36,-8),9,Color("597f65"))
	draw_line(Vector2(36,-8),Vector2(36,12),Color("d4b97d"),3)
