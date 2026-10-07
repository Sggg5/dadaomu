class_name TombExplorationPlan
extends RefCounted
## 生成器之后的可选装配层；复制拓扑节点，保留主图/普通奖励原始输入。
const COFFIN: TombRiskEvent = preload("res://data/dungeon/events/stone_coffin.tres")
const ALTAR: TombRiskEvent = preload("res://data/dungeon/events/risk_altar.tres")
const HIDDEN_REWARD: TombRiskEvent = preload("res://data/dungeon/events/hidden_reward.tres")
const QUIET: RoomDefinition = preload("res://data/dungeon/events/quiet_chamber.tres")
const CONFIG: TombExplorationConfig = preload("res://data/dungeon/events/exploration_config.tres")
const VERSION: int = 1
var layout: DungeonLayout
var events: Dictionary[StringName, Array] = {}
var secret_id: StringName = &""
var secret_parent: StringName = &""
var secret_side: int = -1
var secret_discovered: bool = false
var fork: Array[StringName] = []

static func build(base: DungeonLayout, run_seed: int, floor_number: int) -> TombExplorationPlan:
	var plan := TombExplorationPlan.new()
	plan.layout = DungeonLayout.new()
	plan.layout.seed_value = base.seed_value
	plan.layout.start_id = base.start_id
	plan.layout.boss_id = base.boss_id
	plan.layout.antique_id = base.antique_id
	for id in base.ordered_ids():
		var old := base.rooms[id]
		var node := DungeonRoom.new()
		node.room_id = old.room_id
		node.coordinate = old.coordinate
		node.room_type = old.room_type
		node.distance_from_start = old.distance_from_start
		node.definition = old.definition
		node.neighbors = old.neighbors.duplicate()
		plan.layout.add_room(node)
	var candidates: Array[StringName] = []
	for id in base.ordered_ids():
		if base.rooms[id].room_type == RoomDefinition.Type.COMBAT: candidates.append(id)
	candidates.sort_custom(func(a: StringName, b: StringName) -> bool:
		var first := AntiquePool.stable_score(run_seed, floor_number, a, &"exploration", 1)
		var second := AntiquePool.stable_score(run_seed, floor_number, b, &"exploration", 1)
		return first < second or (first == second and str(a) < str(b)))
	for index in range(mini(2, candidates.size())):
		plan.events[candidates[index]] = [COFFIN]
	var rng := RandomNumberGenerator.new()
	rng.seed = AntiquePool.stable_score(run_seed, floor_number, &"FLOOR", &"exploration", 1)
	# 在既有COMBAT连边旁加长度3的平行绕路，原安全边保留，绝不缩短Boss距离。
	if rng.randf() < CONFIG.fork_chance: plan._attach_fork(candidates)
	if rng.randf() < CONFIG.secret_chance: plan._attach_secret(candidates)
	if not plan.fork.is_empty():
		plan.events[plan.fork[2]] = [ALTAR]
		if plan.secret_id != &"":
			plan.events.erase(candidates[0])
			plan.events[plan.secret_id] = [HIDDEN_REWARD, COFFIN]
	elif plan.secret_id != &"": plan.events[plan.secret_id] = [HIDDEN_REWARD, ALTAR]
	elif rng.randf() < CONFIG.standalone_altar_chance and candidates.size() > 2: plan.events[candidates[2]] = [ALTAR]
	return plan

func _add(id: StringName, coordinate: Vector2i, type: RoomDefinition.Type, depth: int) -> void:
	var node := DungeonRoom.new()
	node.room_id = id
	node.coordinate = coordinate
	node.room_type = type
	node.distance_from_start = depth
	node.definition = QUIET
	layout.add_room(node)

func _attach_fork(candidates: Array[StringName]) -> void:
	for id in candidates:
		var first := layout.rooms[id]
		for direction in range(4):
			if not first.neighbors.has(direction): continue
			var second := layout.rooms[first.neighbors[direction]]
			if second.room_type != RoomDefinition.Type.COMBAT: continue
			for perpendicular in [(direction + 1) % 4, (direction + 3) % 4]:
				var a := first.coordinate + DungeonRoom.OFFSETS[perpendicular]
				var b := second.coordinate + DungeonRoom.OFFSETS[perpendicular]
				if layout.coordinates.has(a) or layout.coordinates.has(b): continue
				_add(&"RISK_PATH", a, RoomDefinition.Type.TRAP, mini(first.distance_from_start + 1, second.distance_from_start + 2))
				_add(&"RISK_REWARD", b, RoomDefinition.Type.TRAP, mini(first.distance_from_start + 2, second.distance_from_start + 1))
				layout.connect_rooms(id, perpendicular, &"RISK_PATH")
				layout.connect_rooms(&"RISK_PATH", direction, &"RISK_REWARD")
				layout.connect_rooms(&"RISK_REWARD", (perpendicular + 2) % 4, second.room_id)
				fork = [id, &"RISK_PATH", &"RISK_REWARD", second.room_id]
				events[&"RISK_PATH"] = [COFFIN]
				# 总棺椁保持每层2个，避免新增路线提高按钮密度。
				if candidates.size() > 1: events.erase(candidates[1])
				return

func _attach_secret(candidates: Array[StringName]) -> void:
	for id in candidates:
		for side in range(4):
			var coordinate := layout.rooms[id].coordinate + DungeonRoom.OFFSETS[side]
			if layout.coordinates.has(coordinate): continue
			secret_id = &"SECRET_CHAMBER"
			secret_parent = id
			secret_side = side
			_add(secret_id, coordinate, RoomDefinition.Type.SECRET, layout.rooms[id].distance_from_start + 1)
			# 暗道由交互请求访问，不加入普通Door邻接；主路径完全不依赖暗道。
			events[secret_id] = [HIDDEN_REWARD]
			return
