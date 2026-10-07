extends RefCounted
var test: SceneTree
const CONFIG: DungeonConfig = DungeonSession.DEFAULT_CONFIG
func _init(context: SceneTree) -> void: test = context

func run() -> void:
	var outcomes: Dictionary = {}
	var secrets := 0
	var forks := 0
	var empty_coffin_floors := 0
	var outcome_counts: Array[int] = [0, 0, 0, 0]
	test.check(TombExplorationPlan.COFFIN.weights == PackedInt32Array([35, 25, 20, 20]) and not TombExplorationPlan.COFFIN.ambush_reward and TombExplorationPlan.COFFIN.hp_cost == 20, "Official coffin uses35/25/20/20,20HP trap and no ambush consolation")
	test.check(TombExplorationPlan.ALTAR.hp_cost == 25 and TombExplorationPlan.ALTAR.high_value_reward, "Official altar costs25HP and retains rare/treasure candidates")
	test.check(TombExplorationPlan.CONFIG.fork_chance == .45 and TombExplorationPlan.CONFIG.secret_chance == .35 and TombExplorationPlan.CONFIG.standalone_altar_chance == .25 and TombExplorationPlan.CONFIG.coffin_chance == .65, "Official exploration density configuration matches9A.1")
	for seed_value in range(1000):
		var base := DungeonGenerator.generate(seed_value, CONFIG)
		var signature := base.signature()
		var plan := TombExplorationPlan.build(base, seed_value, 1)
		var again := TombExplorationPlan.build(base, seed_value, 1)
		test.check(base.signature() == signature, "Overlay never mutates original topology seed%d" % seed_value)
		test.check(plan.layout.signature() == again.layout.signature() and plan.events == again.events and plan.secret_id == again.secret_id, "Overlay deterministic seed%d" % seed_value)
		var ordinary_coffins := 0
		var secret_coffins := 0
		var altars := 0
		for id in plan.events:
			for event: TombRiskEvent in plan.events[id]:
				if event.kind == TombRiskEvent.Kind.COFFIN:
					if id == plan.secret_id: secret_coffins += 1
					else: ordinary_coffins += 1
				altars += int(event.kind == TombRiskEvent.Kind.ALTAR)
		empty_coffin_floors += int(ordinary_coffins == 0)
		test.check(ordinary_coffins <= 1 and secret_coffins <= 1 and altars <= 1, "At most one ordinary coffin; optional secret event separate seed%d" % seed_value)
		var service := TombRiskService.new(seed_value, 1)
		var first := service.preview(&"ROOM", TombExplorationPlan.COFFIN)
		var second := service.preview(&"ROOM", TombExplorationPlan.COFFIN)
		test.check(first.outcome == second.outcome, "Same event seed repeat%d" % seed_value)
		outcomes[first.outcome] = true
		outcome_counts[first.outcome] += 1
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
	test.check(outcomes.size() == 4 and secrets > 0 and secrets < 1000 and forks > 0 and forks < 1000 and empty_coffin_floors > 0, "1000 Seeds include all outcomes, absent secrets/forks and no ordinary coffin floors")
	test.check(outcome_counts[TombRiskResult.Outcome.ANTIQUE] < 450, "1000 Seed sample: direct antique is clearly below majority without asserting exact rate")
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
	print("[9A.1 distribution] n=1000 secrets=%d forks=%d no_ordinary_coffin=%d outcomes=%s" % [secrets, forks, empty_coffin_floors, outcome_counts])
