class_name MuseumStaffPayroll
extends RefCounted
## Opening-time all-or-nothing wage per employee. Unfunded staff stop, no arrears.
static func begin(state:MuseumState)->MuseumStaffWorkday:
	var context:=MuseumStaffWorkday.new()
	context.state=state
	context.day=state.day_number
	if state.staff.active_count()==0:return context
	if state.staff.payroll_days.has(state.day_number):return context
	var attendance:Array[String]=[]
	for id in MuseumStaffService.active_ids(state):
		var definition:MuseumStaffDefinition=MuseumStaffService.catalog()[id]
		if state.cash<definition.daily_wage:continue
		state.cash-=definition.daily_wage
		context.paid_ids.append(id)
		context.wages_paid+=definition.daily_wage
		attendance.append(str(id))
		state.staff.record(state.day_number,"WAGES",str(id),definition.daily_wage)
	state.staff.payroll_days[state.day_number]={"paid_ids":attendance,"wages_paid":context.wages_paid}
	return context
