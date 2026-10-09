extends "res://tests/phase_11a_smoke.gd"
## Disk safeguards on earned progress only, never formal user paths.
func run()->void:
	var path:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--checkpoint="):path=arg.trim_prefix("--checkpoint=")
	check(path.begins_with("res://logs/11i_earned_") and FileAccess.file_exists(path),"Isolated earned checkpoint required")
	if failures>0:quit(1);return
	var source:=MuseumProfileStore.new();source.save_path=path
	var state:=source.load_profile();check(not source.write_blocked,"Earned disk state valid")
	var gross:=0;var expenses:=0
	for report in state.daily_reports.values():gross+=int(report.ticket_income)
	for expense in state.staff.expenses:expenses+=int(expense.amount)
	for expense in state.facilities.expenses:expenses+=int(expense.amount)
	check(state.cash==gross-expenses,"Earned-only ticket / hire / wage / construction journal reconciles")
	var encoded:=source.encode(state)
	var copy:=MuseumProfileStore.new();copy.save_path="res://logs/11i_disk_%d.json"%Time.get_ticks_usec()
	check(copy.save_profile(state),"First safe V10 write")
	for index in range(30):
		var reader:=MuseumProfileStore.new();reader.save_path=copy.save_path
		var restored:=reader.load_profile()
		check(not reader.write_blocked and reader.encode(restored)==encoded,"Thirty restart disk roundtrips preserve complete earned state")
		check(reader.save_profile(restored),"Ground save does not repeat money or achievements")
	flow=preload("res://scenes/main/game_flow.tscn").instantiate();flow.profile_store=MuseumProfileStore.new();flow.profile_store.save_path=copy.save_path
	root.add_child(flow);await frames(5)
	check(flow.museum!=null and flow.profile_store.encode(flow.museum_state)==encoded,"Formal GameFlow restores disk checkpoint exactly")
	flow.queue_free();await frames(4)
	var sha:=FileAccess.get_sha256(copy.save_path)
	state.phase=MuseumState.Phase.OPEN
	check(not copy.save_profile(state) and FileAccess.get_sha256(copy.save_path)==sha,"OPEN refuses write")
	state.phase=MuseumState.Phase.NIGHT
	check(not copy.save_profile(state) and FileAccess.get_sha256(copy.save_path)==sha,"NIGHT refuses write")
	state.phase=MuseumState.Phase.EVENING
	var external:=FileAccess.open(copy.save_path,FileAccess.WRITE);external.store_string("{ broken external document");external.close()
	var bytes:=FileAccess.get_file_as_bytes(copy.save_path)
	check(not copy.save_profile(state) and FileAccess.get_file_as_bytes(copy.save_path)==bytes,"External corrupt edit never overwritten")
	var bad:=MuseumProfileStore.new();bad.save_path=copy.save_path;bad.load_profile()
	check(bad.write_blocked and not bad.save_profile(state) and FileAccess.get_file_as_bytes(copy.save_path)==bytes,"Bad load cannot replace original with empty state")
	print("[11I4] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
