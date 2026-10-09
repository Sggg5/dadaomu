class_name MuseumDailyReport
extends RefCounted
## Immutable-value daily report. Ticket cash was earned once at payment, never here.
var values:Dictionary={}
static func create(state:MuseumState,business:MuseumBusiness)->MuseumDailyReport:
	var report:=MuseumDailyReport.new()
	var topics:Dictionary={}
	var scores:Dictionary={}
	for hall in state.exhibition_plans:
		var evaluation:=ExhibitionService.active(state,hall)
		if evaluation.qualified:
			topics[str(hall)]=str(state.exhibition_plans[hall])
			scores[str(hall)]=evaluation.score
	var stats:=business.visits.snapshot()
	report.values={"view_limit":3 if state.facilities.level(&"MAIN_GUIDE")>0 or not stats.staff_guides.is_empty() else 2,"service_visits":stats.service_visits,"day_number":state.day_number,"visitor_count":business.visitors_today,"ticket_income":business.income_today,"total_exhibit_count":state.display_assignments.size(),"museum_level":state.museum_level,"exhibit_appeal":state.total_appeal(),"hall_visit_statistics":stats.hall_visits,"popular_units":stats.unit_visits,"active_exhibitions":topics,"exhibition_scores":scores,"view_count":stats.view_count,"artifact_views":stats.artifact_views,"unique_viewers":stats.unique_viewers,"unique_artifacts":stats.unique_artifacts,"exhibition_visits":stats.topic_visits,"interest_distribution":stats.interests}
	return report
static func store(state:MuseumState,report:MuseumDailyReport)->bool:
	var day:int=report.values.day_number
	if state.daily_reports.has(day):return false
	state.daily_reports[day]=report.values.duplicate(true)
	MuseumMilestoneService.observe(state,"REPORT")
	return true
static func recent(state:MuseumState,page:int=0,page_size:int=5)->Array[Dictionary]:
	var days:=state.daily_reports.keys()
	days.sort()
	days.reverse()
	var result:Array[Dictionary]=[]
	var size:=clampi(page_size,1,10)
	for index in range(maxi(0,page)*size,mini(days.size(),maxi(0,page)*size+size)):
		result.append(state.daily_reports[days[index]].duplicate(true))
	return result
static func totals(state:MuseumState)->Dictionary:
	var visitors:=0
	var income:=0
	for report in state.daily_reports.values():
		visitors+=int(report.visitor_count)
		income+=int(report.ticket_income)
	return {"visitors":visitors,"income":income,"days":state.daily_reports.size()}
