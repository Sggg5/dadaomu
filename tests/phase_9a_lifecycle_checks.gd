extends RefCounted
var test: SceneTree
func _init(context: SceneTree) -> void: test = context

func run() -> void:
	var boundary = preload("res://tests/phase_9a_interaction_checks.gd").new(test)
	var content: TombRiskContent = await boundary.fixture(TombRiskResult.Outcome.AMBUSH)
	var world := test.session.world as RoomController
	var actor: TombRiskInteractable = boundary.event_in(content, content.events[0])
	world.player.position = actor.position + Vector2(24, 0)
	test.key(KEY_E)
	test.key(KEY_E)
	var enemies := content.ambush.get_children()
	for enemy: Enemy in enemies:
		for attempt in range(128):
			if not is_instance_valid(enemy) or enemy.health.is_dead or world.player.health.is_dead: break
			var origin := enemy.position + Vector2(0, 130)
			if not Room.ROOM_RECT.grow(-20).has_point(origin): origin = enemy.position + Vector2(130, 0)
			world.player.position = origin
			world.player.velocity = Vector2.ZERO
			world.player.weapon.try_attack(origin, (enemy.position - origin).normalized(), world.player.stats)
			await test.frames(14)
	test.check(content.remaining() == 0 and not world.player.health.is_dead and content.service.results[content.source(actor.event)].wave_completed, "Live coffin ambush dies to real Weapon/Projectile with active AI")
	var pickup := content.get_node("RiskLoot_%s" % actor.event.id) as AntiquePedestal
	var definition := pickup.definition
	var source := pickup.source_id
	var room_id := world.current_id
	var event := actor.event
	# 离房/重访：使用同一账本重新装配内容节点，模拟实际Room卸载后的恢复边界。
	world._switch_room(world.layout.start_id, -1)
	await test.frames(3)
	world._switch_room(room_id, -1)
	var restored := TombRiskContent.new()
	restored.room = world.current_room
	restored.room_id = room_id
	restored.service = world.risk_service
	restored.events = [event]
	world.current_room.risk_content = restored
	world.current_room.add_child(restored)
	pickup = restored.get_node("RiskLoot_%s" % event.id)
	test.check(pickup.definition == definition and restored.remaining() == 0, "Unclaimed reward survives unloading; completed ambush never respawns")
	world.player.position = pickup.position + Vector2(24, 0)
	test.key(KEY_E)
	await test.frames(2)
	world.player.antiques.remove(definition.id)
	test.check(world.states[room_id].is_loot_claimed(source), "Discarding event loot keeps its source consumed")
	var signature := world.layout.signature()
	test.key(KEY_R)
	await test.frames(5)
	world = test.session.world
	test.check(world.layout.signature() == signature and world.risk_service.results.is_empty() and not world.exploration.secret_discovered and world.player.antiques.used_slots() == 0, "R repeats exploration map and resets events/discovery/eight-slot cargo")
	var first_seed: int = test.session.run_seed
	test.session._seed_rng.seed = 999
	test.key(KEY_N)
	await test.frames(5)
	test.check(test.session.run_seed != first_seed and test.session.world.risk_service.results.is_empty() and test.session.world.player.health.current_hp == 80, "N starts fresh exploration with no event carryover")
	var carry := RunCarryState.capture(test.session.world.player)
	var second := test.session.next_floor_layout() as DungeonLayout
	test.session._enter_next_floor(second, carry) # 单项装配边界；真实过层仍由Phase6～7B覆盖。
	await test.frames(3)
	test.check(test.session.floor_number == 2 and test.session.world.risk_service.floor_number == 2 and test.session.world.risk_service.results.is_empty(), "Floor2 has independent event ledger at existing deterministic floor Seed")
	test.session.queue_free()
	await test.frames(4)
	await rng_integration()
	await exit_restore()

