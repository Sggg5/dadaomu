class_name MuseumStaffCodec
extends RefCounted
## VERSION8 staff extension. Decode into a temporary roster; reject conflicts before installation.
static func encode(state:MuseumState)->Dictionary:
	var members:Array=[];var tasks:Array=[];var days:Dictionary={}
	var ids:=state.staff.members.keys();ids.sort_custom(func(a:StringName,b:StringName)->bool:return str(a)<str(b))
	for id in ids:
		var m:MuseumStaffMember=state.staff.members[id]
		var d:MuseumStaffDefinition=MuseumStaffService.catalog()[id]
		members.append({"staff_id":str(id),"job":str(d.job),"skill_level":d.skill_level,"assigned_hall":str(m.assigned_hall),"employment_status":str(m.employment_status),"last_attended_day":m.last_attended_day,"last_completed_count":m.last_completed_count})
	for task in state.staff.tasks:tasks.append(task.values())
	for day in state.staff.payroll_days:days[str(day)]=state.staff.payroll_days[day].duplicate(true)
	return {"staff_config_version":1,"staff_members":members,"staff_tasks":tasks,"staff_next_task":state.staff.next_task_id,"staff_expenses":state.staff.expenses.duplicate(true),"staff_next_expense":state.staff.next_expense_id,"staff_payroll_days":days}
static func safe_to_save(state:MuseumState)->bool:
	for day in state.staff.payroll_days:
		if not state.staff.payroll_days[day].get("settled",false) or not state.daily_reports.has(day):return false
	return true
