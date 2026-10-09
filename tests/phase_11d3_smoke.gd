extends "res://tests/phase_5b_smoke.gd"
func run()->void:
	var state:=MuseumState.new()
	var slots:=state.display_catalog.units[&"CASE_2"].slots()
	var i:=0
	for id in [&"ly_attendant",&"ly_wuzhu",&"ly_granary"]:
		var item:=state.collection.add(id,1,95,true)
		state.place(slots[i].id,item.instance_id)
		i+=1
	ExhibitionService.start(state,&"MAIN",&"HAN_WEI")
	var result:=VisitorViewResult.snapshot(state,&"CASE_2",{})
	check(result.instance_ids.size()==3 and result.topic_id=="HAN_WEI" and result.feedback.contains("汉魏"),"Feedback derives from actual complete Han display")
	var repeat:=VisitorViewResult.snapshot(state,&"CASE_2",{"COIN":true})
	check(repeat.repeat_category and repeat.feedback.contains("相似"),"Prior observed category explains repetitive feedback")
	var museum:=Museum.new()
	museum.state=state
	museum.config=MuseumConfig.new()
	museum.config.open_duration=15
	museum.config.visitor_speed=800
	museum.config.view_duration=.1
	root.add_child(museum)
	await frames(3)
	check(museum.business.start(),"Actual museum opens")
	await frames(800)
	var stats:=museum.business.visits.snapshot()
	check(stats.view_count>0 and stats.artifact_views>=3 and stats.hall_visits.has("MAIN"),"Real walking visitors finish watching and record hall objects")
	var cash:=state.cash
	var paid:=museum.business.visitors_today
	museum.business._on_paid(0)
	check(state.cash==cash and museum.business.visitors_today==paid,"Repeated ticket signal never pays again")
	var visitor_ids:=museum.business.visits._visitors.keys()
	var index:int=visitor_ids[0]
	var views:int=stats.view_count
	museum.business._on_view_completed(index,result)
	check(museum.business.visits.view_count==views,"Repeated completed view does not double count")
	museum.business.close_now()
	museum.business._on_paid(0)
	museum.business._on_view_completed(0,result)
	check(state.cash==cash and museum.business.visits.view_count==views,"Closing rejects late payment and visit signals")
	await frames(150)
	check(not museum.business.running and state.phase==MuseumState.Phase.EVENING,"Visitors exit and close normally")
	museum.queue_free()
	await frames(3)
	print("[11D3] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)

