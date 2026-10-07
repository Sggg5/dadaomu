extends RefCounted
var test: SceneTree


func _init(context: SceneTree) -> void: test = context


func run() -> void:
	var state := MuseumState.new()
	var available := state.collection.add(&"tang_sancai_horse",1,60,true)
	var displayed := state.collection.add(&"han_jade_disc",1,60,true)
	var waiting := state.collection.add(&"blue_white_jar",1,60)
	var locked := state.collection.add(&"gold_thread_jade",1,60,true)
	state.assign(&"CASE_1",displayed.instance_id)
	state.consign(locked.instance_id,2)
	var museum := preload("res://scenes/museum/museum.tscn").instantiate() as Museum
	museum.state = state
	museum.config = MuseumConfig.new()
	test.root.add_child(museum)
	await test.frames(3)
	museum.dealer.interact()
	test.check(museum.dealer_panel.panel.visible and museum.dealer_panel._ids == [available.instance_id] and not museum.dealer_panel._ids.has(waiting.instance_id),"Dealer UI excludes unidentified/displayed/pending instances")
	museum.dealer_panel.close()
	museum.restoration.interact()
	test.check(museum.restoration_panel._ids == [available.instance_id,displayed.instance_id] and not museum.restoration_panel._ids.has(locked.instance_id),"Repair UI excludes pending lot but allows existing damaged displays")
	museum.restoration_panel.close()
	museum.consignment.interact()
	test.check(museum.consignment_panel._ids.is_empty() and museum.consignment_panel.heading.text.contains("已有待拍品") and museum.consignment_panel.heading.text.contains("品相60"),"Second consignment UI presents one locked lot rather than another choice")
	museum.consignment_panel.cancel_button.pressed.emit()
	test.check(state.auction_lot_instance_id == &"" and locked.condition == 60 and state.cash == 0 and not museum.consignment_panel.cancel(),"Actual free cancel button releases lock once without income/condition changes")
	museum.consignment_panel.close()
	museum.business.start()
	var cash := state.cash
	museum.dealer.interact()
	museum.consignment.interact()
	test.check(museum.message.text == "营业中无法处理古董交易" and not museum.dealer_panel.panel.visible and not museum.consignment_panel.panel.visible and state.cash == cash and state.collection.contains(available.instance_id),"Actual OPEN dealer/consignment Interactables reject transaction and display formal prompt")
	museum.queue_free()
	await test.frames(3)
	# Exactly-once与不可信结算边界，不用伪造结果去代替完整竞价流程。
	state = MuseumState.new()
	var item := state.collection.add(&"tang_sancai_horse",1,60,true)
	state.consign(item.instance_id,2)
	state.phase = MuseumState.Phase.NIGHT
	var result := AuctionResult.new()
	result.instance_id = item.instance_id
	result.market_value = 960
	result.reserve_price = 1250
	result.final_bid = 1000
	result.sold = true
	result.net_proceeds = 900
	result.commission = 100
	test.check(not state.settle_auction(result) and state.cash == 0 and state.is_auction_locked(item.instance_id),"Sold-below-reserve payload cannot modify pending lot/cash")
	result.final_bid = 1300
	result.net_proceeds = 1300
	result.commission = 0
	test.check(not state.settle_auction(result) and state.cash == 0,"Incorrect commission/net payload rejected")
	result.sold = false
	result.final_bid = 1000
	result.net_proceeds = 0
	test.check(state.settle_auction(result) and state.collection.contains(item.instance_id) and not state.is_auction_locked(item.instance_id) and item.condition == 60 and state.cash == 0,"Valid unsold unit result unlocks original item unchanged")
	test.check(not state.settle_auction(result),"Duplicate unsold unit settlement rejected too")
	# State变化仅一次保存，重复交易不能新增持久化操作。
	state.phase = MuseumState.Phase.MORNING
	var store := MuseumProfileStore.in_memory()
	var save_callback := func() -> void: store.save_profile(state)
	state.changed.connect(save_callback)
	test.check(state.sell_to_dealer(item.instance_id) and store.save_count == 1 and not store.load_profile().collection.contains(item.instance_id),"Successful dealer State transaction triggers one complete persistence update")
	test.check(not state.sell_to_dealer(item.instance_id) and store.save_count == 1,"Repeated dealer action cannot save another payout")
	state.changed.disconnect(save_callback)
