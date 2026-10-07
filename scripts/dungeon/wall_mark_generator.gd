class_name WallMarkGenerator
extends RefCounted
## 独立环境流，在探索图装配之后运行；不修改拓扑、事件或既有RNG。
const VERSION: int = 1
const FAKE_MARK_CHANCE: float = 0.55
const SECOND_FAKE_CHANCE: float = 0.15
const PARENT_FAKE_CHANCE: float = 0.35
const FAKE_RESULTS: Array[String] = ["墙砖开裂，但后面似乎是实心的。", "只是年代久远造成的破损。", "石灰脱落，没有发现异常。"]

static func decorate(plan: TombExplorationPlan, run_seed: int, floor_number: int) -> void:
	for id in plan.layout.ordered_ids():
		var room := plan.layout.rooms[id]
		if room.room_type != RoomDefinition.Type.COMBAT: continue
		var rng := RandomNumberGenerator.new()
		rng.seed = AntiquePool.stable_score(run_seed, floor_number, id, &"wall_mark", VERSION)
		var marks: Array[WallMarkDefinition] = []
		var parent := id == plan.secret_parent and plan.secret_id != &""
		if parent:
			var true_positions := wall_candidates(room, plan.secret_side)
			assert(not true_positions.is_empty(), "Secret wall requires an accessible inspect position")
			var point: Vector2 = true_positions[rng.randi_range(0, true_positions.size() - 1)]
			marks.append(_definition(id, plan.secret_side, 0, point, true, rng))
		var fake_count := 0
		if parent:
			fake_count = int(rng.randf() < PARENT_FAKE_CHANCE)
		elif rng.randf() < FAKE_MARK_CHANCE:
			fake_count = 1 + int(rng.randf() < SECOND_FAKE_CHANCE)
		var candidates: Array[Dictionary] = []
		for side in range(4):
			for point: Vector2 in wall_candidates(room, side):
				if parent and point.distance_to(marks[0].position) < 120: continue
				candidates.append({"side": side, "position": point})
		for index in range(fake_count):
			if candidates.is_empty(): break
			var selected := rng.randi_range(0, candidates.size() - 1)
			var candidate: Dictionary = candidates[selected]
			marks.append(_definition(id, candidate.side, index + 1, candidate.position, false, rng))
			var point: Vector2 = candidate.position
			candidates = candidates.filter(func(other: Dictionary) -> bool: return point.distance_to(other.position) >= 120)
		if not marks.is_empty(): plan.wall_marks[id] = marks

static func wall_candidates(room: DungeonRoom, side: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var horizontal := side % 2 == 0
	# 预留现有中心/北侧/侧翼底座区域，避免拾取物抢先消费同一次E。
	var reserved: Array[Vector2] = [Vector2(640, 208), Vector2(384, 368), Vector2(896, 368), Vector2(640, 368), Vector2(640, 256), Vector2(800, 368), Vector2(640, 480), Vector2(480, 368)]
	for along in ([224, 416, 640, 864, 1056] if horizontal else [224, 368, 512]):
		var point := anchor(side)
		if horizontal: point.x = along
		else: point.y = along
		if room.neighbors.has(side) and point.distance_to(wall_center(side)) < Door.WIDTH / 2 + 64: continue
		if reserved.any(func(other: Vector2) -> bool: return other.distance_to(point) < 96): continue
		if accessible(room.definition, point, side): result.append(point)
	return result

static func _definition(room_id: StringName, side: int, index: int, point: Vector2, secret: bool, rng: RandomNumberGenerator) -> WallMarkDefinition:
	var mark := WallMarkDefinition.new()
	mark.id = StringName("%s:wall:%d:%d" % [room_id, side, index])
	mark.side = side
	mark.position = point
	# 真/假从完全相同的视觉池抽样，初始没有秘密专属图形或颜色。
	mark.variant = rng.randi_range(0, 2)
	mark.is_secret = secret
	mark.inspect_result = "敲击声有些发空。" if secret else FAKE_RESULTS[rng.randi_range(0, FAKE_RESULTS.size() - 1)]
	return mark

static func wall_center(side: int) -> Vector2:
	var center := Room.ROOM_RECT.get_center()
	return [Vector2(center.x, Room.ROOM_RECT.position.y), Vector2(Room.ROOM_RECT.end.x, center.y), Vector2(center.x, Room.ROOM_RECT.end.y), Vector2(Room.ROOM_RECT.position.x, center.y)][side]

static func outward(side: int) -> Vector2: return Vector2.UP.rotated(side * PI / 2)

static func anchor(side: int) -> Vector2: return wall_center(side) - outward(side) * 20

static func accessible(template: RoomDefinition, point: Vector2, side: int) -> bool:
	# 交互锚点在墙内20px；站位再向内20px，玩家圆形碰撞留足余量。
	var standing := point - outward(side) * 20
	return Room.ROOM_RECT.grow(-16).has_point(standing) and template.obstacles.all(func(rect: Rect2) -> bool: return not rect.grow(18).has_point(standing) and not rect.grow(18).has_point(point))

static func signature(plan: TombExplorationPlan) -> String:
	var rows: Array = []
	for id in plan.layout.ordered_ids():
		for mark: WallMarkDefinition in plan.wall_marks.get(id, []):
			rows.append([str(mark.id), mark.side, mark.position.x, mark.position.y, mark.variant, mark.is_secret, mark.inspect_result])
	return JSON.stringify(rows)
