class_name MuseumStaffTask
extends RefCounted
## Durable work record; running progress belongs to the temporary business workday.
var task_id:int
var instance_id:StringName
var job:StringName
var staff_id:StringName
var status:StringName=&"PENDING"
var created_day:int
var completed_day:=0
var fee_paid:=0
var worked_seconds:=0.0
var note:String=""
var work_kind:StringName=&""
var target_level:=0
func action()->StringName:return work_kind if work_kind!=&"" else &"APPRAISE" if job==&"APPRAISER" else &"RESTORE"
func duration()->float:
	var seconds:float=MuseumStaffService.catalog()[staff_id].seconds_per_task
	if action()==&"RESEARCH":seconds*=float(ResearchDefinition.rules().type_seconds_multiplier if target_level==2 else ResearchDefinition.rules().topic_seconds_multiplier)
	if action()==&"INSPECT":seconds*=float(ResearchDefinition.rules().inspection_seconds_multiplier)
	return seconds
func values()->Dictionary:
	return {"task_id":task_id,"instance_id":str(instance_id),"job":str(job),"staff_id":str(staff_id),"status":str(status),"created_day":created_day,"completed_day":completed_day,"worked_seconds":worked_seconds,"fee_paid":fee_paid,"note":note,"work_kind":str(work_kind),"target_level":target_level}
