class_name GameFlow
extends Node
## 顶层只装配白天/夜晚，安全结果按ID转成馆藏实例；不接触房间或游客算法。
const MUSEUM_SCENE: PackedScene = preload("res://scenes/museum/museum.tscn")
const DUNGEON_SCENE: PackedScene = preload("res://scenes/main/dungeon_test.tscn")
@export var museum_config: MuseumConfig = preload("res://data/museum/default_config.tres")
@export var museum_seed: int = 192034
@export var night_seed: int = 192034
@export var initial_test_collection: bool = true
var museum_state := MuseumState.new()
var current_dungeon_result: RunResult
var museum: Museum
var dungeon: DungeonSession
var _changing: bool = false
var current_day: int:
	get: return museum_state.day_number
var current_phase: MuseumState.Phase:
	get: return museum_state.phase


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed=") and argument.trim_prefix("--seed=").is_valid_int(): night_seed = argument.trim_prefix("--seed=").to_int()
	if initial_test_collection: museum_state.collection.add(&"tang_sancai_horse",0)
	_show_museum("原型馆藏：唐三彩马 · 可布展/开馆，也可到情报板直接下墓" if initial_test_collection else "早晨 · 可开馆，也可到情报板直接下墓")


func _show_museum(notice: String) -> void:
	museum_state.phase = MuseumState.Phase.MORNING
	museum = MUSEUM_SCENE.instantiate() as Museum
	museum.state = museum_state
	museum.config = museum_config
	museum.museum_seed = museum_seed
	museum.morning_notice = notice
	museum.night_requested.connect(start_night)
	add_child(museum)
	_changing = false


func start_night() -> bool:
	if _changing or current_phase not in [MuseumState.Phase.MORNING,MuseumState.Phase.EVENING]: return false
	if current_phase == MuseumState.Phase.MORNING:
		museum_state.last_day_visitors = 0
		museum_state.last_day_ticket_income = 0
	_changing = true
	museum.player.controls_enabled = false
	museum_state.phase = MuseumState.Phase.NIGHT
	_enter_night.call_deferred()
	return true


func _enter_night() -> void:
	remove_child(museum)
	museum.queue_free()
	museum = null
	current_dungeon_result = null
	dungeon = DUNGEON_SCENE.instantiate() as DungeonSession
	dungeon.hub_mode = true
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
		for id in result.antique_ids:
			var definition := MuseumState.POOL.find_by_id(id)
			if definition == null: continue
			museum_state.collection.add(id,current_day)
			names.append(definition.display_name)
	var notice := "昨夜新入藏：%s · 已存入库房" % ("、".join(names) if not names.is_empty() else "无")
	if result.outcome == RunResult.Outcome.DEAD: notice = "昨夜探墓失败 · 遗失古董 %s · 没有新藏品带回" % AntiqueDefinition.money(result.antique_value)
	remove_child(dungeon)
	dungeon.queue_free()
	dungeon = null
	museum_state.day_number += 1
	_show_museum(notice)
