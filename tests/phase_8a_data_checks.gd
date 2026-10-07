extends RefCounted
var test: SceneTree


func _init(context: SceneTree) -> void: test = context


func run() -> void:
	var pool := MuseumState.POOL
	var appeal_values := {&"republic_silver_coin":3,&"blue_white_jar":12,&"gilt_buddha":22,&"han_jade_disc":25,&"inlaid_bronze_mirror":35,&"tang_sancai_horse":50,&"gold_thread_jade":32,&"guardian_fragment":60}
	for id in appeal_values:
		test.check(pool.find_by_id(id).exhibit_appeal == appeal_values[id],"Explicit appeal correct: "+str(id))
	test.check(pool.find_by_id(&"unknown") == null and pool.find_by_id(&"tang_sancai_horse").exhibit_appeal > pool.find_by_id(&"gold_thread_jade").exhibit_appeal,"ID lookup and appeal independent of market price")
	var state := MuseumState.new()
	var first := state.collection.add(&"gold_thread_jade",1,100,true)
	var second := state.collection.add(&"gold_thread_jade",1,100,true)
	test.check(first.instance_id != second.instance_id and first.acquired_day == 1 and state.collection.contains(first.instance_id),"Duplicate definitions have different owned IDs/acquired day")
	var copied := state.collection.all_items()
	copied.clear()
	test.check(state.collection.all_items().size() == 2 and state.collection.find(second.instance_id) == second,"Collection returns independent array and finds specific instance")
	test.check(state.assign(&"CASE_1",first.instance_id) and not state.assign(&"CASE_2",first.instance_id),"Same instance cannot occupy two display cases")
	test.check(state.assign(&"CASE_2",second.instance_id) and state.total_appeal() == 64,"Separate duplicates exhibit simultaneously and sum exact appeal")
	state.phase = MuseumState.Phase.OPEN
	test.check(not state.unassign(&"CASE_1") and not state.assign(&"CASE_3",second.instance_id),"Data boundary refuses all exhibit changes while open")
	state.phase = MuseumState.Phase.EVENING
	test.check(state.unassign(&"CASE_1") and state.case_for(first.instance_id) == &"" and state.collection.contains(first.instance_id),"After closing withdrawal returns owned antique to storage")
	test.check(state.collection.remove(first.instance_id) and not state.collection.contains(first.instance_id) and not state.collection.remove(first.instance_id),"Collection remove targets owned ID once (no daytime delete UI)")
	var config := MuseumConfig.new()
	var business := MuseumBusiness.new()
	business.config = config
	test.check(config.open_duration == 60 and config.ticket_price == 5 and config.max_active_visitors == 8,"Default business duration/price/active limit")
	test.check(business.visitor_target(0,0) == 0 and business.visitor_target(50,0) == 0,"Empty exhibit count means zero target regardless of appeal")
	test.check(business.visitor_target(3,1) == 6 and business.visitor_target(50,1) == 30 and business.visitor_target(75,2) == 30 and business.visitor_target(117,3) == 30,"Displayed exhibits use5+floor(appeal*.5), Level0 capacity30")
	test.check(business.visitor_target(0,1) == 5,"Opening does not require a minimum appeal")
	var single_state := MuseumState.new()
	var only_coin := single_state.collection.add(&"republic_silver_coin",1,100,true)
	test.check(single_state.assign(&"CASE_3",only_coin.instance_id),"One legitimate antique can occupy any one of three cases")
	business.state = single_state
	test.check(business.can_open() and business.start() and single_state.phase == MuseumState.Phase.OPEN and business.target == 6,"One silver coin alone qualifies; no value/rarity/diversity gate")
	business.free()
	var cases: Array[DisplayCase] = []
	for index in range(2):
		var exhibit := DisplayCase.new()
		exhibit.case_id = state.case_ids()[index]
		exhibit.state = state
		cases.append(exhibit)
	var silver := state.collection.add(&"republic_silver_coin",1,100,true)
	var horse := state.collection.add(&"tang_sancai_horse",1,100,true)
	state.assign(&"CASE_1",silver.instance_id)
	state.assign(&"CASE_2",horse.instance_id)
	var horse_count: int = 0
	var silver_count: int = 0
	for index in range(200):
		var visitor := MuseumVisitor.new()
		visitor.cases = cases
		visitor.configure(192034,1,index)
		var chosen := visitor.choose_exhibit()
		var repeated := MuseumVisitor.new()
		repeated.cases = cases
		repeated.configure(192034,1,index)
		test.check(chosen == repeated.choose_exhibit(),"Deterministic visitor selection "+str(index))
		if chosen.case_id == &"CASE_2": horse_count += 1
		else: silver_count += 1
		visitor.free()
		repeated.free()
	test.check(horse_count > silver_count and silver_count > 0,"Appeal-weighted visits favor horse without starving silver coin")
	var empty := MuseumVisitor.new()
	test.check(empty.choose_exhibit() == null,"No exhibits yields safe EXIT decision")
	empty.free()
	for exhibit in cases: exhibit.free()
