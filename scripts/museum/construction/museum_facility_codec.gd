class_name MuseumFacilityCodec
extends RefCounted
## v7 extension, verifies levels against the ordered expense chain and immutable daily totals.
static func encode(state:MuseumState)->Dictionary:
	var levels:Dictionary={}
	for id in state.facilities.levels:levels[str(id)]=state.facilities.level(id)
	var halls:=0
	for row in state.facilities.expenses:
		if row.kind=="HALL_EXPANSION":halls+=1
	return {"facility_config_version":1,"facility_levels":levels,"facility_expenses":state.facilities.expenses.duplicate(true),"facility_next_transaction":state.facilities.next_transaction,"facility_foundation_level":state.museum_level-halls}
static func decode(state:MuseumState,payload:Dictionary)->bool:
	if payload.get("facility_config_version")!=1 or not payload.get("facility_levels") is Dictionary or not payload.get("facility_expenses") is Array:return false
	if payload.facility_expenses.size()>10000 or not MuseumManagementCodec.integer(payload.get("facility_next_transaction"),1,1000000000) or not MuseumManagementCodec.integer(payload.get("facility_foundation_level"),0,state.museum_level):return false
	var restored:=MuseumFacilityState.new()
	var catalog:=MuseumConstructionService.definitions(state)
	var levels:Dictionary[StringName,int]={}
	var museum_level:int=int(payload.facility_foundation_level)
	var maintenance_days:Dictionary={}
	for row:Variant in payload.facility_expenses:
		if not row is Dictionary:return false
		for field in ["transaction_id","day_number","amount","from_level","to_level"]:
			if not MuseumManagementCodec.integer(row.get(field),0,1000000000):return false
		if row.transaction_id!=restored.next_transaction or row.day_number<1 or row.day_number>state.day_number or not row.get("kind") is String or not row.get("target_id") is String:return false
		if row.kind=="FACILITY_UPGRADE":
			var id:=StringName(row.target_id)
			if not catalog.has(id):return false
			var definition:MuseumFacilityDefinition=catalog[id]
			var before:int=levels.get(id,0)
			if definition.unlock_level>museum_level or row.from_level!=before or row.to_level!=before+1 or row.to_level>definition.max_level or row.amount!=int(definition.costs[before]):return false
			levels[id]=int(row.to_level)
		elif row.kind=="HALL_EXPANSION":
			if row.target_id!="MUSEUM" or row.from_level!=museum_level or row.to_level!=museum_level+1 or row.to_level>MuseumState.LEVELS.highest_level() or row.amount!=MuseumState.LEVELS.at(museum_level).upgrade_cost:return false
			museum_level+=1
		elif row.kind=="MAINTENANCE":
			var day:int=int(row.day_number)
			if row.target_id!="DAY_"+str(day) or maintenance_days.has(day) or not state.daily_reports.has(day) or row.amount<=0 or row.from_level!=0 or row.to_level!=0:return false
			if row.amount!=state.daily_reports[day].get("maintenance_paid",0):return false
			maintenance_days[day]=true
		else:return false
		var normalized:Dictionary=row.duplicate(true)
		for field in ["transaction_id","day_number","amount","from_level","to_level"]:normalized[field]=int(normalized[field])
		restored.expenses.append(normalized)
		restored.next_transaction+=1
	if museum_level!=state.museum_level or restored.next_transaction!=payload.facility_next_transaction or payload.facility_levels.size()!=levels.size():return false
	for key:Variant in payload.facility_levels:
		if not key is String or not levels.has(StringName(key)) or not MuseumManagementCodec.integer(payload.facility_levels[key],1,3) or payload.facility_levels[key]!=levels[StringName(key)]:return false
	for day in state.daily_reports:
		var report:Dictionary=state.daily_reports[day]
		if not validate_report(state,report):return false
		if report.get("maintenance_paid",0)>0 and not maintenance_days.has(day):return false
		report=report.duplicate(true)
		for field in ["view_limit","maintenance_due","maintenance_paid","maintenance_waived","operating_net_income","construction_at_close"]:
			if report.has(field):report[field]=int(report[field])
		if report.has("service_visits"):
			for key in report.service_visits:report.service_visits[key]=int(report.service_visits[key])
		state.daily_reports[day]=report
	restored.levels=levels
	state.facilities=restored
	return true
static func validate_report(state:MuseumState,report:Dictionary)->bool:
	var financial:=["maintenance_due","maintenance_paid","maintenance_waived","operating_net_income","construction_at_close"]
	var has_financial:=false
	for key in financial:
		if report.has(key):has_financial=true
	if has_financial:
		for key in financial:
			if not MuseumManagementCodec.integer(report.get(key),-1000000000 if key=="operating_net_income" else 0,1000000000):return false
		if report.maintenance_due!=report.maintenance_paid+report.maintenance_waived or report.operating_net_income!=report.ticket_income-report.maintenance_paid-report.get("staff_wages_paid",0):return false
	if report.has("service_visits"):
		if not report.service_visits is Dictionary:return false
		for id:Variant in report.service_visits:
			if not id is String or id not in ["MAIN_GUIDE","EAST_REST","MAIN_RECEPTION"] or not MuseumManagementCodec.integer(report.service_visits[id],0,report.visitor_count):return false
	return true
