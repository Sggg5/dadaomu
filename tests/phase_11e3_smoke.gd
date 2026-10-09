extends "res://tests/phase_5b_smoke.gd"
func run()->void:
	var state:=preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(50)
	state.cash=10000
	for id in [&"MAIN_GUIDE",&"EAST_REST",&"MAIN_RECEPTION"]:check(MuseumConstructionService.purchase(state,MuseumConstructionService.quote(state,id)),"Public facility bought "+str(id))
	var museum:=Museum.new()
	museum.state=state;museum.config=MuseumConfig.new()
	museum.config.open_duration=25;museum.config.visitor_speed=1000;museum.config.view_duration=.1
	root.add_child(museum);await frames(3)
	check(museum._service_nodes.size()==2,"MAIN loads only two upgraded public fixtures")
	museum.business.start()
	await frames(1300)
	var services:=museum.business.visits.services
	check(services.get("MAIN_GUIDE",0)>0 and services.get("MAIN_RECEPTION",0)>0 and services.get("EAST_REST",0)>0,"Real walkers finish guide reception and rest services")
	check(museum.business.visits.view_count<=museum.business.visitors_today*3,"Public guide cannot exceed three actual views per paid visitor")
	var cash:=state.cash
	var paid:=museum.business.visitors_today
	museum.business._on_paid(0);museum.business._on_service_completed(0,&"MAIN_RECEPTION")
	check(state.cash==cash and museum.business.visitors_today==paid,"Services never sell another ticket")
	museum.switch_hall(&"EAST");await frames(3)
	check(museum._service_nodes.size()==1,"Eastern rest only renders in active hall")
	museum.business.close_now();await frames(200)
	check(state.daily_reports[state.day_number].service_visits.get("MAIN_GUIDE",0)>0,"Actual completed service counts in daily report")
	museum.queue_free();await frames(3)
	print("[11E3] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
