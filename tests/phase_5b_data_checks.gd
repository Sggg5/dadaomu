extends RefCounted
var test: SceneTree
var completed: bool = false
var pool: RelicPool = RelicRewardService.DEFAULT_POOL


func _init(context: SceneTree) -> void:
	test = context


func definition(id: StringName) -> RelicDefinition:
	for item in pool.relics:
		if item.id == id:
			return item
	return null


func signature(service: RelicRewardService) -> String:
	return ",".join(service.sequence.map(func(item: RelicDefinition) -> String: return str(item.id)))


func request() -> AttackRequest:
	var base := AttackRequest.new()
	base.origin = Vector2(640, 368)
	base.direction = Vector2.RIGHT
	base.damage = 20.0
	base.speed = 650.0
	base.lifetime = 3.0
	return base


func run() -> void:
	var initial: RoomClearContext = test.contexts[0]
	test.check(initial.room_id == &"START" and initial.room_type == RoomDefinition.Type.START and not initial.was_combat and initial.enemy_count == 0, "START clear context includes identity/type and no combat")
	test.check(pool.is_valid() and pool.relics.size() == 8 and pool.relics.all(func(item: RelicDefinition) -> bool: return not str(item.id).begins_with("test_")), "Formal pool has exactly eight unique non-engineering relics")
	var a := RelicRewardService.new()
	var b := RelicRewardService.new()
	a.configure(192034)
	b.configure(192034)
	var digest := FileAccess.open("res://logs/phase_5b_rewards_%s.txt" % DisplayServer.get_name(), FileAccess.WRITE)
	digest.store_string(signature(a))
	test.check(signature(a) == signature(b) and a._rng != b._rng, "Same Seed reward order uses independent RNG instances")
	var variants: Dictionary[String, bool] = {}
	for seed_value in range(20):
		b.configure(seed_value)
		variants[signature(b)] = true
	test.check(variants.size() > 10, "Different Seeds normally produce different reward sequences")
	var unique: Dictionary[StringName, bool] = {}
	for item in a.sequence:
		unique[item.id] = true
	test.check(unique.size() == 8, "Reward shuffle is without replacement across all eight items")
	var rewards: Array[StringName] = []
	a.reward_available.connect(func(item: RelicDefinition, _id: StringName) -> void: rewards.append(item.id))
	a.on_room_cleared(initial)
	var antique := RoomClearContext.new()
	antique.room_id = &"ANTIQUE"
	antique.room_type = RoomDefinition.Type.ANTIQUE
	a.on_room_cleared(antique)
	var boss := RoomClearContext.new()
	boss.room_id = &"BOSS"
	boss.room_type = RoomDefinition.Type.BOSS
	a.on_room_cleared(boss)
	test.check(a.combat_clears == 0, "START ANTIQUE and Boss placeholder never count rewards")
	for index in range(1, 6):
		var clear := RoomClearContext.new()
		clear.room_id = StringName("COMBAT_%d" % index)
		clear.room_type = RoomDefinition.Type.COMBAT
		clear.was_combat = true
		clear.enemy_count = 3
		a.on_room_cleared(clear)
		a.on_room_cleared(clear)
		test.check(a.combat_clears == index and rewards.size() == (1 if index < 3 else (2 if index < 5 else 3)), "Reward cadence and duplicate clear guard at COMBAT %d" % index)
	a.stop()
	a.on_room_cleared(antique)
	test.check(a.rewards_given == 3 and not a.active, "Stopped reward service cannot issue more rewards")
	a.free()
	b.free()
	var base := request()
	base.pierce_count = 2
	base.projectile_scale = 1.8
	base.tags = [&"heavy"]
	var copy := base.copy()
	copy.tags.append(&"copy_only")
	test.check(copy.pierce_count == 2 and copy.projectile_scale == 1.8 and copy.origin == base.origin and copy.direction == base.direction and copy.damage == base.damage and copy.speed == base.speed and copy.lifetime == base.lifetime and not base.tags.has(&"copy_only"), "AttackRequest copies every new field and isolates tag arrays")
	base = request()
	var player: Player = test.session.world.player
	var runtime := player.relics
	var inventory := runtime.inventory
	inventory.add(definition(&"five_emperor_coins"))
	var batch := runtime.prepare_attack(base)
	test.check(batch.size() == 2 and batch[0].damage == 16.0 and batch[1].direction != batch[0].direction, "Coins create plus/minus five degree double shots with 0.8 damage")
	inventory.clear()
	inventory.add(definition(&"copper_mirror"))
	for index in range(1, 7):
		batch = runtime.prepare_attack(base)
		test.check(batch.size() == (3 if index % 3 == 0 else 1), "Mirror expands only every third attack %d" % index)
	inventory.clear()
	var order_a: Array[AttackRequest]
	for order in [[&"five_emperor_coins", &"tomb_nail", &"copper_mirror"], [&"copper_mirror", &"tomb_nail", &"five_emperor_coins"]]:
		inventory.clear()
		for id in order:
			inventory.add(definition(id))
		test.check(inventory.attack_order() == [&"five_emperor_coins", &"tomb_nail", &"copper_mirror"], "Stage ordering overrides alphabetical and installation ordering")
		runtime.prepare_attack(base)
		runtime.prepare_attack(base)
		batch = runtime.prepare_attack(base)
		if order_a.is_empty():
			order_a = batch
		else:
			test.check(batch.size() == 6 and batch[0].direction == order_a[0].direction and batch[5].direction == order_a[5].direction and batch[5].damage == order_a[5].damage and batch.all(func(item: AttackRequest) -> bool: return item.pierce_count == 1), "Coins plus mirror plus nail naturally combine identically in reverse obtain order")
	inventory.clear()
	inventory.add(definition(&"luoyang_shovel"))
	var mirror_priority := definition(&"copper_mirror").duplicate() as RelicDefinition
	var shovel_priority := definition(&"luoyang_shovel").duplicate() as RelicDefinition
	mirror_priority.id = &"z_priority_mirror"
	shovel_priority.id = &"a_priority_shovel"
	inventory.clear()
	inventory.add(shovel_priority)
	inventory.add(mirror_priority)
	test.check(inventory.attack_order() == [&"z_priority_mirror", &"a_priority_shovel"], "Explicit priority wins over ID tie-break within FINAL stage")
	inventory.clear()
	inventory.add(definition(&"luoyang_shovel"))
	for index in range(1, 11):
		batch = runtime.prepare_attack(base)
		test.check(batch.size() == (2 if index % 5 == 0 else 1), "Shovel triggers only every fifth attack %d" % index)
		if index % 5 == 0:
			var heavy := batch[1]
			test.check(heavy.damage == 44.0 and heavy.speed == 845.0 and heavy.lifetime == 0.22 and heavy.projectile_scale == 1.8 and heavy.tags.has(&"heavy"), "Shovel wind has distinct short heavy projectile values")
	inventory.clear()
	inventory.add(definition(&"spirit_kite"))
	var kite := inventory.get_effect(&"spirit_kite")
	player.take_damage(10.0)
	test.check(kite.get("charged") and not player.take_damage(10.0), "One effective damage charges kite and invulnerability rejects repeat")
	test.check(runtime.prepare_attack(base).size() == 3 and not kite.get("charged") and runtime.prepare_attack(base).size() == 1, "Next attack consumes kite side shots without infinite repeats")
	inventory.clear()
	player.health.heal(100.0)
	completed = true
