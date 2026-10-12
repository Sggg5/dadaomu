class_name ProfessionRunState
extends RefCounted
## One expedition owns this value state. No UI nodes, ordinary relics or antiques.
signal changed
const IDS: Array[StringName] = [&"MOJIN", &"FAQIU", &"BANSHAN", &"XIELING"]
var _tokens: Array[StringName] = []
var _active: StringName = &"NONE"
var _initial: StringName = &"NONE"
var _spent: Dictionary = {}
var _identities: Dictionary = {}
var _searched: Dictionary = {}
var _ended: bool = false
var guard_ready: bool = false
var catalog_note: String = ""
var active_id: StringName:
	get: return _active
var initial_id: StringName:
	get: return _initial
static func valid_id(id: StringName) -> bool:
	return id == &"NONE" or id in IDS
func begin(initial: StringName) -> void:
	assert(valid_id(initial))
	_tokens.clear(); _spent.clear(); _identities.clear(); _searched.clear()
	_ended = false
	guard_ready = false; catalog_note = ""
	_initial = initial
	_active = initial
	if initial != &"NONE": _tokens.append(initial)
	changed.emit()
func tokens() -> Array[StringName]: return _tokens.duplicate()
func has_token(id: StringName) -> bool: return id in _tokens
func searched(key: StringName) -> bool: return _searched.has(key)
func search(key: StringName, faction: StringName, identity: Dictionary) -> bool:
	if _ended or faction not in IDS or _searched.has(key): return false
	_searched[key] = true
	_identities[key] = identity.duplicate(true)
	if faction not in _tokens: _tokens.append(faction)
	changed.emit()
	return true
func identities() -> Dictionary: return _identities.duplicate(true)
func used(ability: StringName) -> int: return int(_spent.get(ability, 0))
func spend(ability: StringName, limit: int) -> bool:
	if _ended or limit < 1 or used(ability) >= limit: return false
	_spent[ability] = used(ability) + 1
	changed.emit()
	return true
func consumption_ledger() -> Dictionary: return _spent.duplicate(true)
func equip_without_signal(id: StringName) -> bool:
	# Runtime service validates safety and commits effects before the sole signal.
	if _ended or (id != &"NONE" and not has_token(id)): return false
	_active = id
	return true
func end() -> void:
	_tokens.clear(); _spent.clear(); _identities.clear(); _searched.clear()
	_active = &"NONE"; _initial = &"NONE"; _ended = true
	guard_ready = false; catalog_note = ""
	changed.emit()
