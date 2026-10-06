extends RefCounted
## 正常奖励、活跃AI、真实Weapon/Projectile击杀Boss，再用真实E进入第二层。
var test: SceneTree
var completed: bool = false
var driver: RefCounted


func _init(context: SceneTree) -> void:
	test = context
	driver = preload("res://tests/phase_5b_run_checks.gd").new(context)


func definition(id: StringName) -> RelicDefinition:
	var pool: RelicPool = RelicRewardService.DEFAULT_POOL
	for data in pool.relics:
		if data.id == id: return data
	return null


func boss_fight() -> void:
	var world: RoomController = test.session.world
	var room := world.current_room
	var boss := room.boss_encounter.boss as WarlordBoss
	var ticks: int = 0
	var saw_charge: bool = false
	var saw_shockwave: bool = false
	var saw_phase_two: bool = false
	var captured_shock: bool = false
	var captured_phase: bool = false
	while is_instance_valid(boss) and not boss.health.is_dead and not world.player.health.is_dead and ticks < 3600:
		# 驾驶选择安全、可见的射击点；AI保持开启，所有伤害来自真实弹丸。
		var preferred := boss.position + Vector2(260,0)
		var best: float = -INF
		for y in range(192,552,48):
			for x in range(160,1150,48):
				var point := Vector2(x,y)
				var distance := point.distance_to(boss.position)
				if distance < 210 or distance > 380: continue
				if room.definition.obstacles.any(func(rect: Rect2) -> bool: return rect.grow(20).has_point(point)): continue
				var ray := PhysicsRayQueryParameters2D.create(boss.position,point,1,[boss.get_rid()])
				if not boss.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
				var score: float = 500 - absf(distance - 260)
				if boss.state == WarlordBoss.State.CHARGE:
					var closest := Geometry2D.get_closest_point_to_segment(point,boss.position,boss.position + boss.charge_direction * 320)
					score = minf(score,point.distance_to(closest))
				for actor in room.boss_encounter.targets():
					if actor != boss: score = minf(score,point.distance_to(actor.global_position))
				if score > best:
					best = score
					preferred = point
		world.player.position = preferred
		world.player.velocity = Vector2.ZERO
		# 仅在决策/后摇窗口开火，保留完整冲锋、震荡和召尸的观测。
		if boss.state in [WarlordBoss.State.DECIDE,WarlordBoss.State.RECOVERY]:
			world.player.weapon.try_attack(preferred,(boss.position-preferred).normalized(),world.player.stats)
		saw_charge = saw_charge or boss.charges > 0
		saw_shockwave = saw_shockwave or boss.shockwaves > 0
		saw_phase_two = saw_phase_two or boss.phase_two
		if not captured_shock and boss.state == WarlordBoss.State.SHOCKWAVE_WINDUP:
			test.capture("boss_shockwave")
			captured_shock = true
		if not captured_phase and boss.phase_two:
			test.capture("boss_phase_two")
			captured_phase = true
		await test.frames(6)
		ticks += 6
		if ticks == 180: test.capture("boss_charge")
	test.check(room.boss_encounter.finished and not world.player.health.is_dead, "Real Weapon/Projectile defeats active Boss with earned formal Build")
	test.check(saw_charge and saw_shockwave and saw_phase_two, "Live fight executes charge, shockwave and half-HP summons")
	print("[Phase6 live Boss] physics duration %.2fs, Player HP %.2f" % [ticks/60.0,world.player.health.current_hp])
	await test.frames(12)
	test.capture("boss_victory")


