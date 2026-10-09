class_name MuseumOperatingFinance
extends RefCounted
## One closure = one maintenance settlement. Gross tickets never become net tickets.
static func settle(state:MuseumState,business:MuseumBusiness)->bool:
	if state.daily_reports.has(state.day_number):return false
	var due:=business.maintenance_budget
	var paid:=mini(state.cash,due)
	state.cash-=paid
	if paid>0:state.facilities.record(state.day_number,"MAINTENANCE","DAY_"+str(state.day_number),paid,0,0)
	if business.workday!=null:business.workday.commit_tasks()
	var wages:=business.workday.wages_paid if business.workday!=null else 0
	if state.staff.payroll_days.has(state.day_number):state.staff.payroll_days[state.day_number]["settled"]=true
	MuseumCollectionCare.exhibition_history(state)
	var report:=MuseumDailyReport.create(state,business)
	report.values.merge({"maintenance_due":due,"maintenance_paid":paid,"maintenance_waived":due-paid,"operating_net_income":business.income_today-paid-wages,"staff_wages_paid":wages,"staff_repair_fees":business.workday.repair_fees_paid if business.workday!=null else 0,"staff_guide_counts":business.workday.guide_counts.duplicate() if business.workday!=null else {},"staff_task_counts":business.workday.completed_counts.duplicate() if business.workday!=null else {},"construction_at_close":MuseumConstructionService.capital_today(state)})
	return MuseumDailyReport.store(state,report)

static func net_for_day(state:MuseumState,day:int)->int:
	# Legacy reports have no maintenance: their gross remains their net, without mutation.
	var report:Dictionary=state.daily_reports.get(day,{})
	return int(report.get("operating_net_income",report.get("ticket_income",0)))
