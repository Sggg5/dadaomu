class_name AuctionBidding
extends RefCounted
## 一口一轮的确定性状态机；价格/预算仅向MarketService索取。
var instance_id: StringName
var market_value: int
var reserve_price: int
var starting_bid: int
var bid_step: int
var budgets: Array[int] = []
var current_bid: int = 0
var highest_bidder: int = -1
var history: Array[String] = []
var finished: bool = false
var result: AuctionResult
var _cursor: int = 0
var _withdrawn: Dictionary[int,bool] = {}


func configure(item: OwnedAntique, definition: AntiqueDefinition, day: int, auction_seed: int, mode: int) -> void:
	instance_id = item.instance_id
	market_value = AntiqueMarketService.market_value(item,definition)
	reserve_price = AntiqueMarketService.reserve_price(market_value,mode)
	starting_bid = AntiqueMarketService.starting_bid(market_value)
	bid_step = AntiqueMarketService.bid_step(market_value)
	budgets = AntiqueMarketService.npc_budgets(item,definition,day,auction_seed)


func next_round() -> bool:
	if finished: return false
	var next_price := starting_bid if current_bid == 0 else current_bid+bid_step
	for offset in range(budgets.size()):
		var index := (_cursor+offset)%budgets.size()
		# 领先者没有竞争报价时不应自己抬价，即使其预算仍有余量。
		if index == highest_bidder: continue
		if budgets[index] < next_price:
			if not _withdrawn.has(index):
				_withdrawn[index] = true
				history.append("%s退出竞价。" % AntiqueMarketService.CONFIG.bidder_names[index])
			continue
		current_bid = next_price
		highest_bidder = index
		_cursor = (index+1)%budgets.size()
		history.append("%s：%s！" % [AntiqueMarketService.CONFIG.bidder_names[index],AntiqueDefinition.money(current_bid)])
		return true
	finish()
	return false


func finish() -> void:
	if finished: return
	finished = true
	result = AuctionResult.new()
	result.instance_id = instance_id
	result.market_value = market_value
	result.reserve_price = reserve_price
	result.final_bid = current_bid
	result.sold = highest_bidder >= 0 and current_bid >= reserve_price
	result.commission = AntiqueMarketService.commission(current_bid) if result.sold else 0
	result.net_proceeds = AntiqueMarketService.net_proceeds(current_bid) if result.sold else 0
	history.append("成交" if result.sold else "流拍：最高报价未达到保留价")
	result.bid_history = history.duplicate()
