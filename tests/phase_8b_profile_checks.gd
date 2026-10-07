extends RefCounted
var test: SceneTree


func _init(context: SceneTree) -> void: test = context


static func temporary_path(label: String) -> String:
	return "user://tests/phase_8b/%d_%s.json" % [OS.get_process_id(),label]


func run() -> void:
	var store := MuseumProfileStore.new()
	store.save_path = temporary_path("profile")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(store.save_path))
	var fresh := store.load_profile()
	test.check(fresh.day_number == 1 and fresh.cash == 0 and fresh.museum_level == 0 and fresh.collection.all_items().is_empty(),"Missing profile returns official empty Day1/Level0")
	var state := MuseumState.new()
	state.day_number = 5
	state.cash = 1260
	state.museum_level = 1
	var one := state.collection.add(&"gold_thread_jade",1,100,true)
	var two := state.collection.add(&"gold_thread_jade",2,100,true)
	state.assign(&"CASE_1",one.instance_id)
	state.assign(&"CASE_5",two.instance_id)
	state.phase = MuseumState.Phase.EVENING
	state.last_day_visitors = 40
	state.last_day_ticket_income = 200
	test.check(store.save_profile(state) and FileAccess.file_exists(store.save_path),"Safe museum profile writes real disk JSON")
	test.check(store.save_profile(state),"Atomic replacement supports existing Windows save file")
	var restored := store.load_profile()
	test.check(store.encode(restored) == store.encode(state) and restored.phase == MuseumState.Phase.EVENING,"Disk reload preserves all IDs/day/cash/level/assignments and closed business phase")
	var newer := restored.collection.add(&"republic_silver_coin",5,100,true)
	test.check(newer.instance_id == &"A000003" and newer.instance_id != one.instance_id and newer.instance_id != two.instance_id,"Reload resumes next owned ID without duplicate")
	var data := store.encode(state)
	data.next_antique_id = 1
	test.check(store.decode(data).collection.add(&"han_jade_disc",5,100,true).instance_id == &"A000003","Too-low saved next ID is repaired from existing instances")
	for phase in [MuseumState.Phase.OPEN,MuseumState.Phase.NIGHT]:
		state.phase = phase
		var saves := store.save_count
		test.check(not store.save_profile(state) and store.save_count == saves,"Unsafe phase never writes profile "+str(phase))
	state.phase = MuseumState.Phase.MORNING
	for variant in [null,[],{"version":2}, {"version":1,"day_number":"bad"}]:
		var fallback := store.decode(variant)
		test.check(fallback.cash == 0 and fallback.day_number == 1 and fallback.museum_level == 0 and not store.last_error.is_empty(),"Invalid root/version/field safely falls back")
	for field in ["cash","day_number","museum_level","next_antique_id","collection","display_assignments","phase"]:
		var invalid := store.encode(state)
		invalid[field] = "invalid"
		var fallback := store.decode(invalid)
		test.check(fallback.cash == 0 and fallback.collection.all_items().is_empty(),"Malformed field safely defaults: "+field)
	var cleaned := store.encode(state)
	cleaned.museum_level = 0
	cleaned.collection.append({"instance_id":"A000010","definition_id":"removed_antique","acquired_day":1})
	cleaned.display_assignments = {"CASE_1":str(one.instance_id),"CASE_2":str(one.instance_id),"CASE_3":"A999999","CASE_5":str(two.instance_id)}
	var checked := store.decode(cleaned)
	test.check(checked.collection.all_items().size() == 2 and checked.display_assignments.size() == 1 and checked.display_assignments[&"CASE_1"] == one.instance_id,"Unknown definitions/locked cases/missing IDs/duplicate display ownership safely ignored")
	var file := FileAccess.open(store.save_path,FileAccess.WRITE)
	file.store_string("{ broken json")
	file.close()
	test.check(store.load_profile().collection.all_items().is_empty() and store.last_error.contains("JSON"),"Corrupted disk JSON safely defaults without crash")
	var memory := MuseumProfileStore.in_memory()
	test.check(memory.save_profile(state) and memory.encode(memory.load_profile()) == memory.encode(state),"Injected in-memory profile restores identically without disk")
	var failed := MuseumProfileStore.new()
	failed.save_path = "res://project.godot/profile.json"
	test.check(not failed.save_profile(state) and not failed.last_error.is_empty(),"Unwritable save location reports failure, not success")
