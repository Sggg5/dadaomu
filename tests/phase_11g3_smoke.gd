extends "res://tests/phase_5b_smoke.gd"
func run()->void:
	var state:=preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(50);state.cash=5000
	MuseumStaffService.hire(state,&"APPRAISER_SHEN")
	var item:=state.collection.find(state.display_assignments[&"CASE_2"]);MuseumResearchService.register(state,item.instance_id)
	var task:=MuseumStaffTasks.enqueue(state,&"APPRAISER_SHEN",item.instance_id,&"RESEARCH",2)
	check(task!=null and MuseumStaffTasks.enqueue(state,&"APPRAISER_SHEN",item.instance_id,&"RESEARCH",2)==null,"Research uses shared queue with duplicate protection")
	var museum:=Museum.new();museum.state=state;museum.config=MuseumConfig.new();museum.config.open_duration=10;museum.config.staff_task_time_scale=.02
	root.add_child(museum);await frames(3)
	var cash:=state.cash;museum.business.start();await frames(60)
	check(museum.business.workday.prepared.size()==1 and state.collection.archives[item.instance_id].level==1,"OPEN prepares research without early unlock")
	museum.business.close_now();await frames(300)
	check(state.collection.archives[item.instance_id].level==2 and task.status==&"COMPLETED","Actual close commits employee research")
	check(state.daily_reports[1].staff_wages_paid==14 and state.cash==cash-14+museum.business.income_today,"Research consumes one existing daily wage")
	check(not MuseumOperatingFinance.settle(state,museum.business) and state.collection.archives[item.instance_id].events.size()==2,"Research cannot settle twice")
	museum.queue_free();await frames(3)
	print("[11G3] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
