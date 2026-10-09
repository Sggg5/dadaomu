class_name MuseumStaffTasks
extends RefCounted
static func eligible(state:MuseumState,job:StringName,id:StringName)->bool:
	var item:=state.collection.find(id)
	if item==null or state.is_auction_locked(id):return false
	return not item.identified if job==&"APPRAISER" else item.identified and item.condition<100 and state.restoration_cost(id)>0 if job==&"CONSERVATOR" else false
static func enqueue(state:MuseumState,staff_id:StringName,instance_id:StringName)->MuseumStaffTask:
	if not state.can_edit() or not state.staff.members.has(staff_id) or state.staff.members[staff_id].employment_status!=&"ACTIVE":return null
	var job:StringName=MuseumStaffService.catalog()[staff_id].job
	if not eligible(state,job,instance_id):return null
	for task in state.staff.tasks:
		if task.instance_id==instance_id and task.status in [&"PENDING",&"WAITING_FUNDS"]:return null
	var task:=MuseumStaffTask.new()
	task.task_id=state.staff.next_task_id;state.staff.next_task_id+=1
	task.staff_id=staff_id;task.instance_id=instance_id;task.job=job;task.created_day=state.day_number
	state.staff.tasks.append(task)
	state.changed.emit()
	return task
static func cancel(state:MuseumState,task_id:int)->bool:
	if not state.can_edit():return false
	for task in state.staff.tasks:
		if task.task_id==task_id and task.status in [&"PENDING",&"WAITING_FUNDS"]:
			task.status=&"CANCELLED";task.note="馆长取消任务，记录保留"
			state.changed.emit();return true
	return false
static func reconcile(state:MuseumState)->void:
	for task in state.staff.tasks:
		if task.status not in [&"PENDING",&"WAITING_FUNDS"]:continue
		if not state.staff.members.has(task.staff_id) or state.staff.members[task.staff_id].employment_status!=&"ACTIVE" or not eligible(state,task.job,task.instance_id):
			task.status=&"CANCELLED"
			task.note="实例不存在、已手动作业、待拍或员工离职，安全跳过"