func exit_restore() -> void:
	var store := MuseumProfileStore.in_memory()
	var flow := preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
	flow.profile_store = store
	flow.night_seed = 33
	test.root.add_child(flow)
	await test.frames(3)
	flow.start_night()
	await test.frames(5)
	test.session = flow.dungeon
	var world := flow.dungeon.world
	world._switch_room(&"RISK_REWARD", -1)
	var content := world.current_room.risk_content
	var boundary = preload("res://tests/phase_9a_interaction_checks.gd").new(test)
	var actor: TombRiskInteractable = boundary.event_in(content, TombExplorationPlan.ALTAR)
	world.player.position = actor.position + Vector2(24, 0)
	var saves := store.save_count
	test.key(KEY_E)
	test.key(KEY_E)
	await test.frames(2)
	var pickup := content.get_node("RiskLoot_blood_altar") as AntiquePedestal
	world.player.position = pickup.position + Vector2(24, 0)
	test.key(KEY_E)
	await test.frames(2)
	test.check(world.player.health.current_hp == 65 and world.player.antiques.used_slots() > 0 and store.save_count == saves, "Real altar/cargo make no mid-Dungeon save or museum writes")
	flow.queue_free()
	await test.frames(4)
	flow = preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
	flow.profile_store = store
	flow.night_seed = 33
	test.root.add_child(flow)
	await test.frames(3)
	test.check(flow.current_day == 1 and flow.current_phase == MuseumState.Phase.MORNING and flow.museum_state.collection.all_items().is_empty(), "Quit during risk exploration restores preceding safe ground, no imported cargo")
	flow.start_night()
	await test.frames(5)
	test.check(flow.dungeon.world.player.health.current_hp == 80 and flow.dungeon.world.player.antiques.used_slots() == 0 and flow.dungeon.world.risk_service.results.is_empty(), "Next night is fresh80HP/eight-slot Run, never mid-event recovery")
	flow.queue_free()
	await test.frames(4)

func rng_integration() -> void:
	var baseline: Dictionary
	for opened in [false, true]:
		var session := preload("res://scenes/main/dungeon_test.tscn").instantiate() as DungeonSession
		session.seed_value = 33
		test.session = session
		test.root.add_child(session)
		await test.frames(3)
		var world := session.world
		var plan := world.exploration
		if opened:
			for id in plan.events:
				world._switch_room(id, -1)
				for enemy in world.current_room.enemy_spawner.get_children(): enemy.take_damage(10000)
				await test.frames(3)
				for event: TombRiskEvent in plan.events[id]:
					world.current_room.risk_content.resolve(event, world.current_room.risk_content.safe_position(plan.events[id].find(event)))
					if is_instance_valid(world.current_room.risk_content.ambush):
						for enemy in world.current_room.risk_content.ambush.get_children(): enemy.take_damage(10000)
					await test.frames(3)
		var snapshot := preload("res://tests/phase_8b_isolation_checks.gd").new(test).snapshot(session)
		var actors: Array = []
		for id in world.layout.ordered_ids():
			if world.layout.rooms[id].room_type != RoomDefinition.Type.COMBAT: continue
			# 使用新的RoomState仅重建对照的实际敌人配置，非游戏重刷入口。
			world.states[id] = RoomState.new()
			world._switch_room(id, -1)
			for enemy: Enemy in world.current_room.enemy_spawner.get_children():
				actors.append([id, enemy.definition.resource_path, enemy.health.max_hp, enemy.scaled_damage(enemy.definition.contact_damage), enemy.position])
			session.world.current_room.stop_combat()
		snapshot["actual_enemies"] = actors
		if not opened: baseline = snapshot
		test.check(snapshot == baseline, "Actual open-none/open-all leaves full map/live enemies/Boss/relic sequence/ordinary drops identical")
		test.check(world.player.health.max_hp == 80 and world.player.antiques.capacity == 8, "Optional risks never change80HP/eight slots")
		session.queue_free()
		await test.frames(4)
