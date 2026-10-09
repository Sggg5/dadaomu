extends "res://tests/phase_5b_smoke.gd"
func run()->void:
	var state:=MuseumState.new()
	check(not ExhibitionService.start(state,&"MAIN",&"HAN_WEI"),"Empty hall cannot start exhibition")
	var ids:Array[StringName]=[]
	for id in [&"ly_attendant",&"ly_wuzhu",&"ly_granary"]:
		var item:=state.collection.add(id,1,90,true)
		ids.append(item.instance_id)
	var slots:=state.display_catalog.units[&"CASE_2"].slots()
	check(state.place(slots[0].id,ids[0]),"First owned Han item legal")
	check(not ExhibitionService.start(state,&"MAIN",&"HAN_WEI"),"One artifact not full exhibition")
	check(not state.place(&"COIN_E1",ids[0]),"Same instance cannot display in another hall")
	for i in [1,2]:check(state.place(slots[i].id,ids[i]),"Matching legal display")
	var plan:=ExhibitionPlan.new(&"MAIN",&"HAN_WEI")
	var result:=ExhibitionService.evaluate(state,plan)
	check(result.qualified and result.matched_ids.size()==3 and result.category_count>=2,"Three real Han definitions qualify")
	check(ExhibitionService.start(state,&"MAIN",&"HAN_WEI"),"Start actual hall exhibition")
	check(not ExhibitionService.start(state,&"EAST",&"HAN_WEI"),"Other hall does not borrow displayed instances")
	var score:=result.score
	state.unassign(slots[2].id)
	check(not ExhibitionService.active(state,&"MAIN").qualified and ExhibitionService.bonus_appeal(state)==0,"Removing display immediately disables effective theme")
	state.place(slots[2].id,ids[2])
	state.phase=MuseumState.Phase.OPEN
	check(not ExhibitionService.stop(state,&"MAIN") and not state.unassign(slots[0].id),"OPEN forbids exhibition and display edits")
	state.phase=MuseumState.Phase.MORNING
	for i in range(4):
		var item:=state.collection.add(&"ly_attendant",1,90,true)
		state.place(slots[3+i].id,item.instance_id)
	result=ExhibitionService.evaluate(state,plan)
	check(result.score>score and result.score<score+40,"Duplicate definitions have diminishing score")
	check(result.heat<=0.20 and ExhibitionService.bonus_appeal(state)<=floori(state.total_appeal()*0.20),"Finite theme boost caps prevent additive runaway")
	check(not ExhibitionService.evaluate(state,ExhibitionPlan.new(&"WEST",&"HAN_WEI")).qualified,"Locked hall rejected")
	var coverage:=0
	var pool:AntiquePool=load("res://data/antiques/playtest_catalog_50.tres")
	for definition in pool.antiques:
		if definition.loot_group==&"LEGACY":continue
		for topic in ExhibitionService.definitions():
			if ExhibitionService.matches(definition,topic):coverage+=1;break
	check(coverage==42,"New regional objects participate through explicit prototype metadata")
	check(not ExhibitionService.matches(pool.find_by_id(&"gz_sancai_camel"),ExhibitionService.find(&"HAN_WEI")),"Tang artifact cannot join Han theme")
	print("[11D2] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)

