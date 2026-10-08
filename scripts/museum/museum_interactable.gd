class_name MuseumInteractable
extends Node2D
## 统一距离/提示/回调接口；Player不包含库房或展柜类型分支。
var interaction_priority: int = 10 # fixtures should not be occluded by visitors
var prompt: Callable
var action: Callable
var alternate_action: Callable
var label: Label
var title: String
var tint: Color = Color("ba9b63")


func _ready() -> void:
	label = Label.new()
	label.position = Vector2(-100, 28)
	label.size = Vector2(200, 90)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	refresh()


func refresh() -> void:
	if is_instance_valid(label): label.text = title
	queue_redraw()


func interact() -> void:
	if action.is_valid(): action.call()


func alternate() -> void:
	if alternate_action.is_valid(): alternate_action.call()


func _draw() -> void:
	draw_rect(Rect2(-30,-22,60,44), tint)
	draw_rect(Rect2(-30,-22,60,44), Color("efdfb7"), false, 2)