static func decode(state:MuseumState,payload:Dictionary)->bool:
	if payload.get("staff_config_version")!=1:return false
	for key in ["staff_members","staff_tasks","staff_expenses"]:
		if not payload.get(key) is Array or payload[key].size()>100000:return false
	if not payload.get("staff_payroll_days") is Dictionary:return false
	var roster:=MuseumStaffRoster.new();var catalog:=MuseumStaffService.catalog()
	var job_counts:Dictionary={}
	for row:Variant in payload.staff_members:
		if not row is Dictionary or not row.get("staff_id") is String:return false
		var id:=StringName(row.staff_id)
		if not catalog.has(id) or roster.members.has(id):return false
		var d:MuseumStaffDefinition=catalog[id]
		if row.get("job")!=str(d.job) or row.get("skill_level")!=d.skill_level or row.get("employment_status") not in ["ACTIVE","DISMISSED"] or not row.get("assigned_hall") is String:return false
		var hall:=StringName(row.assigned_hall)
		if not state.display_catalog.halls.has(hall) or hall not in state.display_catalog.hall_ids(state.museum_level):return false
		if not MuseumManagementCodec.integer(row.get("last_attended_day"),0,state.day_number) or not MuseumManagementCodec.integer(row.get("last_completed_count"),0,d.work_capacity):return false
		var member:=MuseumStaffMember.new();member.staff_id=id;member.assigned_hall=hall;member.employment_status=StringName(row.employment_status)
		member.last_attended_day=int(row.last_attended_day);member.last_completed_count=int(row.last_completed_count);roster.members[id]=member
		if member.employment_status==&"ACTIVE":job_counts[str(d.job)]=int(job_counts.get(str(d.job),0))+1
	for count in job_counts.values():
		if count>MuseumStaffService.max_per_job:return false
	if roster.active_count()>MuseumStaffService.max_staff:return false
	var pending_instances:Dictionary={}
	for row:Variant in payload.staff_tasks:
		if not row is Dictionary or row.get("task_id")!=roster.next_task_id or not row.get("staff_id") is String or not row.get("instance_id") is String:return false
		var id:=StringName(row.staff_id)
		var suffix:String=row.instance_id.trim_prefix("A")
		if not row.instance_id.begins_with("A") or not suffix.is_valid_int() or suffix.to_int()<1:return false
		if row.get("status") in ["PENDING","WAITING_FUNDS"]:
			if pending_instances.has(row.instance_id):return false
			pending_instances[row.instance_id]=true
		if not roster.members.has(id) or row.get("job")!=str(catalog[id].job) or row.job=="GUIDE":return false
		if row.get("status") not in ["PENDING","WAITING_FUNDS","CANCELLED","COMPLETED"] or not row.get("note") is String:return false
		for key in ["created_day","completed_day","fee_paid"]:
			if not MuseumManagementCodec.integer(row.get(key),0,1000000000):return false
		if row.created_day<1 or row.created_day>state.day_number or row.completed_day>state.day_number:return false
		if int(payload.version)>=9 and (not row.get("work_kind","") is String or not MuseumManagementCodec.integer(row.get("target_level",0),0,3)):return false
		var kind:StringName=StringName(row.get("work_kind","")) if int(payload.version)>=9 else &""
		var target:int=int(row.get("target_level",0)) if int(payload.version)>=9 else 0
		var effective:=kind if kind!=&"" else &"APPRAISE" if row.job=="APPRAISER" else &"RESTORE"
		if effective not in ([&"APPRAISE",&"RESEARCH"] if row.job=="APPRAISER" else [&"RESTORE",&"INSPECT"]):return false
		if (effective==&"RESEARCH" and target not in [2,3]) or (effective!=&"RESEARCH" and target!=0):return false
		var temporary_task:=MuseumStaffTask.new();temporary_task.staff_id=id;temporary_task.job=StringName(row.job);temporary_task.work_kind=kind;temporary_task.target_level=target
		var duration:=temporary_task.duration()
		if not (row.get("worked_seconds") is float or row.get("worked_seconds") is int) or not is_finite(float(row.worked_seconds)) or row.worked_seconds<0 or row.worked_seconds>duration:return false
		if row.status=="COMPLETED" and (row.completed_day<row.created_day or row.worked_seconds<duration):return false
		if row.status!="COMPLETED" and (row.completed_day!=0 or row.fee_paid!=0):return false
		if effective!=&"RESTORE" and row.fee_paid!=0:return false
		if effective==&"RESTORE" and row.status=="COMPLETED" and row.fee_paid<=0:return false
		var task:=MuseumStaffTask.new()
		task.work_kind=kind;task.target_level=target
		task.task_id=int(row.task_id);task.staff_id=id;task.instance_id=StringName(row.instance_id);task.job=StringName(row.job);task.status=StringName(row.status)
		task.created_day=int(row.created_day);task.completed_day=int(row.completed_day);task.worked_seconds=float(row.worked_seconds);task.fee_paid=int(row.fee_paid);task.note=row.note
		roster.tasks.append(task);roster.next_task_id+=1
	var hires:Dictionary={};var wages:Dictionary={};var repairs:Dictionary={}
	var previous_day:=0
	for row:Variant in payload.staff_expenses:
		if not row is Dictionary or row.get("expense_id")!=roster.next_expense_id or not row.get("target_id") is String:return false
		if not MuseumManagementCodec.integer(row.get("day_number"),1,state.day_number) or not MuseumManagementCodec.integer(row.get("amount"),1,1000000000):return false
		if int(row.day_number)<previous_day:return false
		previous_day=int(row.day_number)
		var target:=StringName(row.target_id)
		if row.get("kind")=="HIRE":
			if not roster.members.has(target) or row.amount!=catalog[target].hire_cost:return false
			hires[target]=true
		elif row.get("kind")=="WAGES":
			var key:=str(int(row.day_number))+":"+str(target)
			if not hires.has(target) or row.amount!=catalog[target].daily_wage or wages.has(key):return false
			wages[key]=int(row.amount)
		elif row.get("kind")=="STAFF_REPAIR":
			if not row.target_id.is_valid_int():return false
			var tid:int=int(row.target_id)
			if tid<1 or tid>=roster.next_task_id or repairs.has(tid):return false
			var task:MuseumStaffTask=roster.tasks[tid-1]
			if task.status!=&"COMPLETED" or task.job!=&"CONSERVATOR" or task.fee_paid!=row.amount or task.completed_day!=row.day_number:return false
			repairs[tid]=true
		else:return false
		var normalized:Dictionary=row.duplicate(true)
		for key in ["expense_id","day_number","amount"]:normalized[key]=int(normalized[key])
		roster.expenses.append(normalized);roster.next_expense_id+=1
	for id in roster.members:
		if not hires.has(id):return false
	for task in roster.tasks:
		if task.fee_paid>0 and not repairs.has(task.task_id):return false
	var wage_keys:Dictionary={}
	for key:Variant in payload.staff_payroll_days:
		if not key is String or not key.is_valid_int():return false
		var day:int=int(key);var row:Variant=payload.staff_payroll_days[key]
		if day<1 or day>state.day_number or not row is Dictionary or row.get("settled")!=true or not row.get("paid_ids") is Array or not state.daily_reports.has(day):return false
		var total:=0;var seen:Dictionary={};var normalized_ids:Array[String]=[]
		for id:Variant in row.paid_ids:
			if not id is String or not roster.members.has(StringName(id)) or seen.has(id):return false
			var wk:String=str(day)+":"+id
			if not wages.has(wk):return false
			total+=wages[wk];seen[id]=true;wage_keys[wk]=true;normalized_ids.append(id)
		if row.get("wages_paid")!=total or state.daily_reports[day].get("staff_wages_paid",0)!=total:return false
		roster.payroll_days[day]={"paid_ids":normalized_ids,"wages_paid":total,"settled":true}
	if wage_keys.size()!=wages.size() or payload.get("staff_next_task")!=roster.next_task_id or payload.get("staff_next_expense")!=roster.next_expense_id:return false
	for day in state.daily_reports:
		var report:Dictionary=state.daily_reports[day]
		if not MuseumManagementCodec.integer(report.get("staff_wages_paid",0),0,1000000000) or not MuseumManagementCodec.integer(report.get("staff_repair_fees",0),0,1000000000):return false
		if report.get("staff_wages_paid",0)>0 and not roster.payroll_days.has(day):return false
		var fees:=0
		for expense in roster.expenses:
			if expense.day_number==day and expense.kind=="STAFF_REPAIR":fees+=expense.amount
		if report.get("staff_repair_fees",0)!=fees:return false
		for field in ["staff_guide_counts","staff_task_counts"]:
			if report.has(field):
				if not report[field] is Dictionary:return false
				for id in report[field]:
					if not catalog.has(StringName(id)) or not MuseumManagementCodec.integer(report[field][id],0,catalog[StringName(id)].work_capacity):return false
		var attendance:Array=roster.payroll_days.get(day,{"paid_ids":[]}).paid_ids
		var task_counts:Dictionary={}
		for task in roster.tasks:
			if task.status==&"COMPLETED" and task.completed_day==day:
				if str(task.staff_id) not in attendance:return false
				task_counts[str(task.staff_id)]=int(task_counts.get(str(task.staff_id),0))+1
		var actual_counts:Dictionary=report.get("staff_task_counts",{})
		if actual_counts.size()!=task_counts.size():return false
		for id in actual_counts:
			if not task_counts.has(id) or actual_counts[id]!=task_counts[id]:return false
		for id in report.get("staff_guide_counts",{}):
			if id not in attendance or catalog[StringName(id)].job!=&"GUIDE" or report.staff_guide_counts[id]>report.visitor_count:return false
		for field in ["staff_wages_paid","staff_repair_fees"]:
			if report.has(field):report[field]=int(report[field])
		for field in ["staff_guide_counts","staff_task_counts"]:
			if report.has(field):
				for id in report[field]:report[field][id]=int(report[field][id])
	state.staff=roster
	MuseumStaffTasks.reconcile(state)
	return true




