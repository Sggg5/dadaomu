class_name MuseumState
extends RefCounted
## 纯地面状态；展柜按馆藏实例ID归属。存档编解码由ProfileStore承担。
enum Phase { MORNING, OPEN, EVENING, NIGHT }
const LEVELS: MuseumLevels = preload("res://data/museum/levels.tres")
const POOL: AntiquePool = preload("res://data/antiques/formal_pool.tres")
signal changed
var day_number: int = 1
var cash: int = 0
var museum_level: int = 0
var phase: Phase = Phase.MORNING
var collection := MuseumCollection.new()
var display_assignments: Dictionary[StringName, StringName] = {}
var last_day_visitors: int = 0
var last_day_ticket_income: int = 0
var auction_lot_instance_id: StringName = &""
var auction_reserve_mode: int = AntiqueMarketService.Reserve.NORMAL


func level_definition() -> MuseumLevelDefinition: return LEVELS.at(museum_level)


func case_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for index in range(level_definition().case_count): ids.append(StringName("CASE_%d" % (index+1)))
	return ids


func upgrade(expected_level: int) -> bool:
	# 调用携带打开建设牌时的等级：同一旧请求重复执行不可能再次扣款。
	if expected_level != museum_level or not can_edit() or museum_level >= LEVELS.highest_level(): return false
	var cost := level_definition().upgrade_cost
	if cash < cost: return false
	cash -= cost
	museum_level += 1
	changed.emit()
	return true


func case_for(instance_id: StringName) -> StringName:
	for id in display_assignments:
		if display_assignments[id] == instance_id: return id
	return &""


func can_edit() -> bool: return phase in [Phase.MORNING, Phase.EVENING]


func assign(case_id: StringName, instance_id: StringName) -> bool:
	if case_id not in case_ids() or not can_assign(instance_id): return false
	if case_for(instance_id) != &"" and case_for(instance_id) != case_id: return false
	display_assignments[case_id] = instance_id
	changed.emit()
	return true


func unassign(case_id: StringName) -> bool:
	if not can_edit() or not display_assignments.has(case_id): return false
	display_assignments.erase(case_id)
	changed.emit()
	return true


func definition_for(case_id: StringName) -> AntiqueDefinition:
	var item := collection.find(display_assignments.get(case_id, &""))
	return POOL.find_by_id(item.definition_id) if item != null else null


func total_appeal() -> int:
	var appeal: int = 0
	for id in case_ids():
		appeal += appeal_for(display_assignments.get(id,&""))
	return appeal


func appeal_for(instance_id: StringName) -> int:
	var item := collection.find(instance_id)
	if item == null or not item.identified: return 0
	var definition := POOL.find_by_id(item.definition_id)
	return maxi(1,roundi(definition.exhibit_appeal*item.condition/100.0)) if definition != null else 0


func identify(instance_id: StringName) -> bool:
	var item := collection.find(instance_id)
	if not can_edit() or item == null or item.identified: return false
	item.identified = true
	changed.emit()
	return true


func restoration_cost(instance_id: StringName) -> int:
	var item := collection.find(instance_id)
	if item == null or not item.identified or item.condition >= 100: return 0
	var definition := POOL.find_by_id(item.definition_id)
	if definition == null: return 0
	var unit_cost: int = [20,40,60,100][definition.rarity]
	return ceili((100-item.condition)/10.0)*unit_cost


func repair(instance_id: StringName) -> bool:
	var cost := restoration_cost(instance_id)
	if not can_repair(instance_id) or cost <= 0 or cash < cost: return false
	# 原子事务后通知存档/UI；满品相再次调用拒绝，不产生半完成状态。
	cash -= cost
	collection.find(instance_id).condition = 100
	changed.emit()
	return true


func is_auction_locked(instance_id: StringName) -> bool:
	return instance_id != &"" and auction_lot_instance_id == instance_id


func can_assign(instance_id: StringName) -> bool:
	var item := collection.find(instance_id)
	return can_edit() and item != null and item.identified and not is_auction_locked(instance_id)


func can_repair(instance_id: StringName) -> bool:
	var item := collection.find(instance_id)
	return can_assign(instance_id) and item.condition < 100


func can_sell(instance_id: StringName) -> bool:
	return can_assign(instance_id) and case_for(instance_id) == &""


func can_consign(instance_id: StringName) -> bool:
	return auction_lot_instance_id == &"" and can_sell(instance_id)


func sell_to_dealer(instance_id: StringName) -> bool:
	if not can_sell(instance_id): return false
	var item := collection.find(instance_id)
	var value := AntiqueMarketService.market_value(item,POOL.find_by_id(item.definition_id))
	cash += AntiqueMarketService.dealer_offer(value)
	collection.remove(instance_id)
	changed.emit() # 钱与身份都已提交后，唯一State通知才触发地面保存。
	return true


func consign(instance_id: StringName, mode: int) -> bool:
	if not can_consign(instance_id) or mode not in [0,1,2]: return false
	auction_lot_instance_id = instance_id
	auction_reserve_mode = mode
	changed.emit()
	return true


func cancel_consignment() -> bool:
	if not can_edit() or auction_lot_instance_id == &"": return false
	auction_lot_instance_id = &""
	auction_reserve_mode = AntiqueMarketService.Reserve.NORMAL
	changed.emit()
	return true


func settle_auction(result: AuctionResult) -> bool:
	# 一次性凭据是仍存在的pending ID；旧结果/重复回馆不可能再次提款。
	if phase != Phase.NIGHT or result == null or not is_auction_locked(result.instance_id): return false
	var item := collection.find(result.instance_id)
	if item == null or not item.identified or case_for(item.instance_id) != &"": return false
	var value := AntiqueMarketService.market_value(item,POOL.find_by_id(item.definition_id))
	if result.market_value != value or result.reserve_price != AntiqueMarketService.reserve_price(value,auction_reserve_mode): return false
	if result.sold:
		if result.final_bid < result.reserve_price or result.net_proceeds != AntiqueMarketService.net_proceeds(result.final_bid) or result.commission != AntiqueMarketService.commission(result.final_bid): return false
		cash += result.net_proceeds
		collection.remove(result.instance_id)
	elif result.final_bid >= result.reserve_price or result.net_proceeds != 0 or result.commission != 0:
		return false
	auction_lot_instance_id = &""
	auction_reserve_mode = AntiqueMarketService.Reserve.NORMAL
	changed.emit()
	return true
