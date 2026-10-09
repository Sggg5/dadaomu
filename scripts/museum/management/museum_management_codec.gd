class_name MuseumManagementCodec
extends RefCounted
## v6 pure-value management extension. Failure protects the source; no replayed cash.
static func encode(state:MuseumState)->Dictionary:
	var plans:Dictionary={}
	for hall in state.exhibition_plans:plans[str(hall)]=str(state.exhibition_plans[hall])
	var reports:Array[Dictionary]=[]
	var days:=state.daily_reports.keys()
	days.sort()
	for day in days:reports.append(state.daily_reports[day].duplicate(true))
	return {"exhibition_plans":plans,"daily_reports":reports}
static func integer(value:Variant,low:int,high:int)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and value>=low and value<=high
static func decode(state:MuseumState,payload:Dictionary)->bool:
	if not payload.get("exhibition_plans") is Dictionary or not payload.get("daily_reports") is Array:return false
	var plans:Dictionary[StringName,StringName]={}
	for hall:Variant in payload.exhibition_plans:
		var topic:Variant=payload.exhibition_plans[hall]
		if not hall is String or not topic is String or not state.display_catalog.halls.has(StringName(hall)) or ExhibitionService.find(StringName(topic))==null:return false
		if state.display_catalog.halls[StringName(hall)].unlock_level>state.museum_level:return false
		plans[StringName(hall)]=StringName(topic)
	var reports:Dictionary[int,Dictionary]={}
	if payload.daily_reports.size()>10000:return false
	for report:Variant in payload.daily_reports:
		if not report is Dictionary or not integer(report.get("day_number"),1,state.day_number):return false
		var day:int=int(report.day_number)
		if reports.has(day):return false
		for key in ["visitor_count","ticket_income","total_exhibit_count","museum_level","exhibit_appeal","view_count","artifact_views","unique_viewers","unique_artifacts"]:
			if not integer(report.get(key),0,1000000000):return false
		if report.museum_level>MuseumState.LEVELS.highest_level() or report.total_exhibit_count>81 or report.unique_viewers>report.visitor_count or report.unique_artifacts>report.artifact_views:return false
		for key in ["hall_visit_statistics","popular_units","active_exhibitions","exhibition_scores","exhibition_visits","interest_distribution"]:
			if not report.get(key) is Dictionary:return false
		for key in ["hall_visit_statistics","popular_units","exhibition_visits","interest_distribution"]:
			for id:Variant in report[key]:
				if not id is String or str(id).length()>100 or not integer(report[key][id],0,1000000000):return false
				if key=="hall_visit_statistics" and not state.display_catalog.halls.has(StringName(id)):return false
				if key=="popular_units" and not state.display_catalog.units.has(StringName(id)):return false
				if key=="exhibition_visits" and ExhibitionService.find(StringName(id))==null:return false
		for hall:Variant in report.active_exhibitions:
			if not hall is String or not state.display_catalog.halls.has(StringName(hall)) or not report.active_exhibitions[hall] is String or ExhibitionService.find(StringName(report.active_exhibitions[hall]))==null:return false
		for hall:Variant in report.exhibition_scores:
			var score:Variant=report.exhibition_scores[hall]
			if not report.active_exhibitions.has(hall) or not (score is int or score is float) or not is_finite(float(score)) or score<0 or score>200:return false
		if report.unique_viewers>report.view_count or report.view_count>report.visitor_count*2 or report.unique_artifacts>report.total_exhibit_count:return false
		var hall_total:=0
		var unit_total:=0
		var interest_total:=0
		for count:Variant in report.hall_visit_statistics.values():hall_total+=int(count)
		for count:Variant in report.popular_units.values():unit_total+=int(count)
		for count:Variant in report.interest_distribution.values():interest_total+=int(count)
		if hall_total!=report.view_count or unit_total!=report.view_count or interest_total!=report.artifact_views:return false
		var normalized:Dictionary=report.duplicate(true)
		for key in ["day_number","visitor_count","ticket_income","total_exhibit_count","museum_level","exhibit_appeal","view_count","artifact_views","unique_viewers","unique_artifacts"]:normalized[key]=int(normalized[key])
		for key in ["hall_visit_statistics","popular_units","exhibition_visits","interest_distribution"]:
			for id in normalized[key]:normalized[key][id]=int(normalized[key][id])
		for hall in normalized.exhibition_scores:normalized.exhibition_scores[hall]=float(normalized.exhibition_scores[hall])
		reports[day]=normalized
	state.exhibition_plans=plans
	state.daily_reports=reports
	return true
