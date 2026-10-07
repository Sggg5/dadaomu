class_name AntiqueMarketService
extends RefCounted
## 单一经济公式入口。只读定义/实例数值，不操作钱包、不消耗Dungeon RNG。
enum Reserve { LOW, NORMAL, HIGH }
const CONFIG: AntiqueMarketConfig = preload("res://data/market/default_market_config.tres")


static func round_to_10(value: float) -> int: return roundi(value/10.0)*10


static func market_value(item: OwnedAntique, definition: AntiqueDefinition) -> int:
	if item == null or definition == null or not item.identified: return 0
	return roundi(definition.base_value*item.condition/100.0)


static func dealer_offer(value: int) -> int: return maxi(10,round_to_10(value*CONFIG.dealer_ratio))


static func reserve_price(value: int, mode: int) -> int:
	if mode < Reserve.LOW or mode > Reserve.HIGH: return 0
	return maxi(10,round_to_10(value*CONFIG.reserve_ratios[mode]))


static func starting_bid(value: int) -> int: return maxi(10,round_to_10(value*CONFIG.starting_ratio))


static func bid_step(value: int) -> int: return maxi(10,round_to_10(value*CONFIG.bid_step_ratio))


static func net_proceeds(final_bid: int) -> int: return floori(final_bid*(1.0-CONFIG.commission_ratio))


static func commission(final_bid: int) -> int: return final_bid-net_proceeds(final_bid)


static func npc_budgets(item: OwnedAntique, definition: AntiqueDefinition, day: int, auction_seed: int) -> Array[int]:
	var rng := RandomNumberGenerator.new()
	rng.seed = AntiquePool.stable_score(auction_seed,day,item.instance_id,StringName("%s|%d" % [item.definition_id,item.condition]),1)
	var value := market_value(item,definition)
	var budgets: Array[int] = []
	for index in range(CONFIG.bidder_names.size()):
		var ratio := rng.randf_range(CONFIG.budget_min[index],CONFIG.budget_max[index])+CONFIG.rarity_bonus[definition.rarity]
		budgets.append(maxi(10,round_to_10(value*ratio)))
	return budgets


static func reserve_name(mode: int) -> String:
	return ["低保留价（80%）","标准保留价（100%）","高保留价（130%）"][mode] if mode in [Reserve.LOW,Reserve.NORMAL,Reserve.HIGH] else "无效保留价"
