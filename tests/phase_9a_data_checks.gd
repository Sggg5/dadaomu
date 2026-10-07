extends RefCounted
var test: SceneTree
const CONFIG: DungeonConfig = DungeonSession.DEFAULT_CONFIG
func _init(context: SceneTree) -> void: test = context

func run() -> void:
	var outcomes: Dictionary = {}
	var secrets := 0
	var forks := 0
	for seed_value in range(100):
		var base := DungeonGenerator.generate(seed_value, CONFIG)
		var signature := base.signature()
		var plan := TombExplorationPlan.build(base, seed_value, 1)
		var again := TombExplorationPlan.build(base, seed_value, 1)
		test.check(base.signature() == signature, "Overlay never mutates original topology seed%d" % seed_value)
		test.check(plan.layout.signature() == again.layout.signature() and plan.events == again.events and plan.secret_id == again.secret_id, "Overlay deterministic seed%d" % seed_value)
		var count := 0
		var altars := 0
		for id in plan.events:
			for event: TombRiskEvent in plan.events[id]:
				count += int(event.kind == TombRiskEvent.Kind.COFFIN)
				altars += int(event.kind == TombRiskEvent.Kind.ALTAR)
		test.check(count >= 1 and count <= 2 and altars <= 1, "Restrained per-floor coffin/altar frequency seed%d" % seed_value)
		var service := TombRiskService.new(seed_value, 1)
		var first := service.preview(&"ROOM", TombExplorationPlan.COFFIN)
		var second := service.preview(&"ROOM", TombExplorationPlan.COFFIN)
		test.check(first.outcome == second.outcome, "Same event seed repeat%d" % seed_value)
		outcomes[first.outcome] = true
		var resolved := service.resolve(&"ROOM", TombExplorationPlan.COFFIN)
		test.check(resolved.resolved and service.resolve(&"ROOM", TombExplorationPlan.COFFIN) == null and service.results.size() == 1, "Data layer exactly once seed%d" % seed_value)
		var parent: Dictionary = {plan.layout.start_id: true}
		var queue: Array[StringName] = [plan.layout.start_id]
		while not queue.is_empty():
			var id: StringName = queue.pop_front()
			for next: StringName in plan.layout.rooms[id].neighbors.values():
				if not parent.has(next): parent[next] = true; queue.append(next)
		test.check(parent.has(plan.layout.boss_id) and plan.layout.rooms[plan.layout.boss_id].distance_from_start == base.rooms[base.boss_id].distance_from_start, "Optional exploration never blocks/shortens Boss seed%d" % seed_value)
		if plan.secret_id != &"":
			secrets += 1
			test.check(not parent.has(plan.secret_id) and plan.layout.rooms[plan.secret_id].neighbors.is_empty() and not plan.secret_discovered, "Secret absent from main path and undiscovered seed%d" % seed_value)
		if not plan.fork.is_empty():
			forks += 1
			var a := plan.layout.rooms[plan.fork[0]]
			var b := plan.layout.rooms[plan.fork[3]]
			test.check(a.neighbors.values().has(b.room_id) and a.neighbors.values().has(plan.fork[1]) and plan.layout.rooms[plan.fork[2]].neighbors.values().has(b.room_id), "Safe direct edge and optional risk detour reunite seed%d" % seed_value)
		var ordinary := AntiqueLootService.new()
		ordinary.configure(seed_value, 1, base)
		var before: Array = []
		for id in base.ordered_ids():
			before.append([id, TombRiskService.POOL.pick(seed_value, 1, id).id, ordinary.has_cache(id), base.rooms[id].definition.spawns])
		for id in plan.events:
			for event: TombRiskEvent in plan.events[id]: service.resolve(id, event)
		var after: Array = []
		for id in base.ordered_ids():
			after.append([id, TombRiskService.POOL.pick(seed_value, 1, id).id, ordinary.has_cache(id), base.rooms[id].definition.spawns])
		test.check(before == after and DungeonGenerator.generate(seed_value, CONFIG).signature() == signature, "Open-all preserves main map/enemy templates/ordinary drops seed%d" % seed_value)
	test.check(outcomes.size() == 4 and secrets > 0 and secrets < 100 and forks > 0 and forks < 100, "100 Seeds cover four outcomes and optional secret/fork presence")
	var altered := TombExplorationPlan.COFFIN.duplicate() as TombRiskEvent
	altered.id = &"other_coffin"
	var different := 0
	for seed_value in range(100):
		var service := TombRiskService.new(seed_value, 2)
		different += int(service.preview(&"ROOM", altered).outcome != service.preview(&"ROOM", TombExplorationPlan.COFFIN).outcome)
	test.check(different > 20, "Distinct event ID independently changes outcomes")
	seed(55)
	var expected := randi()
	seed(55)
	TombExplorationPlan.build(DungeonGenerator.generate(15, CONFIG), 15, 1)
	TombRiskService.new(15, 1).resolve(&"ROOM", TombExplorationPlan.COFFIN)
	test.check(randi() == expected, "Exploration/event RNG does not consume global RNG")
	print("[9A distribution] secrets=%d forks=%d outcomes=%s" % [secrets, forks, outcomes.keys()])