func run() -> void:
	var session: DungeonSession = test.session
	var world := session.world
	var first_signature := world.layout.spatial_signature()
	var first_complete := world.layout.signature()
	var run_seed := session.run_seed
	var reward_signature: String = driver.reward_signature(session.rewards)
	test.check(session.floor_number == 1 and session.current_floor_seed == run_seed, "Initial floor1 seed equals Run seed")
	test.check(not session.request_next_floor(), "Uncleared Run cannot advance")
	var second := session.next_floor_layout()
	test.check(second.signature() == session.next_floor_layout().signature() and second.seed_value == (run_seed ^ (2*104729)), "Floor2 deterministic stable seed derivation")
	test.check(second.spatial_signature() != first_signature, "Floor2 spatial signature differs from floor1")
	# Seed192034有八个普通房；优先正常清六房拿两件，剩余阈值跨层验证。
	for id in world.layout.rooms:
		if world.layout.rooms[id].room_type == RoomDefinition.Type.COMBAT:
			await driver.visit(id)
			if session.rewards.combat_clears >= 6: break
	test.check(driver.picked.size() >= 2, "Normal active combat/E pedestal obtains earned Build before Boss")
	await driver.visit(world.layout.boss_id)
	test.check(world.current_room.room_type == RoomDefinition.Type.BOSS and world.current_room.enemy_spawner.get_child_count() == 0, "Actual Door reaches formal Boss without template enemies")
	await boss_fight()
	var exit := world.current_room.get_node("FloorExit") as FloorExit
	world.player.position = Vector2(96,560)
	test.check(not exit.request() and not exit.used, "FloorExit rejects interaction outside64px")
	# 单项Runtime边界夹具：完整Boss击杀已结束；不使用F2，不影响战斗通关。
	for id in [&"spirit_kite",&"copper_mirror",&"luoyang_shovel"]:
		world.player.relics.inventory.add(definition(id))
	var old_effects: Array[RelicEffect] = []
	for id in world.player.relics.inventory.ids(): old_effects.append(world.player.relics.inventory.get_effect(id))
	var mirror := world.player.relics.inventory.get_effect(&"copper_mirror")
	var shovel := world.player.relics.inventory.get_effect(&"luoyang_shovel")
	var kite := world.player.relics.inventory.get_effect(&"spirit_kite")
	mirror.set("attacks",2)
	shovel.set("attacks",4)
	world.player.invulnerability_remaining = 0
	world.player.take_damage(5)
	test.check(kite.get("charged"), "Carry boundary fixture has charged kite and nonzero attack counters")
	var hp := world.player.health.current_hp
	var ids := world.player.relics.inventory.ids()
	var service := session.rewards
	var progress := service.combat_clears
	var given := service.rewards_given
	var seen := service._seen.duplicate()
	var old_world := world
	# 临时DOT生命周期夹具：属于旧Room，不进入Carry快照。
	var transient := BossEncounter.SCARAB.instantiate() as Enemy
	transient.configure_spawn(world.player,world.current_room.projectiles,BossEncounter.SCARAB_DATA,world.current_room.difficulty)
	transient.position = Vector2(1100,544)
	world.current_room.add_child(transient)
	transient.stop_ai()
	var burn := Burn.new()
	burn.target = transient
	burn.runtime = world.player.relics
	burn.remaining = 10
	transient.add_child(burn)
	world.player.position = exit.position + Vector2(20,0)
	test.capture("exit")
	test.key(KEY_E)
	test.check(exit.used and not exit.request(), "Real E consumes FloorExit only once")
	await test.frames(5)
	world = session.world
	test.check(session.floor_number == 2 and session.current_floor_seed == second.seed_value and world.layout.signature() == second.signature(), "E enters deterministic second floor")
	test.check(not is_instance_valid(old_world) and driver.player_count(test.root) == 1, "Old World releases; exactly one Player remains")
	test.check(not is_instance_valid(burn) and not is_instance_valid(transient), "Old Room temporary burn and target never cross floors")
	test.check(is_equal_approx(world.player.health.current_hp,hp) and world.hud.get_node("Root/HP").text.contains("80"), "Current HP survives and HUD refreshes")
	test.check(world.player.relics.inventory.ids() == ids, "Relic ID set survives next floor")
	for index in range(old_effects.size()):
		var effect := old_effects[index]
		var replacement := world.player.relics.inventory.get_effect(ids[index])
		test.check(replacement != effect and replacement.install_count == 1 and effect.uninstall_count == 1, "New effect installs once; old effect uninstalls once: " + str(ids[index]))
	test.check(not world.player.relics.inventory.get_effect(&"spirit_kite").get("charged") and world.player.relics.inventory.get_effect(&"copper_mirror").get("attacks") == 0 and world.player.relics.inventory.get_effect(&"luoyang_shovel").get("attacks") == 0 and world.player.weapon.cooldown_remaining == 0, "Kite/counters/weapon cooldown reset on next floor")
	test.check(session.rewards == service and service.combat_clears == progress and service.rewards_given == given and service._seen == seen and driver.reward_signature(service) == reward_signature, "RewardService identity/progress/sequence/seen all carry unchanged")
	test.check(world.current_room.room_type == RoomDefinition.Type.START and world.current_room.remaining_count() == 0 and not world.hud.boss_display.visible, "Floor2 START safe and hides Boss HUD")
	test.capture("floor_two_start")
	await test.walk(world.layout.rooms[world.current_id].neighbors.keys()[0])
	var room := world.current_room
	test.check(room.difficulty.depth == world.layout.rooms[world.current_id].distance_from_start + 3 and room.difficulty.tier >= 2, "Floor2 first combat effective depth includes offset3, minimumTier2")
	test.check(room.enemy_spawner.get_children().all(func(actor: Enemy) -> bool: return is_equal_approx(actor.health.max_hp,actor.definition.max_hp*room.difficulty.hp_multiplier)), "Floor2 live enemies receive instance-scaled HP")
	# Driver.picked仅跟踪正常奖励，下面仅复用fight，避免额外夹具ID影响visit断言。
	await driver.fight()
	test.check(service.combat_clears == progress+1 and service.rewards_given == 3, "First floor2 combat continues global progress and third reward at7")
	test.check(service._seen.has(world.scoped_room_id(world.current_id)) and world.scoped_room_id(world.current_id) != world.current_id, "Floor-scoped room IDs prevent duplicate local-ID suppression")
	var context := RoomClearContext.new()
	context.room_type = RoomDefinition.Type.COMBAT
	context.was_combat = true
	for index in range(8,12):
		context.room_id = StringName("F2:unit_extra_%d" % index)
		service.on_room_cleared(context)
	test.check(service.rewards_given == 3, "No fourth formal reward after global seventh clear")
	test.check(BossEncounter.SCARAB_DATA.max_hp == 65 and BossEncounter.SCARAB_DATA.contact_damage == 14, "Shared EnemyDefinition remains unchanged")
	test.capture("floor_two_combat")
	# 第二层占位房边界：直接进入但仍真实弹丸清除全部普通敌人。
	world._switch_room(world.layout.boss_id,-1)
	await test.frames(2)
	test.check(world.current_room.boss_encounter.boss is TombGuardianBeast and world.current_room.enemy_spawner.get_child_count() == 0 and world.hud.boss_display.visible, "Floor2 BOSS replaces old placeholder with one formal beast")
	var beast_driver = preload("res://tests/beast_fight_driver.gd").new(test)
	await beast_driver.run()
	test.check(beast_driver.completed and world.current_room.has_node("RunExit"), "Second formal Boss clears and offers RunExit")
	test.check(not world.current_room.has_node("FloorExit") and not session.request_next_floor(), "Floor2 victory creates no third-floor exit")
	await test.reset(KEY_R)
	world = session.world
	test.check(session.floor_number == 1 and session.run_seed == run_seed and world.layout.signature() == first_complete, "R from floor2 resets Run to same first-floor layout")
	test.check(world.player.health.current_hp == 80 and world.player.relics.inventory.ids().is_empty() and session.rewards.combat_clears == 0 and driver.reward_signature(session.rewards) == reward_signature, "R restores80HP, empty Build/progress, identical reward sequence")
	test.check(session.next_floor_layout().signature() == second.signature(), "Repeated same Run reproduces identical second floor")
	session._seed_rng.seed = 20261006
	await test.reset(KEY_N)
	test.check(session.floor_number == 1 and session.run_seed != run_seed and session.world.player.health.current_hp == 80 and session.world.player.relics.inventory.ids().is_empty() and session.rewards.combat_clears == 0, "N creates new Run on floor1 with fresh HP/Build/rewards")
	test.check(driver.reward_signature(session.rewards) != reward_signature, "Selected N Seed creates new reward order")
	await health_boundaries()
	completed = true


func health_boundaries() -> void:
	var health := Health.new()
	var events := {"changed":0,"damaged":0,"died":0}
	health.changed.connect(func(_hp: float,_max: float) -> void: events.changed += 1)
	health.damaged.connect(func(_damage: float) -> void: events.damaged += 1)
	health.died.connect(func() -> void: events.died += 1)
	health.initialize(80)
	health.restore(200)
	test.check(health.current_hp == 80 and not health.is_dead, "Health.restore clamps upper bound")
	health.restore(-20)
	test.check(health.current_hp == 0 and health.is_dead, "Health.restore clamps lower bound and updates death state")
	health.restore(33)
	test.check(health.current_hp == 33 and not health.is_dead and events.changed == 4 and events.damaged == 0 and events.died == 0, "Health.restore emits only changed, never damaged/died")
	health.free()
