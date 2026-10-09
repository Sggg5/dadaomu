class_name MuseumOverview
extends RefCounted
## Read-only management projection. Forecasts never change cash or ownership.
static func snapshot(state: MuseumState, business: MuseumBusiness) -> Dictionary:
	var identified := 0
	for item in state.collection.all_items():
		if item.identified: identified += 1
	var halls: Array[Dictionary] = []
	var capacity := 0
	var used_units := 0
	for hall_id in [&"MAIN", &"EAST", &"WEST"]:
		var hall: ExhibitionHallDefinition = state.display_catalog.halls[hall_id]
		var row := {"id":hall_id,"name":hall.display_name,"unlocked":hall.unlock_level<=state.museum_level,"units":0,"slots":0,"displayed":0,"appeal":0,"empty_units":0}
		for id in state.display_catalog.unit_ids(state.museum_level,hall_id):
			var unit: DisplayUnitDefinition = state.display_catalog.units[id]
			var count := state.unit_items(id).size()
			row.units += 1
			row.slots += unit.capacity
			row.displayed += count
			row.appeal += state.unit_appeal(id)
			if count==0: row.empty_units += 1
			else: used_units += 1
		capacity += row.slots
		halls.append(row)
	return {"level":state.level_definition().display_name,"cash":state.cash,"owned":state.collection.all_items().size(),"identified":identified,"displayed":state.display_assignments.size(),"stored":state.collection.all_items().size()-state.display_assignments.size(),"capacity":capacity,"used_units":used_units,"halls":halls,"appeal":state.total_appeal(),"forecast_visitors":business.visitor_target(state.total_appeal()+ExhibitionService.bonus_appeal(state),state.display_assignments.size()),"live_visitors":business.visitors_today,"live_income":business.income_today,"last_visitors":state.last_day_visitors,"last_income":state.last_day_ticket_income}
