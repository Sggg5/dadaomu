extends "res://tests/phase_5b_smoke.gd"
func run()->void:
	var state:=MuseumState.new();state.cash=2000
	check(MuseumStaffService.catalog().size()==6,"Six stable configured employees")
	var spent:=0
	for id in MuseumStaffService.catalog():
		spent+=MuseumStaffService.catalog()[id].hire_cost
		check(MuseumStaffService.hire(state,id),"Hire real roster member "+str(id))
		var cash:=state.cash
		check(not MuseumStaffService.hire(state,id) and cash==state.cash,"Repeated hire cannot pay or duplicate")
	check(state.staff.active_count()==6 and state.cash==2000-spent,"Bounded roster and actual recruitment cash")
	check(not MuseumStaffService.assign_hall(state,&"GUIDE_LIN",&"WEST"),"Locked hall assignment denied")
	check(MuseumStaffService.assign_hall(state,&"GUIDE_LIN",&"EAST"),"Guide assigned to unlocked hall")
	check(not MuseumStaffService.assign_hall(state,&"APPRAISER_SHEN",&"EAST"),"Non-guide cannot be assigned guide hall")
	state.phase=MuseumState.Phase.OPEN
	check(not MuseumStaffService.dismiss(state,&"GUIDE_LIN"),"OPEN employment changes denied")
	state.phase=MuseumState.Phase.EVENING
	check(MuseumStaffService.dismiss(state,&"GUIDE_LIN") and state.staff.members.has(&"GUIDE_LIN"),"Dismissal preserves stable member record")
	check(not MuseumStaffService.dismiss(state,&"GUIDE_LIN"),"Repeated dismissal safe")
	var cash_before:=state.cash
	check(MuseumStaffService.hire(state,&"GUIDE_LIN") and state.staff.active_count()==6 and state.cash==cash_before-90,"Rehire retains stable identity and pays once")
	cash_before=state.cash
	check(MuseumStaffPayroll.begin(state).wages_paid==0 and state.cash==cash_before,"Closed museum cannot deduct payroll or start work")
	var poor:=MuseumState.new()
	check(not MuseumStaffService.hire(poor,&"GUIDE_LIN") and poor.cash==0,"Insufficient hiring money cannot create staff")
	print("[11F1] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
