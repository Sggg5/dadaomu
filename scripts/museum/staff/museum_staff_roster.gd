class_name MuseumStaffRoster
extends RefCounted
## Persistent members, terminal task history and expense journal. Dismissal never erases work.
var members:Dictionary[StringName,MuseumStaffMember]={}
var tasks:Array[MuseumStaffTask]=[]
var next_task_id:=1
var expenses:Array[Dictionary]=[]
var next_expense_id:=1
var payroll_days:Dictionary[int,Dictionary]={}
func record(day:int,kind:String,target:String,amount:int)->void:
	expenses.append({"expense_id":next_expense_id,"day_number":day,"kind":kind,"target_id":target,"amount":amount})
	next_expense_id+=1
func active_count()->int:
	var count:=0
	for member in members.values():
		if member.employment_status==&"ACTIVE":count+=1
	return count
