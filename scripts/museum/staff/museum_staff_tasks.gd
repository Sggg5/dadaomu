class_name MuseumStaffTasks
extends RefCounted
static func eligible(state:MuseumState,job:StringName,id:StringName)->bool:
	var item:=state.collection.find(id)
	if item==null or state.is_auction_locked(id):return false
	if job==&"APPRAISER":return not item.identified
	if job==&"CONSERVATOR":return item.identified and item.condition<100 and state.restoration_cost(id)>0
	return false
static func enqueue(state:MuseumState,staff_id:StringName,instance_id:StringName,work_kind:StringName=&"",target_level:int=0)->MuseumStaffTask:
	if not state.can_edit() or not state.staff.members.has(staff_id) or state.staff.members[staff_id].employment_status!=&"ACTIVE":return null
	var job:StringName=MuseumStaffService.catalog()[staff_id].job
	var action:=work_kind if work_kind!=&"" else &"APPRAISE" if job==&"APPRAISER" else &"RESTORE"
	if action==&"RESEARCH":
		if job!=&"APPRAISER" or not MuseumResearchService.eligible(state,instance_id,target_level):return null
	elif action!=(&"APPRAISE" if job==&"APPRAISER" else &"RESTORE" if job==&"CONSERVATOR" else &"NONE") or target_level!=0 or not eligible(state,job,instance_id):return null
	for task in state.staff.tasks:
		if task.instance_id==instance_id and task.status in [&"PENDING",&"WAITING_FUNDS"]:return null
	var task:=MuseumStaffTask.new()
	task.task_id=state.staff.next_task_id;state.staff.next_task_id+=1
	task.staff_id=staff_id;task.instance_id=instance_id;task.job=job;task.work_kind=work_kind;task.target_level=target_level;task.created_day=state.day_number
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
		if not state.staff.members.has(task.staff_id) or state.staff.members[task.staff_id].employment_status!=&"ACTIVE" or not task_eligible(state,task):
			task.status=&"CANCELLED"
			task.note="实例不存在、已手动作业、待拍或员工离职，安全跳过"

static func task_eligible(state:MuseumState,task:MuseumStaffTask)->bool:
	if task.action()==&"RESEARCH":return task.job==&"APPRAISER" and MuseumResearchService.eligible(state,task.instance_id,task.target_level)
	return eligible(state,task.job,task.instance_id)
