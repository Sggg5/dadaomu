class_name MuseumProfileStore
extends RefCounted
## 版本化地面JSON。只编码纯值，内存/路径可注入；不保存Night Run。
const VERSION: int = 3
var save_path: String = "user://museum_profile_v1.json"
var memory_only: bool = false
var save_count: int = 0
var last_error: String = ""
var _memory: Dictionary = {}


static func in_memory() -> MuseumProfileStore:
	var store := MuseumProfileStore.new()
	store.memory_only = true
	return store


func encode(state: MuseumState) -> Dictionary:
	var items: Array[Dictionary] = []
	for item in state.collection.all_items():
		items.append({"instance_id":str(item.instance_id),"definition_id":str(item.definition_id),"acquired_day":item.acquired_day,"identified":item.identified,"condition":item.condition})
	var assignments: Dictionary[String,String] = {}
	for id in state.display_assignments: assignments[str(id)] = str(state.display_assignments[id])
	return {"version":VERSION,"day_number":state.day_number,"phase":"EVENING" if state.phase == MuseumState.Phase.EVENING else "MORNING","cash":state.cash,"museum_level":state.museum_level,"next_antique_id":state.collection.next_id(),"collection":items,"display_assignments":assignments,"last_day_visitors":state.last_day_visitors,"last_day_ticket_income":state.last_day_ticket_income,"auction_lot_instance_id":str(state.auction_lot_instance_id),"auction_reserve_mode":state.auction_reserve_mode}


func save_profile(state: MuseumState) -> bool:
	# OPEN现金仍在流动，NIGHT背包仍有风险，都不属于可保存地面快照。
	if not state.can_edit(): return false
	last_error = ""
	var payload := encode(state)
	if memory_only:
		_memory = payload.duplicate(true)
	else:
		var directory := ProjectSettings.globalize_path(save_path).get_base_dir()
		if DirAccess.make_dir_recursive_absolute(directory) != OK: return _failed("无法创建存档目录")
		var temporary := save_path+".tmp"
		var file := FileAccess.open(temporary,FileAccess.WRITE)
		if file == null: return _failed("无法写入存档")
		file.store_string(JSON.stringify(payload,"\t"))
		file.flush()
		var error := file.get_error()
		file.close()
		if error != OK: return _failed("存档写入失败")
		if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(save_path)) != OK: return _failed("无法替换存档")
	save_count += 1
	return true


func load_profile() -> MuseumState:
	last_error = ""
	if memory_only: return decode(_memory) if not _memory.is_empty() else MuseumState.new()
	if not FileAccess.file_exists(save_path): return MuseumState.new()
	var file := FileAccess.open(save_path,FileAccess.READ)
	if file == null:
		_failed("无法读取存档，使用新档")
		return MuseumState.new()
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	if error != OK:
		_failed("存档JSON损坏，使用新档")
		return MuseumState.new()
	return decode(json.data)


func decode(payload: Variant) -> MuseumState:
	var state := MuseumState.new()
	if not payload is Dictionary:
		_failed("存档根字段异常，使用新档")
		return state
	var bounds := {"version":[1,VERSION],"day_number":[1,1000000],"cash":[0,1000000000],"museum_level":[0,MuseumState.LEVELS.highest_level()],"next_antique_id":[1,1000000000]}
	for key in bounds:
		var range_value: Array = bounds[key]
		if not _integer(payload.get(key),range_value[0],range_value[1]):
			_failed("存档版本/数值字段异常，使用新档")
			return state
	if not payload.get("collection") is Array or not payload.get("display_assignments") is Dictionary:
		_failed("存档集合字段异常，使用新档")
		return state
	if payload.get("phase","MORNING") not in ["MORNING","EVENING"]:
		_failed("存档不是安全地面阶段，使用新档")
		return state
	state.day_number = int(payload.day_number)
	state.cash = int(payload.cash)
	state.museum_level = int(payload.museum_level)
	var items: Array[OwnedAntique] = []
	var seen: Dictionary[StringName,bool] = {}
	for row in payload.collection:
		if not row is Dictionary or not row.get("instance_id") is String or not row.get("definition_id") is String or not _integer(row.get("acquired_day"),0,state.day_number):
			_failed("跳过异常馆藏条目")
			continue
		var id := StringName(row.instance_id)
		var suffix := str(id).trim_prefix("A")
		if not str(id).begins_with("A") or not suffix.is_valid_int() or suffix.to_int() <= 0 or suffix.to_int() >= 1000000000 or seen.has(id) or MuseumState.POOL.find_by_id(StringName(row.definition_id)) == null:
			_failed("跳过未知定义/重复或非法馆藏ID")
			continue
		var item := OwnedAntique.new()
		# v1已有合法展品保留满品相；v2+逐条验证，异常条目跳过。
		if int(payload.version) >= 2 and (not row.get("identified") is bool or not _integer(row.get("condition"),0,100)):
			_failed("跳过异常鉴定/品相条目")
			continue
		item.identified = true if int(payload.version) == 1 else bool(row.identified)
		item.condition = 100 if int(payload.version) == 1 else int(row.condition)
		item.instance_id = id
		item.definition_id = StringName(row.definition_id)
		item.acquired_day = int(row.acquired_day)
		items.append(item)
		seen[id] = true
	state.collection.restore(items,int(payload.next_antique_id))
	for case_id in payload.display_assignments:
		var id: Variant = payload.display_assignments[case_id]
		if not case_id is String or not id is String or not state.assign(StringName(case_id),StringName(id)): _failed("忽略非法/未解锁/重复展柜归属")
	# 先恢复展柜归属再检查待拍，发生冲突时优先保留旧展品。
	if int(payload.version) >= 3:
		var pending: Variant = payload.get("auction_lot_instance_id","")
		var mode: Variant = payload.get("auction_reserve_mode",AntiqueMarketService.Reserve.NORMAL)
		if not pending is String or not _integer(mode,0,2):
			_failed("清理异常待拍字段")
		elif pending != "" and not state.consign(StringName(pending),int(mode)):
			_failed("清理不存在/未鉴定/已展出待拍品，优先保留展柜")
	for key in ["last_day_visitors","last_day_ticket_income"]:
		if _integer(payload.get(key,0),0,1000000000): state.set(key,int(payload.get(key,0)))
	state.phase = MuseumState.Phase.EVENING if payload.get("phase","MORNING") == "EVENING" else MuseumState.Phase.MORNING
	return state


func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= minimum and value <= maximum


func _failed(message: String) -> bool:
	last_error = message
	push_warning(message)
	return false
