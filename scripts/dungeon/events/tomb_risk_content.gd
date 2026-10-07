class_name TombRiskContent
extends Node2D
## Room局部事件呈现/敌人波次；事件账本属于Controller，不随过房销毁。
var room: Room
var room_id: StringName
var service: TombRiskService
var events: Array = []
var confirming: bool = false
var ambush: EnemySpawner
var active_event: TombRiskEvent
var message: Label

func source(event: TombRiskEvent) -> StringName: return service.key(room_id, event.id)

func available() -> bool:
	return not room.combat_target.health.is_dead and room.can_exit.call() and room.room_state.status == RoomState.Status.CLEARED and remaining() == 0

func _ready() -> void:
	message = Label.new()
	message.position = Vector2(260, 150)
	message.size = Vector2(760, 40)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(message)
	for index in range(events.size()):
		var event: TombRiskEvent = events[index]
		var interactable := TombRiskInteractable.new()
		interactable.content = self
		interactable.event = event
		interactable.position = safe_position(index)
		add_child(interactable)
		if service.results.has(source(event)):
			var result := service.results[source(event)]
			if result.outcome == TombRiskResult.Outcome.AMBUSH and not result.wave_completed:
				_start_ambush(event)
			else: _reward(event, interactable.position)

func safe_position(index: int) -> Vector2:
	var candidates: Array[Vector2] = [Vector2(300, 250), Vector2(960, 480)]
	for y in range(224, 530, 96):
		for x in range(200, 1100, 160): candidates.append(Vector2(x, y))
	var accepted: Array[Vector2] = []
	for point in candidates:
		if room.definition.obstacles.any(func(rect: Rect2) -> bool: return rect.grow(48).has_point(point)): continue
		if not Room.ROOM_RECT.grow(-40).has_point(point + Vector2(100, 0)): continue
		if room.definition.obstacles.any(func(rect: Rect2) -> bool: return rect.grow(32).has_point(point + Vector2(100, 0))): continue
		if point.distance_to(RelicPedestal.safe_position(room)) < 150 or point.distance_to(AntiqueCache.safe_position(room)) < 130: continue
		if accepted.any(func(other: Vector2) -> bool: return other.distance_to(point) < 200): continue
		accepted.append(point)
		if accepted.size() > index: return point
	assert(false, "Risk interactable requires accessible placement")
	return Vector2(300, 250)

func resolve(event: TombRiskEvent, point: Vector2) -> bool:
	if not available(): return false
	var result := service.resolve(room_id, event)
	if result == null: return false
	# 祭台为支付生命的主动代价，走Health正式伤害信号，不能用短暂无敌免单。
	if event.kind == TombRiskEvent.Kind.ALTAR or result.outcome == TombRiskResult.Outcome.TRAP:
		var before := room.combat_target.health.current_hp
		room.combat_target.health.take_damage(event.hp_cost)
		result.damage_taken = before - room.combat_target.health.current_hp
		room.combat_target.invulnerability_remaining = room.combat_target.stats.hurt_invulnerability
		room.combat_target.queue_redraw()
		message.text = ("祭台代价" if event.kind == TombRiskEvent.Kind.ALTAR else "机关触发") + " · -%d生命" % result.damage_taken
	match result.outcome:
		TombRiskResult.Outcome.AMBUSH: _start_ambush(event)
		TombRiskResult.Outcome.EMPTY: message.text = "空棺 · 什么也没有"
	_reward(event, point)
	return true

func _reward(event: TombRiskEvent, point: Vector2) -> void:
	var result := service.results[source(event)]
	if result.antique_ids.is_empty() or (result.outcome == TombRiskResult.Outcome.AMBUSH and not result.wave_completed): return
	var loot_source := StringName("risk:%s" % event.id)
	var node_name := "RiskLoot_%s" % event.id
	if room.room_state.is_loot_claimed(loot_source) or has_node(node_name): return
	var pickup := AntiquePedestal.new()
	pickup.name = node_name
	pickup.definition = TombRiskService.POOL.find_by_id(result.antique_ids[0])
	pickup.player = room.combat_target
	pickup.room_state = room.room_state
	pickup.source_id = loot_source
	pickup.caption = "探墓所得 · 未撤离仍可能遗失"
	pickup.position = point + Vector2(100, 0)
	add_child(pickup)

func _start_ambush(event: TombRiskEvent) -> void:
	active_event = event
	ambush = EnemySpawner.new()
	ambush.target = room.combat_target
	ambush.difficulty = room.difficulty
	ambush.projectile_parent = room.projectiles
	ambush.enemy_killed.connect(room.combat_target.relics.notify_enemy_killed)
	ambush.remaining_changed.connect(func(_count: int) -> void: room.enemy_count_changed.emit(room.remaining_count()))
	ambush.all_defeated.connect(_wave_done)
	add_child(ambush)
	var wave := event.wave.duplicate() as RoomDefinition
	wave.spawns = []
	var used: Array[Vector2] = []
	for original in event.wave.spawns:
		var spawn := original.duplicate() as EnemySpawnDefinition
		var found := false
		for y in range(232, 520, 80):
			for x in range(240, 1080, 100):
				var point := Vector2(x, y)
				if point.distance_to(room.combat_target.position) < 180: continue
				if room.definition.obstacles.any(func(rect: Rect2) -> bool: return rect.grow(28).has_point(point)): continue
				if used.any(func(other: Vector2) -> bool: return other.distance_to(point) < 80): continue
				var near_door := false
				for side in range(4):
					if point.distance_to(room.get_entry_position(side) + Vector2.UP.rotated(side * PI / 2) * 64) < 180: near_door = true
				if near_door: continue
				spawn.position = point
				found = true
				break
			if found: break
		assert(found, "Ambush requires safe spawn")
		used.append(spawn.position)
		wave.spawns.append(spawn)
	room._set_doors_open(false)
	ambush.spawn(wave)
	message.text = "惊动尸蟞！清除伏击后墓门重开"

func _wave_done() -> void:
	service.results[source(active_event)].wave_completed = true
	room._set_doors_open(true)
	_reward(active_event, safe_position(events.find(active_event)))
	message.text = "伏击已清除 · 墓门重开"

func remaining() -> int: return ambush.get_remaining() if is_instance_valid(ambush) else 0

func targets() -> Array[Node2D]:
	var result: Array[Node2D] = []
	if is_instance_valid(ambush): result.assign(ambush.get_children())
	return result

func stop() -> void:
	if is_instance_valid(ambush): ambush.stop_all()
	for child in get_children():
		if child is TombRiskInteractable and child.confirming: child.close()
