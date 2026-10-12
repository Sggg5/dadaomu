class_name ProfessionRuntime
extends Node
## Sole effect owner. Synchronous, guarded commit; effects never enter RelicInventory.
const OVERLOAD_KEY: int = -130001
var state: ProfessionRunState
var world: Node2D
var can_session_act: Callable
var busy: bool = false
var guard_ready: bool:
	get: return state.guard_ready
	set(value): state.guard_ready = value
var catalog_note: String:
	get: return state.catalog_note
	set(value): state.catalog_note = value
var notice: String = ""
func _ready() -> void:
	state.changed.connect(refresh)
	world.player.antiques.changed.connect(refresh_overload)
	world.player.profession_runtime = self
	refresh()
func available() -> bool:
	if busy or not is_instance_valid(world.current_room) or world.run_finished or world.transitioning or world._restarting: return false
	if world.player.health.is_dead or not world.player.controls_enabled: return false
	if can_session_act.is_valid() and not can_session_act.call(): return false
	var room: Room = world.current_room
	if room.room_state.status != RoomState.Status.CLEARED or room.remaining_count() != 0: return false
	if is_instance_valid(room.risk_content) and (room.risk_content.confirming or room.risk_content.resolving): return false
	for hazard in room.hazards.get_children():
		if hazard is EncounterHazard and hazard.phase != EncounterHazard.Phase.OFF and hazard.contains_point(world.player.position, 20): return false
	return true
func refresh() -> void:
	if busy: return
	apply_effects()
func apply_effects() -> void:
	if not is_instance_valid(world.player): return
	var data := ProfessionRegistry.definition(state.active_id)
	world.player.profession_wall_multiplier = float(data.get("wall_multiplier", 1.0))
	world.player.antiques.capacity = 8 + int(data.get("extra_slots", 0))
	refresh_overload()
	world.player.antiques.changed.emit()
func refresh_overload() -> void:
	if world.player.antiques.used_slots() > world.player.antiques.capacity:
		world.player.encounter_movement_modifiers[OVERLOAD_KEY] = .8
	else: world.player.encounter_movement_modifiers.erase(OVERLOAD_KEY)
func equip(id: StringName) -> bool:
	if not available() or not ProfessionRunState.valid_id(id) or (id != &"NONE" and not state.has_token(id)): return false
	busy = true
	if not state.equip_without_signal(id): busy = false; return false
	apply_effects() # Complete all properties before publishing the sole notification.
	state.changed.emit()
	busy = false
	notice = "已装备 " + ProfessionRegistry.display_name(id)
	return true
func use_ability() -> bool:
	if not available(): notice = "仅在清房、安全且未切场时可用"; return false
	var data := ProfessionRegistry.definition(state.active_id)
	var ability: StringName = StringName(data.get("ability", ""))
	if ability == &"" or state.used(ability) >= int(data.uses): notice = "本局能力次数不足"; return false
	var mark: WallMark
	if state.active_id == &"MOJIN":
		for child in world.current_room.get_children():
			if child is WallMark and not child.plan.checked_wall_marks.has(child.definition.id):
				if mark == null or child.position.distance_to(world.player.position) < mark.position.distance_to(world.player.position): mark = child
		if mark == null: notice = "本房没有未检查墙纹，不消耗次数"; return false
	if state.active_id == &"FAQIU" and world.player.antiques.items().is_empty(): notice = "背包为空，不消耗次数"; return false
	busy = true
	if not state.spend(ability, int(data.uses)): busy = false; return false
	match state.active_id:
		&"MOJIN":
			mark.plan.inspect_wall_mark(mark.definition)
			notice = "观气完成：" + mark.prompt_text()
		&"FAQIU":
			var lines: Array[String] = []
			for item in world.player.antiques.items(): lines.append("%s · %d格 · %s" % [item.display_name,item.slots,AntiqueDefinition.money(item.base_value)])
			catalog_note = "\n".join(lines)
			notice = "本局货目已抄录；不改变鉴定或价格"
		&"BANSHAN": guard_ready = true; notice = "护符已备好：一次机关抵免，切走不生效"
	busy = false
	return true
func environment_damage(amount: float) -> float:
	if amount > 0 and state.active_id == &"BANSHAN" and guard_ready:
		guard_ready = false
		notice = "搬山护符抵免机关；本局次数不会因切换恢复"
		return 0
	return amount
func _exit_tree() -> void:
	if state != null and state.changed.is_connected(refresh): state.changed.disconnect(refresh)
	if is_instance_valid(world.player):
		world.player.encounter_movement_modifiers.erase(OVERLOAD_KEY)
