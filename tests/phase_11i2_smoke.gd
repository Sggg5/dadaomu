extends "res://tests/phase_11a_smoke.gd"
## Accelerated actual business, not full GameFlow / human playtest.
func run()->void:
	var path:=""
	var scenario:="first_income"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--checkpoint="):path=arg.trim_prefix("--checkpoint=")
		if arg.begins_with("--scenario="):scenario=arg.trim_prefix("--scenario=")
	check(path.begins_with("res://logs/11i_earned_") and FileAccess.file_exists(path),"Isolated earned checkpoint required")
	if failures>0:quit(1);return
	var source:=MuseumProfileStore.new();source.save_path=path
	var initial:=source.load_profile();check(not source.write_blocked,"Earned checkpoint safely decodes")
	var output:Array=[]
	for strategy in ["A","B","C"]:
		var memory:=MuseumProfileStore.in_memory();memory._memory=source.encode(initial)
		var state:=memory.load_profile()
		var museum:=preload("res://scenes/museum/museum.tscn").instantiate() as Museum
		museum.state=state;museum.config=preload("res://data/museum/default_config.tres").duplicate()
		root.add_child(museum);await frames(4)
		var rows:Array=[];var hired:=false;var investments:=0
		var item:=state.collection.all_items()[0]
		MuseumResearchService.register(state,item.instance_id)
		if strategy=="A":
			for id in MuseumStaffService.active_ids(state):MuseumStaffService.dismiss(state,id)
		var unit:=""
		for display in museum.cases:
			if item in state.unit_items(display.case_id):unit=str(display.case_id)
		var facility:=StringName(unit+":LIGHT")
		for offset in range(30):
			state.day_number=initial.day_number+offset+1;state.phase=MuseumState.Phase.MORNING
			var opening:=state.cash;var hire_cost:=0;var construction_cost:=0
			if strategy=="B" and not hired:
				var staff_id:=&"CONSERVATOR_SU" if state.staff.members.has(&"APPRAISER_SHEN") else &"APPRAISER_SHEN"
				var definition:MuseumStaffDefinition=MuseumStaffService.catalog()[staff_id]
				if state.cash>=definition.hire_cost+definition.daily_wage:
					hired=MuseumStaffService.hire(state,staff_id)
					if hired:
						hire_cost=definition.hire_cost
						if definition.job==&"APPRAISER":MuseumStaffTasks.enqueue(state,staff_id,item.instance_id,&"RESEARCH",2)
			if strategy=="B" and state.staff.members.has(&"CONSERVATOR_SU"):
				for owned in state.collection.all_items():
					if MuseumStaffTasks.eligible(state,&"CONSERVATOR",owned.instance_id):MuseumStaffTasks.enqueue(state,&"CONSERVATOR_SU",owned.instance_id)
			if strategy=="C" and investments<1:
				var quote:=MuseumConstructionService.quote(state,facility)
				if quote!=null and state.cash>=quote.price:
					construction_cost=quote.price
					check(MuseumConstructionService.purchase(state,quote),"Actual facility investment")
					investments+=1
			check(museum.business.start(),"Real accelerated business %s day%d"%[strategy,state.day_number])
			for frame in range(6000):
				await frames(1)
				if state.phase==MuseumState.Phase.EVENING:break
			check(state.daily_reports.has(state.day_number),"Actual close report")
			var report:Dictionary=state.daily_reports[state.day_number]
			var delta:int=report.ticket_income-report.maintenance_paid-report.staff_wages_paid-report.staff_repair_fees-hire_cost-construction_cost
			check(state.cash==opening+delta and state.cash>=0,"Daily cash reconciles without debt")
			check(not museum.business.start(),"Same day reopening rejected")
			var rating:=MuseumReputationService.evaluate(state)
			rows.append({"day":state.day_number,"opening":opening,"ticket_income":report.ticket_income,"wages":report.staff_wages_paid,"maintenance":report.maintenance_paid,"repair":report.staff_repair_fees,"hire":hire_cost,"construction":construction_cost,"cash":state.cash,"visitors":museum.business.visitors_today,"collection":state.collection.all_items().size(),"displayed":state.display_assignments.size(),"rating":rating.rank,"score":rating.score,"goals":state.achievements.keys()})
		output.append({"strategy":strategy,"method":"ACTUAL_BUSINESS_FORMAL_60_SECONDS_FIXED_FPS_DATE_ADVANCED_BY_FIXTURE","checkpoint":path,"initial_cash":initial.cash,"initial_artifacts":initial.collection.all_items().size(),"new_acquisitions":0,"rows":rows})
		museum.queue_free();await frames(4)
	var file:=FileAccess.open("res://logs/11i_economy_%s.json"%scenario,FileAccess.WRITE);file.store_string(JSON.stringify(output,"  "));file.close()
	print("[11I2] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)

