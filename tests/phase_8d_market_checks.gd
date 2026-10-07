extends RefCounted
var test: SceneTree


func _init(context: SceneTree) -> void: test = context


func run() -> void:
	var state := MuseumState.new()
	var item := state.collection.add(&"tang_sancai_horse",1,76)
	var definition := MuseumState.POOL.find_by_id(item.definition_id)
	test.check(not state.can_sell(item.instance_id) and not state.sell_to_dealer(item.instance_id) and not state.consign(item.instance_id,1),"Unidentified instance cannot sell/consign")
	state.identify(item.instance_id)
	var value := AntiqueMarketService.market_value(item,definition)
	test.check(value == 1216 and AntiqueMarketService.dealer_offer(value) == 910,"Horse76 market1216 and dealer nearest10 quote910")
	test.check(AntiqueMarketService.starting_bid(value) == 730 and AntiqueMarketService.bid_step(value) == 120,"Market-derived starting730/step120")
	test.check(AntiqueMarketService.reserve_price(value,0) == 970 and AntiqueMarketService.reserve_price(value,1) == 1220 and AntiqueMarketService.reserve_price(value,2) == 1580,"LOW/NORMAL/HIGH reserve nearest10 matches80/100/130 percent")
	test.check(AntiqueMarketService.dealer_offer(0) == 10 and AntiqueMarketService.starting_bid(0) == 10 and AntiqueMarketService.bid_step(0) == 10,"Minimum10 price/step guards")
	test.check(AntiqueMarketService.net_proceeds(2200) == 1980 and AntiqueMarketService.commission(2200) == 220,"Commission10% and floor90% net centralized")
	state.assign(&"CASE_1",item.instance_id)
	test.check(not state.can_sell(item.instance_id) and not state.sell_to_dealer(item.instance_id) and not state.consign(item.instance_id,1),"Displayed instance must be withdrawn before market operation")
	state.unassign(&"CASE_1")
	var other := state.collection.add(&"han_jade_disc",1,70,true)
	test.check(state.consign(item.instance_id,1) and state.collection.contains(item.instance_id) and state.is_auction_locked(item.instance_id),"Consignment locks ownership without removing collection item")
	test.check(not state.can_assign(item.instance_id) and not state.assign(&"CASE_1",item.instance_id) and not state.can_repair(item.instance_id) and not state.repair(item.instance_id) and not state.sell_to_dealer(item.instance_id),"Pending instance refuses assign/repair/dealer at data layer")
	test.check(not state.consign(item.instance_id,1) and not state.consign(other.instance_id,1),"One pending lot only, duplicate or second instance refused")
	state.phase = MuseumState.Phase.OPEN
	test.check(not state.cancel_consignment() and not state.sell_to_dealer(other.instance_id) and not state.consign(other.instance_id,1),"OPEN rejects all market operations")
	state.phase = MuseumState.Phase.EVENING
	test.check(state.cancel_consignment() and item.condition == 76 and state.cash == 0 and state.can_assign(item.instance_id),"Evening cancellation free, condition/ownership preserved and unlocks exhibit")
	test.check(not state.cancel_consignment() and not state.consign(item.instance_id,3),"Duplicate cancel and arbitrary reserve mode refused")
	state.cash = 240
	test.check(state.repair(item.instance_id) and item.condition == 100 and state.cash == 60,"Existing optional repair can precede market sale")
	test.check(AntiqueMarketService.market_value(item,definition) == 1600 and AntiqueMarketService.dealer_offer(1600) == 1200 and AntiqueMarketService.reserve_price(1600,1) > AntiqueMarketService.reserve_price(value,1),"Repair increases market/dealer/reserve without mutating base resource")
	var next_id := state.collection.next_id()
	test.check(state.sell_to_dealer(item.instance_id) and state.cash == 1260 and not state.collection.contains(item.instance_id),"Dealer precisely credits1200 and removes unique instance atomically")
	test.check(not state.sell_to_dealer(item.instance_id) and not state.repair(item.instance_id) and not state.assign(&"CASE_1",item.instance_id) and not state.consign(item.instance_id,1) and state.cash == 1260,"Sold instance cannot generate cash/repair/exhibit/auction again")
	var replacement := state.collection.add(item.definition_id,1,76,true)
	test.check(state.collection.next_id() == next_id+1 and replacement.instance_id != item.instance_id and definition.base_value == 1600 and definition.exhibit_appeal == 50,"New same Definition gets later ID, shared value/appeal remain read-only")
	var history_by_mode: Array[int] = [0,0,0]
	for seed in range(100):
		var first := AuctionBidding.new()
		first.configure(replacement,definition,5,seed,1)
		var second := AuctionBidding.new()
		second.configure(replacement,definition,5,seed,1)
		test.check(first.budgets.size() == 3 and first.budgets == second.budgets,"Independent three NPC budgets repeat exactly seed%d" % seed)
		for rounds in range(100):
			if first.finished: break
			var old := first.current_bid
			var previous_bidder := first.highest_bidder
			first.next_round()
			second.next_round()
			if first.current_bid > old:
				test.check(first.highest_bidder != previous_bidder,"Successive bids must come from competing bidders, never self-raise")
				test.check(first.current_bid <= first.budgets[first.highest_bidder] and first.current_bid == (first.starting_bid if old == 0 else old+first.bid_step),"One legal incremental quote within winning NPC budget")
		test.check(first.finished and first.history == second.history and first.result.sold == second.result.sold and first.result.final_bid == second.result.final_bid,"Bounded same-input full auction result/history deterministic seed%d" % seed)
		var final_history := first.history.duplicate()
		var competition_finished: bool = true
		for index in range(first.budgets.size()):
			if index != first.highest_bidder and first.budgets[index] >= first.current_bid+first.bid_step: competition_finished = false
		test.check(competition_finished,"Auction ends when no other bidder can beat current leader")
		test.check(not first.next_round() and first.history == final_history,"Completed bidding cannot emit another quote")
		for mode in range(3):
			var bidding := AuctionBidding.new()
			bidding.configure(replacement,definition,5,seed,mode)
			for round_index in range(100):
				if bidding.finished: break
				bidding.next_round()
			if bidding.result.sold: history_by_mode[mode] += 1
	test.check(history_by_mode[0] >= history_by_mode[1] and history_by_mode[1] > history_by_mode[2] and history_by_mode[2] < 100,"LOW/NORMAL/HIGH have distinct deterministic sale rates, high reserve can fail")
	print("[8D rates] LOW=%d NORMAL=%d HIGH=%d /100" % history_by_mode)
	var common := OwnedAntique.new()
	common.instance_id = &"A000999"
	common.definition_id = &"blue_white_jar"
	common.condition = 90
	common.identified = true
	var common_rates: Array[int] = [0,0,0]
	for seed in range(512):
		for mode in range(3):
			var comparison := AuctionBidding.new()
			comparison.configure(common,MuseumState.POOL.find_by_id(common.definition_id),5,seed,mode)
			for round_index in range(100):
				if comparison.finished: break
				comparison.next_round()
			if comparison.result.sold: common_rates[mode] += 1
	test.check(common_rates[0] > common_rates[1] and common_rates[1] > common_rates[2],"COMMON fixed sample demonstrates strict LOW>NORMAL>HIGH sale rate differences")
	print("[8D common rates] LOW=%d NORMAL=%d HIGH=%d /512" % common_rates)
	var lone := AuctionBidding.new()
	lone.configure(replacement,definition,5,1,0)
	lone.budgets = [lone.starting_bid+10*lone.bid_step,0,0]
	test.check(lone.next_round() and lone.highest_bidder == 0 and lone.current_bid == lone.starting_bid,"Single eligible bidder wins starting quote despite surplus budget")
	test.check(not lone.next_round() and lone.finished and lone.result.final_bid == lone.starting_bid,"Single remaining bidder cannot inflate its own bid to reserve")
	var competing := AuctionBidding.new()
	competing.configure(replacement,definition,5,1,0)
	competing.budgets = [competing.starting_bid+10*competing.bid_step,competing.starting_bid+competing.bid_step,0]
	competing.next_round()
	competing.next_round()
	test.check(competing.highest_bidder == 1,"Another eligible bidder genuinely raises price")
	competing.next_round()
	test.check(competing.highest_bidder == 0 and competing.current_bid == competing.starting_bid+2*competing.bid_step,"Former leader may counterbid after rival overtakes it")
	test.check(not competing.next_round() and competing.finished,"Competition ends without further self-raising")
	# Settlement unit edge: only the pending ID admits one transaction, even under repeated calls.
	state.consign(replacement.instance_id,0)
	var bidding := AuctionBidding.new()
	bidding.configure(replacement,definition,state.day_number,1,0)
	for rounds in range(100):
		if bidding.finished: break
		bidding.next_round()
	var cash_before := state.cash
	state.phase = MuseumState.Phase.NIGHT
	test.check(state.settle_auction(bidding.result) and state.cash == cash_before+bidding.result.net_proceeds and not state.collection.contains(replacement.instance_id) and state.auction_lot_instance_id == &"","Sold settlement credits net once/removes item/clears lock")
	test.check(not state.settle_auction(bidding.result) and state.cash == cash_before+bidding.result.net_proceeds,"Old result cannot settle twice")
