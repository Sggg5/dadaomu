class_name MuseumStaffWorkday
extends RefCounted
## Temporary business context, discarded with an interrupted OPEN. No offline progress.
var state:MuseumState
var day:int
var paid_ids:Array[StringName]=[]
var wages_paid:=0
var ready_guides:Dictionary={}
var reservations:Dictionary[int,StringName]={}
var guide_counts:Dictionary={}
func guide_position(id:StringName)->Vector2:
	return Vector2(1100 if id==&"GUIDE_LIN" else 1160,550)
func reserve_guide(index:int,hall:StringName)->StringName:
	for id in paid_ids:
		var definition:MuseumStaffDefinition=MuseumStaffService.catalog()[id]
		if definition.job!=&"GUIDE" or not ready_guides.has(id) or state.staff.members[id].assigned_hall!=hall or id in reservations.values():continue
		if int(guide_counts.get(str(id),0))>=definition.work_capacity:continue
		reservations[index]=id
		return id
	return &""
func complete_guide(index:int,id:StringName)->bool:
	if reservations.get(index,&"")!=id:return false
	reservations.erase(index)
	if not ready_guides.has(id) or id not in paid_ids:return false
	guide_counts[str(id)]=guide_counts.get(str(id),0)+1
	return true
func cancel_guide(index:int)->void:reservations.erase(index)
