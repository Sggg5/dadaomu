extends "res://tests/phase_8b_progression_checks.gd"
## 三件主流程藏品均来自真实Door/武器/E/F Run，经济现金不注入。
var auction_seed_value: int = 192034


func create_flow() -> void:
	flow = preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
	flow.profile_store = MuseumProfileStore.new()
	flow.profile_store.save_path = path
	flow.museum_config = config
	flow.auction_seed = auction_seed_value
	test.root.add_child(flow)
	test.current_scene = flow
	await test.frames(3)
	daytime = preload("res://tests/phase_8a_flow_checks.gd").new(test,flow)


func market_at(point: MuseumInteractable) -> void:
	await daytime.walk_to(Vector2(point.position.x,470))
	await daytime.walk_to(point.position+Vector2(0,-40))
	test.key(KEY_E)
	await test.frames(2)


func consign_real(id: StringName, mode: int) -> void:
	await market_at(flow.museum.consignment)
	var panel := flow.museum.consignment_panel
	test.check(panel.panel.visible and panel._ids.has(id),"Actual commission station E lists available real owned antique")
	panel.reserve.select(mode)
	panel.reserve.item_selected.emit(mode)
	panel.list.select(panel._ids.find(id))
	await test.frames(2)
	var item := flow.museum_state.collection.find(id)
	var value := AntiqueMarketService.market_value(item,MuseumState.POOL.find_by_id(item.definition_id))
	test.check(panel.reserve.selected == mode and panel.list.get_item_text(panel._ids.find(id)).contains(AntiqueDefinition.money(AntiqueMarketService.reserve_price(value,mode))),"Selected reserve mode immediately updates formal UI quote")
	test.capture("consignment_choice_%d" % mode)
	test.key(KEY_E)
	test.key(KEY_E)
	await test.frames(2)
	test.check(flow.museum_state.auction_lot_instance_id == id and flow.museum_state.auction_reserve_mode == mode and panel.heading.text.contains("委托已保存"),"Actual selected reserve/E consignment creates one locked pending item")
	test.key(KEY_TAB)
	await test.frames(2)


func choose_night(auction: bool) -> void:
	await daytime.walk_to(Vector2(940,450))
	await daytime.walk_to(Vector2(940,210))
	await daytime.walk_to(flow.museum.board.position+Vector2(-40,20))
	test.key(KEY_E)
	await test.frames(2)
	var panel := flow.museum.night_panel
	test.check(panel.panel.visible and flow.current_phase != MuseumState.Phase.NIGHT,"Pending lot turns actual board E into night choice, not automatic activity")
	test.capture("night_choice")
	if auction: panel.auction_button.pressed.emit()
	else: panel.dungeon_button.pressed.emit()
	test.check(not panel.choose(not auction),"Rapid alternate action cannot select both activities")
	await test.frames(5)
	test.check(flow.current_phase == MuseumState.Phase.NIGHT and flow.museum == null and ((flow.auction != null and flow.dungeon == null) if auction else (flow.dungeon != null and flow.auction == null)),"Actual choice creates exclusively Auction or Dungeon")
	if not auction: test.session = flow.dungeon


