extends "res://tests/phase_5b_smoke.gd"
func run()->void:
	var state:=preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(50)
	state.cash=2000
	MuseumStaffService.hire(state,&"GUIDE_LIN")
	MuseumConstructionService.purchase(state,MuseumConstructionService.quote(state,&"MAIN_GUIDE"))
	var museum:=Museum.new();museum.state=state;museum.config=MuseumConfig.new()
	museum.config.open_duration=20;museum.config.visitor_speed=1000;museum.config.view_duration=.1
	root.add_child(museum);await frames(3)
	check(museum.guide_nodes.size()==1 and museum.business.visits.staff_guides.is_empty(),"Guide actor exists but creates no visitors or services before opening")
	var cash:=state.cash
	museum.business.start();await frames(1000)
	check(museum.business.workday.wages_paid==10 and state.cash==cash-10+museum.business.income_today,"Opening pays actual guide wage once")
	check(museum.business.visits.staff_guides.get("GUIDE_LIN",0)>0,"Real paid visitor and guide actor finish guidance")
	check(museum.business.visits.staff_guides.get("GUIDE_LIN",0)<=8,"Guide daily capacity bounded")
	for visitor in museum.business.active:check(visitor.view_count<=3,"Board plus employee never exceeds three actual views")
	var context:=museum.business.workday
	context.reservations[999]=&"GUIDE_LIN"
	museum.guide_nodes[&"GUIDE_LIN"].queue_free();await frames(3)
	check(not context.ready_guides.has(&"GUIDE_LIN") and not context.reservations.has(999) and not context.complete_guide(999,&"GUIDE_LIN"),"Actual NPC unload cancels service without phantom credit")
	museum._sync_guides();await frames(3)
	check(is_instance_valid(museum.guide_nodes[&"GUIDE_LIN"]),"Scene refresh safely replaces freed guide reference")
	museum.switch_hall(&"EAST");await frames(3)
	check(not museum.guide_nodes[&"GUIDE_LIN"].visible,"Player hall switch preserves logical guide but hides wrong-hall actor")
	museum.business.close_now();await frames(240)
	check(museum.business.workday.reservations.is_empty() and not museum.business.running,"Closing cancels pending guidance without stuck visitor")
	museum.queue_free();await frames(3)
	var poor:=MuseumState.new();poor.cash=1000;MuseumStaffService.hire(poor,&"GUIDE_LIN");poor.cash=0
	poor.phase=MuseumState.Phase.OPEN
	var day:=MuseumStaffPayroll.begin(poor)
	check(day.paid_ids.is_empty() and day.wages_paid==0 and poor.cash==0,"Unfunded employee does not attend or create arrears")
	check(MuseumStaffPayroll.begin(poor).wages_paid==0,"Same-day payroll cannot run twice")
	print("[11F2] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
