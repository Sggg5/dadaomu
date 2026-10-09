extends "res://tests/phase_5b_smoke.gd"
func run()->void:
	for size in [50,100,500]:
		var state:=preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(size)
		state.cash=10000;MuseumStaffService.hire(state,&"APPRAISER_SHEN");MuseumStaffService.hire(state,&"CONSERVATOR_SU")
		var app_ids:Array[StringName]=[]
		for i in range(4):
			var item:=state.collection.add(&"ly_attendant",1,70,false);app_ids.append(item.instance_id);MuseumStaffTasks.enqueue(state,&"APPRAISER_SHEN",item.instance_id)
		var repair_ids:Array[StringName]=[]
		for i in range(3):
			var item:=state.collection.add(&"gz_floral_mirror",1,60,true);repair_ids.append(item.instance_id);MuseumStaffTasks.enqueue(state,&"CONSERVATOR_SU",item.instance_id)
		var museum:=Museum.new();museum.state=state;museum.config=MuseumConfig.new();museum.config.open_duration=10;museum.config.staff_task_time_scale=.02
		root.add_child(museum);await frames(3)
		var panel:=museum.office_panel.staff_view
		panel.employees.select(panel.ids.find(&"APPRAISER_SHEN"))
		var started:=Time.get_ticks_usec();panel.refresh();var duration:=Time.get_ticks_usec()-started
		print("[PERF] staff panel %d artifacts: %d us"%[size,duration])
		check(duration<500000,"Personnel refresh bounded on isolated size "+str(size))
		check(panel.artifacts.item_count<=20 and panel.queue.item_count<=20,"Bounded personnel panel for %d artifacts"%size)
		panel.search.text="A";panel.search.text_changed.emit("A");check(panel.artifact_ids.size()<=20,"Search remains paginated")
		museum.business.start();await frames(120)
		check(museum.business.workday.prepared_counts.get("APPRAISER_SHEN",0)==2 and museum.business.workday.prepared_counts.get("CONSERVATOR_SU",0)==1,"Daily capacity enforced on real work")
		check(MuseumStaffTasks.enqueue(state,&"APPRAISER_SHEN",app_ids[3])==null and not MuseumProfileStore.in_memory().save_profile(state),"OPEN disallows queue edits and save")
		museum.business.close_now();await frames(500)
		check(state.collection.find(app_ids[0]).identified and not state.collection.find(app_ids[2]).identified,"Only completed daily appraisal capacity applied")
		check(state.collection.find(repair_ids[0]).condition==100 and state.collection.find(repair_ids[1]).condition==60,"Only assigned restoration completed")
		museum.queue_free();await frames(3)
	var poor:=MuseumState.new();poor.cash=1000;MuseumStaffService.hire(poor,&"CONSERVATOR_SU")
	var item:=poor.collection.add(&"gz_floral_mirror",1,0,true)
	var task:=MuseumStaffTasks.enqueue(poor,&"CONSERVATOR_SU",item.instance_id)
	poor.cash=18
	poor.phase=MuseumState.Phase.OPEN
	var day:=MuseumStaffPayroll.begin(poor)
	day.advance_tasks(20,1);day.commit_tasks()
	check(task.status==&"WAITING_FUNDS" and item.condition==0 and task.fee_paid==0 and poor.cash==0,"Funded wage does not allow free restoration")
	var state:=MuseumState.new();state.cash=1000;MuseumStaffService.hire(state,&"APPRAISER_SHEN")
	item=state.collection.add(&"ly_attendant",1,70,false);task=MuseumStaffTasks.enqueue(state,&"APPRAISER_SHEN",item.instance_id)
	state.phase=MuseumState.Phase.OPEN
	day=MuseumStaffPayroll.begin(state);day.advance_tasks(2,1)
	check(task.worked_seconds==0 and not item.identified,"Unclosed work is ephemeral and cannot advance offline")
	day.commit_tasks();check(task.worked_seconds==2 and task.status==&"PENDING" and not item.identified,"Partial real work retained at closure only")
	state.phase=MuseumState.Phase.EVENING
	var missing:=state.collection.add(&"ly_attendant",1,50,true)
	MuseumStaffService.hire(state,&"CONSERVATOR_SU")
	var locked:=MuseumStaffTasks.enqueue(state,&"CONSERVATOR_SU",missing.instance_id)
	state.consign(missing.instance_id,0);MuseumStaffTasks.reconcile(state)
	check(locked.status==&"CANCELLED" and missing.condition==50,"Auction lock safely invalidates queued repair")
	var repair_item:=state.collection.add(&"ly_attendant",1,60,true)
	var manually_repaired:=MuseumStaffTasks.enqueue(state,&"CONSERVATOR_SU",repair_item.instance_id)
	state.repair(repair_item.instance_id);MuseumStaffTasks.reconcile(state)
	check(manually_repaired.status==&"CANCELLED","Manual restoration invalidates queued task without repeated fee")
	var before:=state.collection.all_items().size()
	var payload:=MuseumProfileStore.in_memory().encode(state)
	payload.staff_tasks[0].staff_id="INVALID"
	var codec:=MuseumProfileStore.in_memory();var restored:=codec.decode(payload)
	check(codec.write_blocked and restored.collection.all_items().size()==before,"Invalid staff task protects archive and preserves collection")
	print("[11F5] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
