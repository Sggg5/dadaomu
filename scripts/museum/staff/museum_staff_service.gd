class_name MuseumStaffService
extends RefCounted
static var _catalog:Dictionary[StringName,MuseumStaffDefinition]={}
static func catalog()->Dictionary[StringName,MuseumStaffDefinition]:
	if _catalog.is_empty():
		var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/museum/staff.json"))
		for row:Dictionary in data.templates:
			var definition:=MuseumStaffDefinition.new()
			definition.staff_id=StringName(row.staff_id)
			definition.display_name=row.display_name
			definition.job=StringName(row.job)
			definition.daily_wage=row.daily_wage
			definition.hire_cost=row.hire_cost
			definition.skill_level=row.skill_level
			definition.work_capacity=row.work_capacity
			definition.seconds_per_task=row.seconds_per_task
			_catalog[definition.staff_id]=definition
	return _catalog
static func hire(state:MuseumState,id:StringName)->bool:
	var definition:MuseumStaffDefinition=catalog().get(id)
	if not state.can_edit() or definition==null or state.cash<definition.hire_cost or state.staff.active_count()>=6:return false
	if state.staff.members.has(id) and state.staff.members[id].employment_status==&"ACTIVE":return false
	var same_job:=0
	for member in state.staff.members.values():
		if member.employment_status==&"ACTIVE" and catalog()[member.staff_id].job==definition.job:same_job+=1
	if same_job>=2:return false
	var member:=MuseumStaffMember.new()
	member.staff_id=id
	state.cash-=definition.hire_cost
	state.staff.members[id]=member
	state.staff.record(state.day_number,"HIRE",str(id),definition.hire_cost)
	state.changed.emit()
	return true
static func dismiss(state:MuseumState,id:StringName)->bool:
	if not state.can_edit() or not state.staff.members.has(id) or state.staff.members[id].employment_status!=&"ACTIVE":return false
	state.staff.members[id].employment_status=&"DISMISSED"
	for task in state.staff.tasks:
		if task.staff_id==id and task.status in [&"PENDING",&"WAITING_FUNDS"]:
			task.status=&"CANCELLED"
			task.note="员工离职，任务取消；记录保留"
	state.changed.emit()
	return true
static func assign_hall(state:MuseumState,id:StringName,hall:StringName)->bool:
	if not state.can_edit() or not state.staff.members.has(id) or state.staff.members[id].employment_status!=&"ACTIVE" or catalog()[id].job!=&"GUIDE" or hall not in state.display_catalog.hall_ids(state.museum_level):return false
	state.staff.members[id].assigned_hall=hall
	state.changed.emit()
	return true
static func active_ids(state:MuseumState)->Array[StringName]:
	var ids:Array[StringName]=[]
	for id in state.staff.members:
		if state.staff.members[id].employment_status==&"ACTIVE":ids.append(id)
	ids.sort_custom(func(a:StringName,b:StringName)->bool:return str(a)<str(b))
	return ids
