extends RefCounted
## 真假线索、可达墙段、检查/重访/新Run、独立随机流；不充当人工感受。
var test: SceneTree
var reachability: Dictionary = {}
func _init(context: SceneTree) -> void: test = context

func run() -> void:
	var fake_only_floors := 0
	var overlap_counts := {"fake_one": 0, "fake_two": 0, "parent_one": 0, "parent_two": 0}
	var true_variants := {}
	var fake_variants := {}
	for seed_value in range(100):
		var base := DungeonGenerator.generate(seed_value, DungeonSession.DEFAULT_CONFIG)
		var plan := TombExplorationPlan.build(base, seed_value, 1)
		var again := TombExplorationPlan.build(base, seed_value, 1)
		test.check(WallMarkGenerator.signature(plan) == WallMarkGenerator.signature(again), "All wall IDs/counts/positions/variants/truth deterministic seed%d" % seed_value)
		var ids := {}
		var has_fake := false
		for room_id in plan.wall_marks:
			var room := plan.layout.rooms[room_id]
			var marks: Array = plan.wall_marks[room_id]
			var real_count := 0
			test.check(room.room_type == RoomDefinition.Type.COMBAT and marks.size() <= 2, "Only ordinary Combat has restrained wall clues seed%d room%s" % [seed_value, room_id])
			for mark: WallMarkDefinition in marks:
				test.check(not ids.has(mark.id) and mark.variant in [0, 1, 2], "Stable unique wall ID and shared visual variant")
				ids[mark.id] = true
				real_count += int(mark.is_secret)
				if mark.is_secret: true_variants[mark.variant] = true
				else: fake_variants[mark.variant] = true; has_fake = true
				test.check(WallMarkGenerator.accessible(room.definition, mark.position, mark.side) and reachable(room.definition, mark.position - WallMarkGenerator.outward(mark.side) * 20), "Every generated wall has connected walkable Player standing point")
				if room.neighbors.has(mark.side):
					test.check(mark.position.distance_to(WallMarkGenerator.wall_center(mark.side)) >= Door.WIDTH / 2 + 64, "Wall clue stays away from normal and risk-route Door")
			if room_id == plan.secret_parent:
				test.check(real_count == 1, "Secret parent has exactly one true clue plus at most one fake")
				overlap_counts["parent_one" if marks.size() == 1 else "parent_two"] += 1
			else:
				test.check(real_count == 0, "Other rooms only contain ordinary false clues")
				overlap_counts["fake_one" if marks.size() == 1 else "fake_two"] += 1
		if plan.secret_id == &"" and has_fake: fake_only_floors += 1
	test.check(fake_only_floors > 0, "Floors without any secret room still contain inspectable false wall marks")
	test.check(overlap_counts.values().all(func(value: int) -> bool: return value > 0) and true_variants.size() == 3 and fake_variants.size() == 3, "True/false wall-count distributions overlap and both use all three variants")
	print("[Wall distribution] sample100 fake_only_floors=%d counts=%s" % [fake_only_floors, overlap_counts])
	await interactions()
	await rng_isolation()

func reachable(template: RoomDefinition, point: Vector2) -> bool:
	# 缓存各模板的16px可走网格连通分量，圆形Player使用18px障碍余量。
	var key := template.resource_path
	if not reachability.has(key):
		var allowed := {}
		for y in range(176, 577, 16):
			for x in range(96, 1201, 16):
				var position := Vector2(x, y)
				if template.obstacles.all(func(rect: Rect2) -> bool: return not rect.grow(18).has_point(position)): allowed[Vector2i(x, y)] = true
		var origin := Vector2i(640, 368)
		if not allowed.has(origin): origin = allowed.keys()[0]
		var visited := {origin: true}
		var queue: Array[Vector2i] = [origin]
		while not queue.is_empty():
			var current: Vector2i = queue.pop_front()
			for direction in DungeonRoom.OFFSETS:
				var next := current + direction * 16
				if allowed.has(next) and not visited.has(next): visited[next] = true; queue.append(next)
		reachability[key] = visited
	for cell: Vector2i in reachability[key]:
		if Vector2(cell).distance_to(point) <= 14: return true
	return false

func find_mark(world: RoomController, id: StringName) -> WallMark:
	for child in world.current_room.get_children():
		if child is WallMark and child.definition.id == id: return child
	return null

func stand(mark: WallMark) -> void:
	mark.player.position = mark.position - WallMarkGenerator.outward(mark.definition.side) * 20
	mark.player.velocity = Vector2.ZERO
	await test.frames(1)

func enter_fixture(world: RoomController, id: StringName) -> void:
	world._switch_room(id, -1)
	for enemy in world.current_room.enemy_spawner.get_children(): enemy.take_damage(10000) # 交互单项夹具。
	await test.frames(3)