func bid_and_return(expect_sold: bool) -> AuctionResult:
	var session := flow.auction
	var day_before := flow.current_day
	var cash_before := flow.museum_state.cash
	var id := flow.museum_state.auction_lot_instance_id
	var item := flow.museum_state.collection.find(id)
	var condition := item.condition
	test.check(not flow.return_from_auction(AuctionResult.new()) and not session.request_return(),"Foreign and unfinished results cannot advance day or pay cash")
	var rounds: int = 0
	while not session.bidding.finished and rounds < 100:
		var previous := session.bidding.current_bid
		test.key(KEY_E)
		await test.frames(1)
		test.check(session.bidding.current_bid == previous or session.bidding.current_bid == (session.bidding.starting_bid if previous == 0 else previous+session.bidding.bid_step),"Actual E produces at most one bid or closes auction")
		if rounds == 4: test.capture("bidding")
		rounds += 1
	var result := session.bidding.result
	test.check(result != null and result.sold == expect_sold and not result.bid_history.is_empty() and flow.current_day == day_before and flow.museum_state.cash == cash_before,"Real per-round bidding ends expected outcome without premature settlement")
	test.capture("auction_sold" if expect_sold else "auction_unsold")
	test.key(KEY_E)
	test.key(KEY_E)
	await test.frames(5)
	var state := flow.museum_state
	test.check(state.day_number == day_before+1 and flow.current_phase == MuseumState.Phase.MORNING and state.auction_lot_instance_id == &"" and flow.auction == null and flow.dungeon == null,"Auction return clears pending once and advances exactly one night")
	test.check(not flow.return_from_auction(result) and not flow.start_auction(),"Old result/repeated return cannot credit again or launch without lot")
	if expect_sold:
		test.check(state.cash == cash_before+result.net_proceeds and result.net_proceeds == AntiqueMarketService.net_proceeds(result.final_bid) and result.commission == result.final_bid-result.net_proceeds and not state.collection.contains(id),"Sold real auction credits exact net after10% and permanently removes unique lot")
	else:
		test.check(state.cash == cash_before and state.collection.contains(id) and state.collection.find(id).condition == condition and state.collection.find(id).identified and state.can_assign(id) and state.can_sell(id) and state.can_consign(id),"Real unsold lot returns unchanged and unlocked with no cash income")
	var saved := flow.profile_store.load_profile()
	test.check(flow.profile_store.encode(saved) == flow.profile_store.encode(state),"Auction sold/unsold return immediately persists entire safe ground transaction")
	print("[8D auction] day%d seed%d sold=%s market=%d reserve=%d final=%d commission=%d net=%d rounds=%d" % [day_before,flow.auction_seed,result.sold,result.market_value,result.reserve_price,result.final_bid,result.commission,result.net_proceeds,rounds])
	daytime = preload("res://tests/phase_8a_flow_checks.gd").new(test,flow)
	return result


