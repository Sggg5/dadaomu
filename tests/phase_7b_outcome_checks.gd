extends RefCounted
## 直接HP边界仅在本套件；真实敌人致死独立由风险流程验证。
var test: SceneTree
var completed: bool = false
const COIN: AntiqueDefinition = preload("res://data/antiques/republic_silver_coin.tres")


func _init(context: SceneTree) -> void: test = context


func finished_checks() -> void:
	var session: DungeonSession = test.session
	var world := session.world
	var same := session.complete_screen
	var value := world.player.antiques.total_value()
	var relics := world.player.relics.inventory.ids()
	test.key(KEY_TAB)
	test.key(KEY_1)
	test.check(not world.player.controls_enabled and world.run_finished and not world.antique_panel.panel.visible and not session.rewards.active, "Ended Run freezes Player/Panel/reward activity")
	test.check(world.player.relics.inventory.ids() == relics, "Ended Run ignores engineering relic/debug management input")
	var before := world.current_room.projectiles.get_child_count()
	world.player.weapon.cooldown_remaining = 0
	world.player.weapon.try_attack(world.player.position,Vector2.RIGHT,world.player.stats)
	test.check(world.current_room.projectiles.get_child_count() == before and not world.request_traversal(0) and not session.request_extraction() and not session.request_next_floor() and not session.request_run_complete(), "Ended Run blocks direct spawning/traversal/extraction/descent/repeated finish")
	test.check(session.complete_screen == same and world.player.antiques.total_value() == value, "No repeat screen or cargo mutation after ended input")


func run() -> void:
	var session: DungeonSession = test.session
	test.check(not session.request_extraction(), "Cannot extract before first Boss victory")
	var world := session.world
	world._switch_room(world.layout.boss_id,-1)
	test.check(not session.request_extraction(), "Living first Boss cannot extract")
	world.current_room.boss_encounter.boss.take_damage(845)
	await test.frames(3)
	var exit := world.current_room.get_node("ExpeditionExit") as ExpeditionExit
	test.check(exit != null and world.current_room.room_state.status == RoomState.Status.CLEARED, "First Boss victory creates choice exit")
	world.player.position = exit.position+Vector2(100,0)
	test.check(not exit.request_extract() and not exit.request_descend(), "E/F range guard before choice")
	world.player.antiques.add(COIN)
	world.player.position = exit.position+Vector2(24,0)
	test.key(KEY_F)
	test.key(KEY_E)
	var result := session.complete_screen.result
	test.check(session.floor_number == 1 and result.outcome == RunResult.Outcome.EXTRACTED and result.floors_cleared == 1 and result.bosses_defeated == 1, "Actual F/E race only extracts floor1/Boss1, never descends")
	test.check(result.antique_names == [COIN.display_name] and result.antique_value == 120 and world.player.antiques.total_value() == 120 and session.complete_screen.label.text.contains("成功撤离") and session.complete_screen.label.text.contains("安全带回总估值：¥120"), "Extraction preserves pure safe cargo snapshot, no death clearing")
	test.check(exit.used and not exit.request_descend() and not exit.request_extract(), "Choice forever single-use")
	finished_checks()
	var old_screen := session.complete_screen
	await test.reset(KEY_R)
	test.check(not is_instance_valid(old_screen) and not session.run_ended and session.world.player.antiques.items().is_empty(), "R after EXTRACTED resets and frees result")
	# 第一层无货死亡：一次结束，0损失。
	world = session.world
	world.player.health.take_damage(80)
	result = session.complete_screen.result
	test.check(result.outcome == RunResult.Outcome.DEAD and result.antique_value == 0 and result.antique_names.is_empty() and session.complete_screen.label.text.contains("未携带古董") and session.complete_screen.label.text.contains("本次损失：¥0"), "Empty floor1 death ends with zero loss and explicit text")
	finished_checks()
	await test.reset()
	# 古董房死亡：先快照，再clear；原底座不能拾取。
	world = session.world
	world.player.antiques.add(COIN)
	world.player.antiques.add(COIN)
	world._switch_room(world.layout.antique_id,-1)
	var pedestal := world.current_room.get_node("AntiquePedestal") as AntiquePedestal
	world.player.position = pedestal.position
	world.player.health.take_damage(80)
	result = session.complete_screen.result
	test.check(result.outcome == RunResult.Outcome.DEAD and result.antique_value == 240 and result.antique_names.size() == 2 and world.player.antiques.items().is_empty(), "Cargo death snapshots exact loss before Inventory.clear")
	test.check(not pedestal.try_pickup() and session.complete_screen.label.text.contains("全部遗失") and session.complete_screen.label.text.contains("本次损失：¥240"), "Antique-room death cannot pickup and UI shows all lost")
	finished_checks()
	await test.reset()
	world = session.world
	world._switch_room(world.layout.boss_id,-1)
	world.player.antiques.add(COIN)
	world.player.health.take_damage(80)
	test.check(session.complete_screen.result.outcome == RunResult.Outcome.DEAD and not world.hud.boss_display.visible and not world.current_room.boss_encounter.boss.ai_enabled, "Boss-room death ends Run and hides/stops Boss")
	await test.reset()
	# 第二层死亡边界；跨层入口仍真正调用Session，Boss击杀仅本边界直控。
	world = session.world
	world._switch_room(world.layout.boss_id,-1)
	world.current_room.boss_encounter.boss.take_damage(845)
	session.request_next_floor()
	await test.frames(5)
	session.world.player.antiques.add(COIN)
	session.world.player.health.take_damage(80)
	result = session.complete_screen.result
	test.check(result.outcome == RunResult.Outcome.DEAD and result.floor_reached == 2 and result.floors_cleared == 1 and result.bosses_defeated == 1 and result.antique_value == 120 and session.world.player.antiques.items().is_empty(), "Floor2 death uses explicit DEAD, preserves cleared-floor stats, loses all cargo")
	finished_checks()
	old_screen = session.complete_screen
	session._seed_rng.seed = 20261006
	var old_seed := session.run_seed
	await test.reset(KEY_N)
	test.check(not is_instance_valid(old_screen) and not session.run_ended and session.floor_number == 1 and session.run_seed != old_seed and session.world.player.antiques.items().is_empty(), "N after DEAD starts new Seed/empty bag and frees screen")
	# 同帧E排队后死亡：旧跨层回调必须取消，R/N仍可重开。
	world = session.world
	world._switch_room(world.layout.boss_id,-1)
	world.current_room.boss_encounter.boss.take_damage(845)
	var pending := world.current_room.get_node("ExpeditionExit") as ExpeditionExit
	world.player.position = pending.position
	test.key(KEY_E)
	world.player.health.take_damage(80)
	await test.frames(5)
	test.check(session.run_ended and session.floor_number == 1 and session.complete_screen.result.outcome == RunResult.Outcome.DEAD and not session.request_next_floor(), "Death after queued E cancels descent instead of restoring lost carry")
	await test.reset(KEY_R)
	test.check(not session.run_ended and session.floor_number == 1 and session.world.player.health.current_hp == 80, "R restarts normally after canceled dead descent")
	completed = true
