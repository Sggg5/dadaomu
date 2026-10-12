class_name ProfessionRuntime
extends Node
## Sole faction effect owner. Uses weapon notifications without installing a RelicEffect.
const OVERLOAD_KEY: int = -130001
const ATTACK_KEY: StringName = &"profession_attack_id"
const EMPOWERED: StringName = &"profession_empowered"
var state: ProfessionRunState
var world: Node2D
var can_session_act: Callable
var busy: bool = false
var notice: String = ""
var current_key: StringName
var first_visit: bool = false
var last_attack_damage: float = 0
var last_damage_received: float = 0
var last_damage_input: float = 0
var last_damage_factor: float = 1
var damage_events: Array = []
var paying_cost: bool = false
func _ready() -> void:
	state.changed.connect(refresh)
	world.player.antiques.changed.connect(refresh_overload)
	world.player.profession_runtime = self
	world.room_changed.connect(room_entered)
	world.player.health.damaged.connect(actual_damage)
	world.player.relics.attack_prepared.connect(prepare_attack)
	world.player.relics.projectile_spawned.connect(projectile_spawned)
	refresh()
func available() -> bool:
	if busy or not is_instance_valid(world.current_room) or world.run_finished or world.transitioning or world._restarting: return false
	if world.player.health.is_dead or not world.player.controls_enabled: return false
	if can_session_act.is_valid() and not can_session_act.call(): return false
	var room: Room = world.current_room
	if room.room_state.status != RoomState.Status.CLEARED or room.remaining_count() != 0: return false
	if is_instance_valid(room.risk_content) and (room.risk_content.confirming or room.risk_content.resolving): return false
	for hazard in room.hazards.get_children():
		if hazard is EncounterHazard and hazard.phase != EncounterHazard.Phase.OFF and hazard.contains_point(world.player.position,20): return false
	return true
func refresh() -> void:
	if not busy: apply_effects()
func apply_effects() -> void:
	if not is_instance_valid(world.player): return
	var data := ProfessionRegistry.definition(state.active_id)
	world.player.profession_wall_multiplier = 1.0
	world.player.profession_movement_multiplier = float(data.get("movement_multiplier",1.0))
	world.player.antiques.capacity = 8 + int(data.get("extra_slots",0))
	refresh_overload()
	world.player.antiques.changed.emit()
func refresh_overload() -> void:
	var used: int = world.player.antiques.used_slots()
	var capacity: int = world.player.antiques.capacity
	var xieling := ProfessionRegistry.definition(&"XIELING")
	if used > capacity: world.player.encounter_movement_modifiers[OVERLOAD_KEY] = float(xieling.overload_multiplier)
	elif state.active_id == &"XIELING" and used > 8: world.player.encounter_movement_modifiers[OVERLOAD_KEY] = float(xieling.loaded_multiplier)
	else: world.player.encounter_movement_modifiers.erase(OVERLOAD_KEY)
func equip(id: StringName) -> bool:
	if not available() or not ProfessionRunState.valid_id(id) or (id != &"NONE" and not state.has_token(id)): return false
	busy = true
	if not state.equip_without_signal(id): busy = false; return false
	apply_effects()
	state.changed.emit() # Everything is committed before observers see the new class.
	busy = false
	notice = "已装备 " + ProfessionRegistry.display_name(id)
	return true
func room_entered(_id: StringName) -> void:
	current_key = StringName("F%d:%s" % [world.floor_number,world.current_id])
	first_visit = state.visit_room(current_key)
func is_combat_room() -> bool:
	return is_instance_valid(world.current_room) and (world.current_room.room_type==RoomDefinition.Type.BOSS or (world.current_room.room_type==RoomDefinition.Type.COMBAT and (not world.current_room.definition.spawns.is_empty() or world.current_room.remaining_count()>0)))
func received_damage(amount: float) -> float:
	# Called after relic mitigation and before Health; zero/invalid/invulnerable hits do not spend anything.
	last_damage_input = amount
	last_damage_factor = 1.0
	if amount > 0 and is_finite(amount) and state.active_id == &"FAQIU" and is_combat_room() and first_visit and not state.damaged_rooms.has(current_key):
		last_damage_factor = float(ProfessionRegistry.definition(&"FAQIU").first_damage_multiplier)
		return amount * last_damage_factor
	return amount
func environment_damage(amount: float) -> float:
	# Legacy risk-event adapter. Banshan no longer has trap immunity.
	return received_damage(amount)