func interactions() -> void:
	var session := preload("res://scenes/main/dungeon_test.tscn").instantiate() as DungeonSession
	session.progressive_relics = false
	session.tomb = preload("res://tests/fixtures/legacy_two_floor_tomb.tres")
	session.seed_value = 52
	test.session = session
	test.root.add_child(session)
	await test.frames(3)
	var world := session.world
	var plan := world.exploration
	var fake_room: StringName
	var fake_id: StringName
	var true_id: StringName
	for id in plan.wall_marks:
		for mark: WallMarkDefinition in plan.wall_marks[id]:
			if mark.is_secret: true_id = mark.id
			elif fake_id == &"": fake_room = id; fake_id = mark.id
	assert(fake_id != &"" and true_id != &"")
	await enter_fixture(world, fake_room)
	var fake := find_mark(world, fake_id)
	await stand(fake)
	var initial := fake.prompt_text()
	test.check(initial == "[E] 检查墙面" and not initial.contains("暗门") and not initial.contains("隐藏"), "Uninspected fake has neutral initial hint")
	var layout_before := world.layout.signature()
	test.key(KEY_E)
	await test.frames(1)
	test.check(plan.checked_wall_marks.has(fake_id) and not plan.secret_inspected and not plan.secret_discovered and not fake.prompt_text().contains("[E]"), "First fake E records fixed result and never reveals a secret")
	var result_text := fake.prompt_text()
	test.key(KEY_E)
	test.key(KEY_E)
	test.check(fake.prompt_text() == result_text and plan.checked_wall_marks.size() == 1 and world.layout.signature() == layout_before, "Repeated fake E neither rerolls result nor changes map")
	test.capture("fake_wall_result")
	world._switch_room(world.layout.start_id, -1)
	await enter_fixture(world, fake_room)
	fake = find_mark(world, fake_id)
	test.check(fake.prompt_text() == result_text and not fake.prompt_text().contains("[E]"), "Revisited false clue remains checked with no repeat-E chore")
	await enter_fixture(world, plan.secret_parent)
	var real := find_mark(world, true_id)
	await stand(real)
	test.check(world.hud.get_node("Root/Seed").text.contains(str(session.run_seed)), "Hidden minimap filtering preserves actual Seed for multi-Seed playtesting")
	test.check(real.prompt_text() == initial, "True and fake initial text/interaction wording identical")
	test.capture("neutral_true_wall")
	test.key(KEY_E)
	await test.frames(1)
	test.check(plan.secret_inspected and not plan.secret_discovered and real.prompt_text().contains("敲击声有些发空") and not world.hud.minimap._layout.rooms.has(plan.secret_id), "True first E gives hollow-sound feedback, leaves map secret hidden")
	test.capture("hollow_wall")
	world._switch_room(world.layout.start_id, -1)
	await enter_fixture(world, plan.secret_parent)
	real = find_mark(world, true_id)
	test.check(real.prompt_text().contains("继续检查") and plan.secret_inspected and not plan.secret_discovered, "Unopened true wall retains first inspection over room unload/revisit")
	await stand(real)
	test.key(KEY_E)
	await test.frames(5)
	test.check(plan.secret_discovered and world.current_id == plan.secret_id and world.hud.minimap._layout.rooms.has(plan.secret_id), "Second actual E opens and enters true chamber, only then updates minimap")
	test.key(KEY_R)
	await test.frames(5)
	test.check(not session.world.exploration.secret_inspected and not session.world.exploration.secret_discovered and session.world.exploration.checked_wall_marks.is_empty(), "New Run resets all true/false inspection state")
	var carry := RunCarryState.capture(session.world.player)
	session._enter_next_floor(session.next_floor_layout(), carry) # 层装配单项；真实过层另有完整集成。
	await test.frames(3)
	test.check(session.world.exploration.checked_wall_marks.is_empty() and not session.world.exploration.secret_inspected, "New floor starts with fresh wall-state ledger")
	session.queue_free()
	await test.frames(4)

func rng_isolation() -> void:
	var baseline: Dictionary
	for inspected in [false, true]:
		var session := preload("res://scenes/main/dungeon_test.tscn").instantiate() as DungeonSession
		session.progressive_relics = false
		session.tomb = preload("res://tests/fixtures/legacy_two_floor_tomb.tres")
		session.seed_value = 52
		test.session = session
		test.root.add_child(session)
		await test.frames(3)
		var plan := session.world.exploration
		var expected := 0
		for id in plan.wall_marks: expected += plan.wall_marks[id].size()
		if inspected:
			for id in plan.wall_marks:
				await enter_fixture(session.world, id)
				for mark: WallMarkDefinition in plan.wall_marks[id]:
					var actor := find_mark(session.world, mark.id)
					await stand(actor)
					test.key(KEY_E) # 每个真假痕迹都只进行第一次真实检查。
					await test.frames(1)
		test.check(expected > 0 and plan.checked_wall_marks.size() == (expected if inspected else 0), "RNG comparison actually inspects all live WallMarks versus none")
		var snapshot := preload("res://tests/phase_8b_isolation_checks.gd").new(test).snapshot(session)
		snapshot["wall_marks"] = WallMarkGenerator.signature(plan)
		var coffins: Array = []
		for id in plan.events:
			for event: TombRiskEvent in plan.events[id]: coffins.append([id, event.id, session.world.risk_service.preview(id, event).outcome])
		snapshot["coffin_outcomes"] = coffins
		if not inspected: baseline = snapshot
		test.check(snapshot == baseline and not plan.secret_discovered, "Inspect-none/all leaves map/enemies/Boss/ordinary antiques/relics/coffin results unchanged")
		session.queue_free()
		await test.frames(3)
	seed(991)
	var expected := randi()
	seed(991)
	TombExplorationPlan.build(DungeonGenerator.generate(52, DungeonSession.DEFAULT_CONFIG), 52, 1)
	test.check(randi() == expected, "Wall generation leaves global random stream untouched")
