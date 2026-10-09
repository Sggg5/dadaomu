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
var note:String=""
func values()->Dictionary:
	return {"task_id":task_id,"instance_id":str(instance_id),"job":str(job),"staff_id":str(staff_id),"status":str(status),"created_day":created_day,"completed_day":completed_day,"fee_paid":fee_paid,"note":note}