func actual_damage(amount: float) -> void:
	if amount <= 0 or world.run_finished or paying_cost: return
	last_damage_received = amount
	damage_events.append({"input":last_damage_input,"factor":last_damage_factor,"actual":amount,"room":str(current_key)})
	if damage_events.size()>8: damage_events.pop_front()
	if is_combat_room():
		var first_hit := not state.damaged_rooms.has(current_key)
		state.damaged_rooms[current_key] = true
		if state.active_id == &"FAQIU" and first_visit and first_hit and last_damage_factor < 1.0:
			notice = "发丘首伤已结算 · 实际承伤 %.1f" % amount
			state.spend(StringName("FAQIU:SHIELD:"+str(current_key)),1)
func clue_key() -> StringName: return StringName("MOJIN:CLUE:F%d" % world.floor_number)
func find_clue() -> Dictionary:
	var plan: TombExplorationPlan = world.exploration
	if plan != null and plan.secret_id != &"" and not plan.secret_discovered:
		return {"kind":"PASSAGE","room_id":str(plan.secret_parent),"side":plan.secret_side,"target":str(plan.secret_id),"text":"暗道线索：%s 的%s墙面值得调查" % [plan.secret_parent,["北","东","南","西"][plan.secret_side]]}
	for id in [world.layout.antique_id,world.layout.relic_id]:
		if id != &"" and id != world.current_id and world.states[id].status == RoomState.Status.UNVISITED:
			return {"kind":"SPECIAL","room_id":str(id),"target":str(id),"text":"特殊房线索：%s，坐标%s，尚未访问" % [id,world.layout.rooms[id].coordinate]}
	return {}
func use_ability() -> bool:
	if not available(): notice = "仅在清房、安全且未切场时可用"; return false
	if state.active_id != &"MOJIN": notice = "本派能力为自动触发，请查看信物簿说明"; return false
	if state.used(clue_key()) > 0: notice = "本层线索已使用，切派不会恢复"; return false
	var clue := find_clue()
	if clue.is_empty(): notice = "没有有效未发现线索，不消耗次数"; return false
	busy = true
	if not state.spend(clue_key(),1): busy = false; return false
	state.clues[world.floor_number] = clue.duplicate(true)
	busy = false
	notice = str(clue.text)
	return true
func bind_projectile(projectile: Projectile, request: AttackRequest) -> void:
	var id: int = int(request.get_meta(ATTACK_KEY,0))
	if id<=0:return
	projectile.set_meta(ATTACK_KEY,id)
	projectile.set_meta(EMPOWERED,request.get_meta(EMPOWERED,false))
	projectile.hit.connect(weapon_hit.bind(id))
func prepare_attack(context: AttackContext) -> void:
	if state.active_id != &"BANSHAN" or context.requests.is_empty() or world.run_finished: return
	var id := state.new_attack()
	var data := ProfessionRegistry.definition(&"BANSHAN")
	for request in context.requests:
		request.set_meta(ATTACK_KEY,id)
		if state.banshan_ready:
			request.damage *= float(data.empower_multiplier)
			request.set_meta(EMPOWERED,true)
	last_attack_damage = context.requests[0].damage
func projectile_spawned(projectile: Projectile) -> void:
	# Budget-rejected attacks cannot consume the prepared enhancement.
	if state.active_id == &"BANSHAN" and state.banshan_ready and bool(projectile.get_meta(EMPOWERED,false)):
		state.record_empower()
		notice = "搬山强化攻击已发射 · 伤害+25%"
func weapon_hit(context: ProjectileHitContext, id: int = 0) -> void:
	if state.active_id != &"BANSHAN" or context.damage <= 0 or not is_instance_valid(context.target) or not context.target is Enemy: return
	if not state.credit_hit(id): return
	if not state.banshan_ready:
		state.banshan_hits += 1
		if state.banshan_hits >= int(ProfessionRegistry.definition(&"BANSHAN").hits_required):
			state.banshan_ready = true
			notice = "搬山四次有效命中 · 下一次攻击已强化"
func _exit_tree() -> void:
	if state != null and state.changed.is_connected(refresh): state.changed.disconnect(refresh)
	if is_instance_valid(world.player):
		world.player.encounter_movement_modifiers.erase(OVERLOAD_KEY)
		world.player.profession_movement_multiplier = 1.0
