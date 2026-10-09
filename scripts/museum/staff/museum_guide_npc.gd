class_name MuseumGuideNPC
extends Node2D
## Real non-blocking guide actor: walks to station, waits, then serves a real reservation.
var staff_id:StringName
var state:MuseumState
var business:MuseumBusiness
var hall_id:StringName=&"MAIN"
var label:Label
func _ready()->void:
	position=Vector2(1180,560)
	label=Label.new()
	label.position=Vector2(-65,18);label.size=Vector2(130,42)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",13)
	add_child(label)
func _physics_process(delta:float)->void:
	var member:MuseumStaffMember=state.staff.members[staff_id]
	hall_id=member.assigned_hall
	var definition:MuseumStaffDefinition=MuseumStaffService.catalog()[staff_id]
	var attending:=business.running and not business.closing and business.workday!=null and staff_id in business.workday.paid_ids
	var target:=Vector2(1100 if staff_id==&"GUIDE_LIN" else 1160,550)
	position=position.move_toward(target,90*delta)
	if attending and position.distance_to(target)<2:business.workday.ready_guides[staff_id]=true
	elif business.workday!=null:business.workday.ready_guides.erase(staff_id)
	label.text=definition.display_name+" / 导览员\n"+("导览中" if attending and staff_id in business.workday.reservations.values() else "等待游客" if attending else "未出勤")
	visible=hall_id==get_parent().active_hall_id
	queue_redraw()
func _draw()->void:
	draw_circle(Vector2(0,-5),8,Color("dcc5a0"))
	draw_colored_polygon(PackedVector2Array([Vector2(-12,3),Vector2(12,3),Vector2(10,17),Vector2(-10,17)]),Color("798e9c"))
	draw_rect(Rect2(5,3,8,9),Color("e6d8b5"))
func _exit_tree()->void:
	if is_instance_valid(business) and business.workday!=null:business.workday.ready_guides.erase(staff_id)
