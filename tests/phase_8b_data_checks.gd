extends RefCounted
var test: SceneTree


func _init(context: SceneTree) -> void: test = context


func run() -> void:
	var state := MuseumState.new()
	var config := MuseumConfig.new()
	var business := MuseumBusiness.new()
	business.config = config
	business.state = state
	var cases_expected := [3,5,8]
	var capacities := [30,45,60]
	var prices := [1000,3000,0]
	var names := ["私人古物陈列室","古物陈列馆","地方古物馆"]
	for level in range(3):
		state.museum_level = level
		var definition := state.level_definition()
		test.check(definition.case_count == cases_expected[level] and definition.visitor_capacity == capacities[level] and definition.upgrade_cost == prices[level] and definition.display_name == names[level],"Configured museum level "+str(level))
		test.check(state.case_ids().size() == cases_expected[level] and state.case_ids()[0] == &"CASE_1" and state.case_ids().back() == StringName("CASE_%d" % cases_expected[level]),"Stable case IDs grow with level "+str(level))
		test.check(business.visitor_target(200,3) == capacities[level] and business.visitor_target(200,0) == 0,"Capacity clamps same appeal and empty exhibit still means0 at level "+str(level))
	state.museum_level = 0
	var owned := state.collection.add(&"tang_sancai_horse",1,100,true)
	test.check(state.assign(&"CASE_1",owned.instance_id) and not state.assign(&"CASE_4",owned.instance_id),"Level0 rejects locked case")
	state.cash = 999
	test.check(not state.upgrade(0) and state.cash == 999 and state.museum_level == 0,"Insufficient upgrade is atomic")
	state.cash = 5000
	var collection := state.collection
	test.check(state.upgrade(0) and state.cash == 4000 and state.museum_level == 1 and state.collection == collection and state.display_assignments[&"CASE_1"] == owned.instance_id,"First upgrade deducts exactly1000, preserves collection and original assignment")
	test.check(not state.upgrade(0) and state.cash == 4000 and state.museum_level == 1,"Duplicate old upgrade request cannot charge or skip another level")
	var duplicate := state.collection.add(&"tang_sancai_horse",1,100,true)
	test.check(state.assign(&"CASE_4",duplicate.instance_id),"Newly unlocked case accepts independent duplicate")
	state.phase = MuseumState.Phase.OPEN
	test.check(not state.upgrade(1) and not state.unassign(&"CASE_4") and state.cash == 4000,"Open-stage upgrade and changing exhibits rejected")
	state.phase = MuseumState.Phase.EVENING
	test.check(state.upgrade(1) and state.cash == 1000 and state.museum_level == 2 and state.case_ids().size() == 8,"Second upgrade deducts exactly3000 and opens8 cases")
	test.check(not state.upgrade(2) and state.cash == 1000 and state.museum_level == 2,"Highest level rejects all further payment")
	var museum := preload("res://scenes/museum/museum.tscn").instantiate() as Museum
	museum.state = state
	museum.config = config
	test.root.add_child(museum)
	await test.frames(3)
	test.check(museum.cases.size() == 8 and museum.cases[3].case_id == &"CASE_4" and museum.cases[7].case_id == &"CASE_8","Level2 actually instantiates8 stable display nodes")
	test.capture("level2_layout")
	museum.construction_panel.open()
	test.check(museum.construction_panel.label.text.contains("最高馆舍等级") and not museum.construction_panel.confirm() and state.cash == 1000,"Max-level construction UI refuses spending")
	museum.queue_free()
	business.free()
	await test.frames(3)
