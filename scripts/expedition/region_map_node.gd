class_name RegionMapNode
extends Control
signal selected(id:StringName)
var definition:RegionDefinition
var highlighted:bool=false
var hovered:bool=false
func _ready()->void:
	mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func()->void:hovered=true;queue_redraw())
	mouse_exited.connect(func()->void:hovered=false;queue_redraw())
	tooltip_text=definition.description
func _gui_input(event:InputEvent)->void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		selected.emit(definition.region_id)
		accept_event()
func _draw()->void:
	var color:=Color("8d3028") if highlighted or hovered else Color("514332")
	draw_circle(Vector2(42,22),17,Color("efe0b8"))
	draw_arc(Vector2(42,22),17,0,TAU,32,color,2)
	draw_line(Vector2(26,22),Vector2(58,22),color,1)
	draw_line(Vector2(42,6),Vector2(42,38),color,1)
	draw_circle(Vector2(42,22),5,color)
	draw_string(ThemeDB.fallback_font,Vector2(12,64),definition.display_name,HORIZONTAL_ALIGNMENT_LEFT,-1,22,color)
