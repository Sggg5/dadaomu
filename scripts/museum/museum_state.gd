class_name MuseumState
extends RefCounted
## 纯地面状态；展柜按馆藏实例ID归属。存档编解码由ProfileStore承担。
enum Phase { MORNING, OPEN, EVENING, NIGHT }
const LEVELS: MuseumLevels = preload("res://data/museum/levels.tres")
const POOL: AntiquePool = preload("res://data/antiques/playtest_catalog_50.tres")
signal changed
var day_number: int = 1
var campaign_seed: int = 0 # 0仅为新档/迁移待初始化，正式v4存档必须是正31位整数。
var cash: int = 0
var museum_level: int = 0
var phase: Phase = Phase.MORNING
var collection := MuseumCollection.new()
var display_catalog := MuseumDisplayCatalog.new()
# Stable DisplaySlot IDs -> OwnedAntique instance IDs. CASE_n is the migrated first slot.
var display_assignments: Dictionary[StringName, StringName] = {}
var facilities:=MuseumFacilityState.new()
var daily_reports: Dictionary[int,Dictionary] = {}
var exhibition_plans: Dictionary[StringName,StringName] = {}
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
	facilities.record(day_number,"HALL_EXPANSION","MUSEUM",cost,museum_level,museum_level+1)
	museum_level += 1
	changed.emit()
	return true


func case_for(instance_id: StringName) -> StringName:
	for id in display_assignments:
		if display_assignments[id] == instance_id: return id
	return &""


func can_edit() -> bool: return phase in [Phase.MORNING, Phase.EVENING]


func assign(case_id: StringName, instance_id: StringName) -> bool:
	# Historical callers target the first slot; production management selects a slot.
	if not display_catalog.units.has(case_id): return false
	return place(display_catalog.units[case_id].slots()[0].id,instance_id)

func place(slot_id: StringName, instance_id: StringName) -> bool:
	if not can_assign(instance_id) or not display_catalog.slots.has(slot_id): return false
	var slot := display_catalog.slots[slot_id]
	var unit := display_catalog.units[slot.unit_id]
	if unit.unlock_level > museum_level: return false
	var occupied := case_for(instance_id)
	if occupied != &"" and occupied != slot_id: return false
	var item := collection.find(instance_id)
	if not display_catalog.accepts(unit,display_catalog.profiles.get(str(item.definition_id),{})): return false
	display_assignments[slot_id] = instance_id
	changed.emit()
	return true

func unassign(slot_id: StringName) -> bool:
	if not can_edit() or not display_assignments.has(slot_id): return false
	display_assignments.erase(slot_id)
	changed.emit()
	return true

func unit_items(unit_id: StringName) -> Array[OwnedAntique]:
	var result: Array[OwnedAntique] = []
	if not display_catalog.units.has(unit_id): return result
	for slot in display_catalog.units[unit_id].slots():
		var item := collection.find(display_assignments.get(slot.id,&""))
		if item != null: result.append(item)
	return result

func withdraw_unit(unit_id: StringName) -> bool:
	if not can_edit() or not display_catalog.units.has(unit_id): return false
	for slot in display_catalog.units[unit_id].slots(): display_assignments.erase(slot.id)
	changed.emit()
	return true

func fill_unit(unit_id: StringName, candidates: Array) -> int:
	if not can_edit() or not display_catalog.units.has(unit_id): return 0
	var count := 0
	var unit := display_catalog.units[unit_id]
	# Validate candidates before touching each independent empty slot; no overwrites.
	for slot in unit.slots():
		if display_assignments.has(slot.id): continue
		for candidate in candidates:
			if not (candidate is StringName or candidate is String):continue
			var id:=StringName(candidate)
			var item := collection.find(id)
			if can_assign(id) and case_for(id) == &"" and display_catalog.accepts(unit,display_catalog.profiles.get(str(item.definition_id),{})):
				display_assignments[slot.id] = id
				count += 1
				break
	if count > 0: changed.emit()
	return count

func definition_for(case_id: StringName) -> AntiqueDefinition:
	var items := unit_items(case_id)
	return POOL.find_by_id(items[0].definition_id) if not items.is_empty() else null

func displayed_appeals() -> Dictionary[StringName,int]:
	var ordered: Array[OwnedAntique] = []
	for id in display_assignments.values():
		var item := collection.find(id)
		if item != null and item.identified: ordered.append(item)
	ordered.sort_custom(func(a: OwnedAntique,b: OwnedAntique)->bool:
		var aa:=appeal_for(a.instance_id)
		var bb:=appeal_for(b.instance_id)
		return aa>bb if aa!=bb else str(a.instance_id)<str(b.instance_id))
	var counts: Dictionary = {}
	var result: Dictionary[StringName,int] = {}
	for item in ordered:
		var repeat: int = counts.get(item.definition_id,0)
		var factor:=maxf(display_catalog.minimum_repeat_factor,pow(display_catalog.repeat_decay,repeat))
		result[item.instance_id]=maxi(0,roundi(appeal_for(item.instance_id)*factor))
		counts[item.definition_id]=repeat+1
	return result

func total_appeal() -> int:
	var total:=0
	for value: int in displayed_appeals().values(): total+=value
	return total

func unit_appeal(unit_id: StringName) -> int:
	var values:=displayed_appeals()
	var total:=0
	for item in unit_items(unit_id): total+=values.get(item.instance_id,0)
	return total

func displayed_halls() -> Array[StringName]:
	var result: Array[StringName]=[]
	var appeals:=displayed_appeals()
	for id in display_assignments:
		if appeals.get(display_assignments[id],0)<=0:continue
		if display_catalog.slots.has(id):
			var hall:=display_catalog.slots[id].hall_id
			if hall not in result: result.append(hall)
	result.sort_custom(func(a:StringName,b:StringName)->bool:return str(a)<str(b))
	return result

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