func run() -> void:
	path = "user://tests/phase_8d/%d_flow.json" % OS.get_process_id()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	config = MuseumConfig.new()
	await create_flow()
	test.check(flow.current_day == 1 and flow.museum_state.collection.all_items().is_empty() and flow.museum_state.cash == 0,"Formal8D starts empty without seeded test loot/cash")
	await night() # 无待拍时沿用直接情报板E下墓。
	var driver = preload("res://tests/phase_7b_run_driver.gd").new(test)
	await driver.collect_floor()
	await driver.defeat_warlord()
	var exit := test.session.world.current_room.get_node("ExpeditionExit") as ExpeditionExit
	test.session.world.player.position = exit.position+Vector2(24,0)
	test.key(KEY_F)
	await test.frames(3)
	test.key(KEY_E)
	await test.frames(5)
	var state := flow.museum_state
	test.check(state.collection.all_items().size() == 4 and state.day_number == 2 and state.cash == 0,"Real first-floor Door/weapon/loot/Boss/F import four antiques but no ticket/market cash")
	var horse_id: StringName
	var jades: Array[StringName] = []
	for item in state.collection.all_items():
		if item.definition_id == &"tang_sancai_horse": horse_id = item.instance_id
		if item.definition_id == &"gold_thread_jade": jades.append(item.instance_id)
	await daytime.appraise(horse_id)
	var horse := state.collection.find(horse_id)
	var market := AntiqueMarketService.market_value(horse,MuseumState.POOL.find_by_id(horse.definition_id))
	var offer := AntiqueMarketService.dealer_offer(market)
	await market_at(flow.museum.dealer)
	var dealer_panel := flow.museum.dealer_panel
	test.check(dealer_panel.panel.visible and dealer_panel._ids == [horse_id] and dealer_panel.list.get_item_text(0).contains(AntiqueDefinition.money(offer)),"Actual dealer E lists only appraised storage horse with centralized offer")
	test.capture("dealer_offer")
	test.key(KEY_E)
	test.key(KEY_E)
	await test.frames(2)
	test.check(state.cash == offer and not state.collection.contains(horse_id) and dealer_panel.heading.text.contains("出售完成"),"Real dealer E exact once cash/identity transaction")
	test.capture("dealer_sold")
	test.key(KEY_TAB)
	var expected := flow.profile_store.encode(state)
	flow.queue_free()
	await test.frames(4)
	await create_flow()
	state = flow.museum_state
	test.check(flow.profile_store.encode(state) == expected and not state.collection.contains(horse_id),"Actual restart retains dealer cash, sold horse never resurrects")
	await daytime.appraise(jades[0])
	await consign_real(jades[0],AntiqueMarketService.Reserve.NORMAL)
	var pending_snapshot := flow.profile_store.encode(state)
	await choose_night(false)
	test.check(state.is_auction_locked(jades[0]) and flow.auction == null and test.session.world.layout != null,"Dungeon choice preserves pending lock and runs ordinary Dungeon only")
	driver = preload("res://tests/phase_7b_run_driver.gd").new(test)
	await driver.die_to_enemy()
	test.key(KEY_E)
	await test.frames(5)
	daytime = preload("res://tests/phase_8a_flow_checks.gd").new(test,flow)
	test.check(state.day_number == 3 and state.auction_lot_instance_id == jades[0] and state.cash == pending_snapshot.cash,"Real enemy death consumes one Dungeon night and pending consignment survives")
	await choose_night(true)
	var sold := await bid_and_return(true)
	expected = flow.profile_store.encode(state)
	flow.queue_free()
	await test.frames(4)
	await create_flow()
	state = flow.museum_state
	test.check(flow.profile_store.encode(state) == expected and not state.collection.contains(jades[0]) and state.cash == offer+sold.net_proceeds,"Restart after actual standard auction preserves net cash and sold identity deletion")
	await daytime.appraise(jades[1])
	var remaining := state.collection.find(jades[1])
	var found: bool = false
	for seed in range(128):
		var bidding := AuctionBidding.new()
		bidding.configure(remaining,MuseumState.POOL.find_by_id(remaining.definition_id),state.day_number,seed,AntiqueMarketService.Reserve.HIGH)
		for rounds in range(100):
			if bidding.finished: break
			bidding.next_round()
		if not bidding.result.sold:
			auction_seed_value = seed
			found = true
			break
	test.check(found,"Finite search identifies deterministic high-reserve unsold fixture, not altered NPC budgets")
	flow.auction_seed = auction_seed_value
	await consign_real(jades[1],AntiqueMarketService.Reserve.HIGH)
	var before_auction := flow.profile_store.encode(state)
	await choose_night(true)
	for round_index in range(3): test.key(KEY_E); await test.frames(1)
	flow.queue_free() # 中途退出：未结算，不保存AuctionSession。
	await test.frames(4)
	await create_flow()
	state = flow.museum_state
	test.check(flow.auction == null and flow.dungeon == null and flow.profile_store.encode(state) == before_auction and state.is_auction_locked(jades[1]),"Mid-auction restart restores same safe day/cash/pendingHIGH, no session continuation")
	await choose_night(true)
	await bid_and_return(false)
	expected = flow.profile_store.encode(state)
	flow.queue_free()
	await test.frames(4)
	await create_flow()
	state = flow.museum_state
	test.check(flow.profile_store.encode(state) == expected and state.collection.contains(jades[1]) and state.auction_lot_instance_id == &"","Restart after real unsold auction preserves unlocked item/cash/next morning")
	await daytime.place(1,jades[1])
	test.check(state.case_for(jades[1]) == &"CASE_2","Real returned unsold antique can be personally displayed again")
	test.capture("unsold_return_exhibit")
	flow.queue_free()
	await test.frames(3)
