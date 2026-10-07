class_name GameFlow
extends Node
## 顶层只装配白天/夜晚，安全结果按ID转成馆藏实例；不接触房间或游客算法。
const MUSEUM_SCENE: PackedScene = preload("res://scenes/museum/museum.tscn")
const DUNGEON_SCENE: PackedScene = preload("res://scenes/main/dungeon_test.tscn")
const AUCTION_SCENE: PackedScene = preload("res://scenes/auction/auction_session.tscn")
@export var museum_config: MuseumConfig = preload("res://data/museum/default_config.tres")
@export var museum_seed: int = 192034
@export var night_seed: int = 192034
@export var auction_seed: int = 192034
@export var tomb_exploration_enabled: bool = true
# 仅自动测试显式启用；正式新游戏没有赠送馆藏。
@export var initial_test_collection: bool = false
@export var profile_path: String = "user://museum_profile_v1.json"
var profile_store: MuseumProfileStore
var museum_state := MuseumState.new()
var current_dungeon_result: RunResult
var museum: Museum
var dungeon: DungeonSession
var auction: AuctionSession
var current_auction_result: AuctionResult
var _changing: bool = false
var current_day: int:
	get: return museum_state.day_number
var current_phase: MuseumState.Phase:
	get: return museum_state.phase


func _ready() -> void:
	if profile_store == null:
		profile_store = MuseumProfileStore.new()
		profile_store.save_path = profile_path
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed=") and argument.trim_prefix("--seed=").is_valid_int(): night_seed = argument.trim_prefix("--seed=").to_int()
		if argument.begins_with("--profile-path="): profile_store.save_path = argument.trim_prefix("--profile-path=")
	museum_state = profile_store.load_profile()
	museum_state.changed.connect(_save_profile)
	if initial_test_collection: museum_state.collection.add(&"tang_sancai_horse",0,100,true)
	_show_museum("原型馆藏：唐三彩马 · 可布展/开馆，也可到情报板直接下墓" if initial_test_collection else "地面状态已恢复 · 可整理展品，也可到情报板下墓",museum_state.phase)
	if not profile_store.last_error.is_empty(): museum.message.text = profile_store.last_error
	_save_profile()


func _show_museum(notice: String, phase: MuseumState.Phase = MuseumState.Phase.MORNING) -> void:
	museum_state.phase = phase
	museum = MUSEUM_SCENE.instantiate() as Museum
	museum.state = museum_state
	museum.config = museum_config
	museum.museum_seed = museum_seed
	museum.morning_notice = notice
	museum.night_requested.connect(start_night)
	museum.auction_requested.connect(start_auction)
	add_child(museum)
	_changing = false


func start_night() -> bool:
	if not _prepare_night(): return false
	_enter_night.call_deferred()
	return true


func _prepare_night() -> bool:
	if _changing or current_phase not in [MuseumState.Phase.MORNING,MuseumState.Phase.EVENING]: return false
	if current_phase == MuseumState.Phase.MORNING:
		museum_state.last_day_visitors = 0
		museum_state.last_day_ticket_income = 0
	if not _save_profile(): return false
	_changing = true
	museum.player.controls_enabled = false
	museum_state.phase = MuseumState.Phase.NIGHT
	return true


func start_auction() -> bool:
	var item := museum_state.collection.find(museum_state.auction_lot_instance_id)
	if item == null or not item.identified or museum_state.case_for(item.instance_id) != &"": return false
	if not _prepare_night(): return false
	_enter_auction.call_deferred()
	return true


func _enter_auction() -> void:
	remove_child(museum)
	museum.queue_free()
	museum = null
	current_dungeon_result = null
	current_auction_result = null
	auction = AUCTION_SCENE.instantiate() as AuctionSession
	var item := museum_state.collection.find(museum_state.auction_lot_instance_id)
	auction.configure(item,MuseumState.POOL.find_by_id(item.definition_id),current_day,auction_seed,museum_state.auction_reserve_mode)
	auction.return_requested.connect(return_from_auction)
	add_child(auction)
	_changing = false


func return_from_auction(result: AuctionResult) -> bool:
	if _changing or current_phase != MuseumState.Phase.NIGHT or auction == null or not auction.bidding.finished or result != auction.bidding.result: return false
	_changing = true
	_return_auction_morning.call_deferred(result)
	return true


func _return_auction_morning(result: AuctionResult) -> void:
	if not museum_state.settle_auction(result):
		_changing = false
		auction.info.text = "拍卖结算数据不一致，无法重复提交。请退出后恢复安全地面。"
		return
	current_auction_result = result
	var notice := "昨夜拍卖成交 · 成交%s · 佣金%s · 实际到账%s" % [AntiqueDefinition.money(result.final_bid),AntiqueDefinition.money(result.commission),AntiqueDefinition.money(result.net_proceeds)] if result.sold else "昨夜流拍 · 古董已退回库房，待拍锁定解除 · 本次无收入"
	remove_child(auction)
	auction.queue_free()
	auction = null
	museum_state.day_number += 1
	_show_museum(notice)
	_save_profile()


func _enter_night() -> void:
	remove_child(museum)
	museum.queue_free()
	museum = null
	current_dungeon_result = null
	current_auction_result = null
	dungeon = DUNGEON_SCENE.instantiate() as DungeonSession
	dungeon.hub_mode = true
	dungeon.exploration_enabled = tomb_exploration_enabled
	dungeon.collection_day = current_day
	dungeon.seed_value = night_seed
	dungeon.run_started.connect(func() -> void: current_dungeon_result = null)
	dungeon.result_ready.connect(func(result: RunResult) -> void: current_dungeon_result = result)
	dungeon.return_requested.connect(return_from_night)
	add_child(dungeon)
	_changing = false


func return_from_night(result: RunResult) -> bool:
	if _changing or current_phase != MuseumState.Phase.NIGHT or dungeon == null or not dungeon.run_ended or not is_instance_valid(dungeon.complete_screen) or result != dungeon.complete_screen.result: return false
	_changing = true
	_return_morning.call_deferred(result)
	return true


func _return_morning(result: RunResult) -> void:
	current_dungeon_result = result
	var names: Array[String] = []
	if result.outcome in [RunResult.Outcome.EXTRACTED,RunResult.Outcome.COMPLETED]:
		for index in range(result.antique_ids.size()):
			var id := result.antique_ids[index]
			var definition := MuseumState.POOL.find_by_id(id)
			if definition == null: continue
			if index >= result.antique_conditions.size(): continue
			museum_state.collection.add(id,current_day,result.antique_conditions[index],false)
			names.append(definition.display_name)
	var notice := "昨夜新入藏：%s · 已存入库房，待正式鉴定" % ("、".join(names) if not names.is_empty() else "无")
	if result.outcome == RunResult.Outcome.DEAD: notice = "昨夜探墓失败 · 遗失古董 %s · 没有新藏品带回" % AntiqueDefinition.money(result.antique_value)
	remove_child(dungeon)
	dungeon.queue_free()
	dungeon = null
	museum_state.day_number += 1
	_show_museum(notice)
	_save_profile()


func _save_profile() -> bool:
	if not museum_state.can_edit(): return false
	if profile_store.save_profile(museum_state): return true
	if is_instance_valid(museum): museum.message.text = "保存失败："+profile_store.last_error
	return false
