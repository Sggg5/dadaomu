extends RefCounted
## Optional extension of the same clean-new-game run, only actual UI/input.
var test:SceneTree
var flow:GameFlow
var day:RefCounted
var tours:Array=[]
func _init(context:SceneTree)->void:
	test=context;flow=test.flow;day=preload("res://tests/phase_8a_flow_checks.gd").new(test,flow)
func row(list:ItemList,index:int)->void:
	list.ensure_current_is_visible()
	await test.click(list.get_global_rect().position+list.get_item_rect(index).get_center())
func organize()->void:
	var state:=flow.museum_state
	for item in state.collection.all_items():
		if item.identified:continue
		await day.walk_to(Vector2(920,450));await day.walk_to(Vector2(920,230));await day.walk_to(Vector2(540,230))
		test.key(KEY_E);await test.frames(3)
		var panel:=flow.museum.appraisal_panel
		var index:=panel._ids.find(item.instance_id)
		if index>=0:await row(panel.list,index);await test.click(panel.confirm_button.get_global_rect().get_center())
		test.check(item.identified,"Actual appraisal of earned artifact "+str(item.definition_id))
		test.key(KEY_TAB);await test.frames(3)
		await day.walk_to(Vector2(920,230));await day.walk_to(Vector2(920,380))
	for display in flow.museum.cases:
		await day.walk_to(Vector2(display.position.x,380));await day.walk_to(display.position+Vector2(0,48))
		test.key(KEY_E);await test.frames(3)
		var panel:=flow.museum.collection_panel
		for button in panel.panel.find_children("*","Button",true,false):
			if button.text=="按筛选自动填空位":await test.click(button.get_global_rect().get_center());break
		test.key(KEY_TAB);await test.frames(3)
func open_day()->void:
	if flow.museum_state.phase!=MuseumState.Phase.MORNING:return
	await day.walk_to(Vector2(1080,450));await day.walk_to(Vector2(1080,540));test.key(KEY_E);await test.frames(3)
	for frame in range(6000):
		await test.frames(1)
		if flow.museum_state.phase==MuseumState.Phase.EVENING:break
	test.check(flow.museum_state.phase==MuseumState.Phase.EVENING,"Real formal duration business closes")
func tour(region:StringName)->bool:
	await day.walk_to(Vector2(940,450));await day.walk_to(Vector2(940,210));await day.walk_to(Vector2(1020,190))
	test.key(KEY_E);await test.frames(3);await test.choose_region(region);await test.choose_row(0)
	await test.click(flow.museum.expedition_map.confirm_button.get_global_rect().get_center());await test.frames(6)
	test.session=flow.dungeon
	var session:=flow.dungeon
	if session==null:return false
	var driver=preload("res://tests/integration_input_driver.gd").new(test,session.world);driver.collect_rewards=true
	var alive:bool=await driver.visit(session.world.layout.antique_id)
	if alive:
		var pickup:=session.world.current_room.get_node_or_null("AntiquePedestal") as AntiquePedestal
		if pickup!=null and session.world.player.antiques.can_add(pickup.definition):
			await driver.walk(pickup.position+Vector2(24,0));test.key(KEY_E);await test.frames(3)
		alive=await driver.visit(session.world.layout.boss_id)
	if alive:
		var exit:=session.world.current_room.get_node_or_null("ExpeditionExit")
		if exit==null:alive=false
		else:
			await driver.walk(exit.position+Vector2(24,0));test.key(KEY_F);await test.frames(5)
	var record:={"region":str(region),"seed":session.run_seed,"alive":alive,"hp":session.world.player.health.current_hp,"bag":session.world.player.antiques.items().map(func(d:AntiqueDefinition)->String:return str(d.id))}
	driver.release()
	if not alive and not session.world.player.health.is_dead:
		test.check(false,"Input driver unable to finish living run; do not fake result");return false
	test.key(KEY_E);await test.frames(10)
	test.check(flow.museum!=null,"Normal result E returns museum after extraction or death")
	tours.append(record);print("[Progression tour] ",record)
	return flow.museum!=null
