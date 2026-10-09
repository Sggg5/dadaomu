extends "res://tests/phase_11a_smoke.gd"
func run()->void:
	flow=preload("res://scenes/main/game_flow.tscn").instantiate();flow.profile_store=MuseumProfileStore.in_memory()
	root.add_child(flow);await frames(45)
	check(flow.museum!=null and flow.museum_state.phase==MuseumState.Phase.MORNING,"Formal scene starts in safe museum morning")
	check(flow.museum_state.collection.all_items().is_empty() and flow.museum_state.staff.members.is_empty() and flow.museum_state.cash==0,"Formal new game grants no staff funds or artifacts")
	check(flow.museum.office_panel.tabs.get_tab_count()==8,"Office retains seven old pages plus functional personnel page")
	flow.queue_free();flow=null;await frames(3)
	print("[11F startup] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
