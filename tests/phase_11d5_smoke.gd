extends "res://tests/phase_5b_smoke.gd"
func run()->void:
	var measurements:Array[Dictionary]=[]
	for count in [50,100,500]:
		var state:=MuseumState.new()
		state.museum_level=2
		state.campaign_seed=52
		var ids:Array[StringName]=[]
		for index in range(count):ids.append(state.collection.add(&"republic_silver_coin",1,95,true).instance_id)
		# Isolated full-capacity fixture: wall/platform accept a small coin for stress only.
		# Production layouts/categories and original prototypes are never edited.
		for id in [&"WALL_E1",&"PLATFORM_W1"]:state.display_catalog.units[id].categories.append("COIN")
		var index:=0
		for unit_id in state.display_catalog.unit_ids(2):
			for slot in state.display_catalog.units[unit_id].slots():
				if index>=count:break
				check(state.place(slot.id,ids[index]),"Fixture legal owned unique slot "+str(index))
				index+=1
		check(state.display_assignments.size()==mini(count,81),"Configured81 positions stress with real owned instances")
		var museum:=Museum.new()
		museum.state=state
		museum.config=MuseumConfig.new()
		root.add_child(museum)
		await frames(3)
		var started:=Time.get_ticks_usec()
		museum.office_panel.open()
		for repeat in range(10):museum.office_panel.refresh()
		var open_ms:=(Time.get_ticks_usec()-started)/1000.0/11.0
		check(open_ms<250.0,"Office refresh bounded under250ms with "+str(count)+" owned objects")
		started=Time.get_ticks_usec()
		for repeat in range(10):ExhibitionService.evaluate(state,ExhibitionPlan.new(&"MAIN",&"HAN_WEI"))
		var evaluate_ms:=(Time.get_ticks_usec()-started)/10000.0
		check(evaluate_ms<100,"Topic filtering bounded under100ms")
		check(museum.office_panel.get_child_count()==1 and museum.office_panel.hall_list.item_count==3,"UI has one bounded ledger and three hall rows")
		museum.office_panel.close()
		for hall in [&"EAST",&"WEST",&"MAIN"]:
			museum.switch_hall(hall)
			await frames(3)
			check(museum.cases.size()==state.display_catalog.unit_ids(2,hall).size(),"Only current hall instantiates facilities")
		measurements.append({"owned":count,"displayed":index,"office_ms":open_ms,"evaluate_ms":evaluate_ms})
		museum.queue_free()
		await frames(3)
	var file:=FileAccess.open("res://logs/11d_performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(measurements));file.close()
	# Real game contents: one ancient coin is insufficient; distinct types with a third copy qualify.
	var coins:=MuseumState.new()
	for id in [&"ly_wuzhu",&"gz_kaiyuan",&"ly_wuzhu"]:
		var item:=coins.collection.add(id,1,90,true)
		coins.fill_unit(&"COIN_E1",[item.instance_id])
	check(ExhibitionService.start(coins,&"EAST",&"COINS"),"Actual ancient coin exhibition uses acquired legal small objects")
	check(not ExhibitionService.matches(MuseumState.POOL.find_by_id(&"republic_silver_coin"),ExhibitionService.find(&"COINS")),"Republic coin cannot pretend to be ancient")
	print("[11D5] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