func run()->void:
	var long_run:bool="--long-run" in OS.get_cmdline_user_args()
	for index in range(40 if long_run else 24):
		if not await tour([&"LUOYANG",&"GUANZHONG",&"JINBEI"][index%3]):break
		await organize();await manage();await open_day()
		var rating:=MuseumReputationService.evaluate(flow.museum_state)
		print("[Progression] day=",flow.current_day," cash=",flow.museum_state.cash," rating=",rating.rank," metrics=",rating.metrics)
		if rating.rank>=1 and flow.museum_state.museum_level>=(2 if long_run else 1) and rating.metrics.topics>=1 and rating.metrics.researched>=1 and (not long_run or flow.current_day>=31):break
	var rating:=MuseumReputationService.evaluate(flow.museum_state)
	test.check(rating.rank>=1,"Earned actual collection reaches second operating title")
	test.check(tours.any(func(t:Dictionary)->bool:return t.region=="LUOYANG" and t.alive) and tours.any(func(t:Dictionary)->bool:return t.region=="GUANZHONG" and t.alive),"Actual input-only successful trips to both other regions")
	test.check(flow.museum_state.museum_level>=1 and rating.metrics.topics>=1 and rating.metrics.researched>=1,"Earned income funds real expansion, staff research and topic")
	if long_run:test.check(flow.current_day>=31 and flow.museum_state.museum_level==2,"Actual GameFlow thirty business days reaches maximum legal construction")
	var store:=MuseumProfileStore.new();store.save_path="res://logs/11i_earned_midgame_%d.json"%Time.get_ticks_usec()
	test.check(store.save_profile(flow.museum_state),"Legally earned midgame save")
	print("[Midgame checkpoint] ",store.save_path)
	var file:=FileAccess.open("res://logs/11i_progression.json",FileAccess.WRITE);file.store_string(JSON.stringify({"tours":tours,"day":flow.current_day,"cash":flow.museum_state.cash,"rating":rating.rank,"metrics":rating.metrics},"  "));file.close()
func office()->void:
	await day.walk_to(Vector2(230,450));await day.walk_to(Vector2(230,230));test.key(KEY_E);await test.frames(3)
func tab(index:int)->void:
	var tabs:=flow.museum.office_panel.tabs
	await test.click(tabs.get_tab_bar().global_position+tabs.get_tab_bar().get_tab_rect(index).get_center());await test.frames(3)
func manage()->void:
	var state:=flow.museum_state
	if not state.staff.members.has(&"APPRAISER_SHEN") and state.cash>=134:
		await office();await tab(7)
		var staff:=flow.museum.office_panel.staff_view
		await row(staff.employees,staff.ids.find(&"APPRAISER_SHEN"));await test.click(staff.hire.get_global_rect().get_center())
		test.check(state.staff.members.has(&"APPRAISER_SHEN"),"Mouse hires employee using earned income")
		test.key(KEY_TAB);await test.frames(3)
	if state.staff.members.has(&"APPRAISER_SHEN"):
		await day.walk_to(Vector2(940,450));await day.walk_to(Vector2(940,230));await day.walk_to(Vector2(900,230));test.key(KEY_E);await test.frames(3)
		var codex:=flow.museum.codex_panel
		for item in state.collection.all_items():
			var record:CollectionResearchRecord=state.collection.archives[item.instance_id]
			if record.level>=2:continue
			var index:=codex.visible_ids.find(str(item.instance_id))
			if index<0:continue
			await row(codex.list,index)
			if not codex.register_button.disabled:await test.click(codex.register_button.get_global_rect().get_center())
			if not codex.research_button.disabled:await test.click(codex.research_button.get_global_rect().get_center())
			break
		test.key(KEY_TAB);await test.frames(3);await day.walk_to(Vector2(940,230));await day.walk_to(Vector2(940,450))
	await office();await tab(5)
	var panel:=flow.museum.office_panel
	if not panel.topic_start.disabled:await test.click(panel.topic_start.get_global_rect().get_center())
	test.key(KEY_TAB);await test.frames(3)
	if state.museum_level<2 and state.cash>=state.level_definition().upgrade_cost:
		var previous:=state.museum_level
		await day.walk_to(Vector2(400,230));test.key(KEY_E);await test.frames(3);test.key(KEY_E);await test.frames(3)
		test.check(state.museum_level==previous+1,"Actual construction E expands from earned funds")
		test.key(KEY_TAB);await test.frames(3)
