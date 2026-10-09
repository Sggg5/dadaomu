class_name MuseumOperatingFinance
extends RefCounted
## One closure = one maintenance settlement. Gross tickets never become net tickets.
static func settle(state:MuseumState,business:MuseumBusiness)->bool:
	if state.daily_reports.has(state.day_number):return false
	var due:=business.maintenance_budget
	var paid:=mini(state.cash,due)
	var report:=MuseumDailyReport.create(state,business)
	report.values.merge({"maintenance_due":due,"maintenance_paid":paid,"maintenance_waived":due-paid,"operating_net_income":business.income_today-paid,"construction_at_close":MuseumConstructionService.capital_today(state)})
	state.cash-=paid
	if paid>0:state.facilities.record(state.day_number,"MAINTENANCE","DAY_"+str(state.day_number),paid,0,0)
	return MuseumDailyReport.store(state,report)
