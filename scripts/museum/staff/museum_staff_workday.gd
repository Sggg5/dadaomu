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
	return Vector2(900 if id==&"GUIDE_LIN" else 1160,470)
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

var progress:Dictionary[int,float]={}
var prepared:Dictionary[int,StringName]={}
var prepared_counts:Dictionary={}
var completed_counts:Dictionary={}
var completed_ids:Array[int]=[]
var repair_fees_paid:=0
var tasks_committed:=false
func advance_tasks(delta:float,time_scale:float)->void:
	if tasks_committed or state.phase!=MuseumState.Phase.OPEN or state.day_number!=day:return
	MuseumStaffTasks.reconcile(state)
	for id in paid_ids:
		var definition:MuseumStaffDefinition=MuseumStaffService.catalog()[id]
		if definition.job==&"GUIDE" or int(prepared_counts.get(str(id),0))>=definition.work_capacity:continue
		for task in state.staff.tasks:
			if task.staff_id!=id or task.status not in [&"PENDING",&"WAITING_FUNDS"] or prepared.has(task.task_id):continue
			var reserved:=0
			for task_id in prepared:
				for candidate in state.staff.tasks:
					if candidate.task_id==task_id and candidate.job==&"CONSERVATOR":reserved+=state.restoration_cost(candidate.instance_id)
			if task.job==&"CONSERVATOR" and state.cash-reserved<state.restoration_cost(task.instance_id):
				task.status=&"WAITING_FUNDS";task.note="修复资金不足，保留待处理"
				break
			task.status=&"PENDING"
			var seconds:float=progress.get(task.task_id,task.worked_seconds)+delta/maxf(.001,time_scale)
			progress[task.task_id]=minf(definition.seconds_per_task,seconds)
			if seconds>=definition.seconds_per_task:
				prepared[task.task_id]=id
				prepared_counts[str(id)]=prepared_counts.get(str(id),0)+1
			break
func task_progress(task:MuseumStaffTask)->float:
	var definition:MuseumStaffDefinition=MuseumStaffService.catalog()[task.staff_id]
	return minf(1.0,float(progress.get(task.task_id,task.worked_seconds))/definition.seconds_per_task)
func commit_tasks()->void:
	if tasks_committed:return
	tasks_committed=true
	MuseumStaffTasks.reconcile(state)
	for task in state.staff.tasks:
		if task.status not in [&"PENDING",&"WAITING_FUNDS"]:continue
		if progress.has(task.task_id):task.worked_seconds=progress[task.task_id]
		if not prepared.has(task.task_id) or not MuseumStaffTasks.eligible(state,task.job,task.instance_id):continue
		var item:=state.collection.find(task.instance_id)
		if task.job==&"CONSERVATOR":
			var cost:=state.restoration_cost(task.instance_id)
			if state.cash<cost:
				task.status=&"WAITING_FUNDS";task.note="结算后资金不足，待后续营业处理";continue
			state.cash-=cost
			task.fee_paid=cost
			repair_fees_paid+=cost
			state.staff.record(day,"STAFF_REPAIR",str(task.task_id),cost)
			item.condition=100
		else:item.identified=true
		task.status=&"COMPLETED";task.completed_day=day;task.note="真实营业作业完成，闭馆统一提交"
		completed_ids.append(task.task_id)
		completed_counts[str(task.staff_id)]=completed_counts.get(str(task.staff_id),0)+1
	for id in paid_ids:
		state.staff.members[id].last_attended_day=day
		state.staff.members[id].last_completed_count=int(guide_counts.get(str(id),0))+int(completed_counts.get(str(id),0))
