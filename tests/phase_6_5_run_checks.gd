extends RefCounted
var test: SceneTree
var completed: bool = false


func _init(context: SceneTree) -> void: test = context


func run() -> void:
	var session: DungeonSession = test.session
	var driver = preload("res://tests/phase_5b_run_checks.gd").new(test)
	var original := session.world.layout.signature()
	var run_seed := session.run_seed
	await prepare_first_floor(driver)
	for id in session.world.layout.rooms:
		if session.world.layout.rooms[id].room_type == RoomDefinition.Type.COMBAT:
			await driver.visit(id)
			if session.rewards.combat_clears >= 6: break
	test.check(driver.picked.size() == 2 and session.bosses_defeated == 0, "Normal floor1 earns two formal relics without F2")
	await driver.visit(session.world.layout.boss_id)
	var warlord_driver = preload("res://tests/phase_6_floor_checks.gd").new(test)
	await warlord_driver.boss_fight()
	test.check(session.bosses_defeated == 1 and not session.run_completed, "Real warlord victory counts one, does not finish Run")
	var hp := session.world.player.health.current_hp
	var ids := session.world.player.relics.inventory.ids()
	var floor_exit := session.world.current_room.get_node("FloorExit") as FloorExit
	session.world.player.position = floor_exit.position+Vector2(20,0)
	test.key(KEY_E)
	await test.frames(5)
	test.check(session.floor_number == 2 and session.world.player.health.current_hp == hp and session.world.player.relics.inventory.ids() == ids, "Actual E enters floor2 retaining earned Build/HP")
	await test.walk(session.world.layout.rooms[session.world.current_id].neighbors.keys()[0])
	await driver.fight()
	test.check(session.rewards.combat_clears == 7 and driver.picked.size() == 3, "Normal floor2 seventh clear/E grants third formal relic")
	await prepare_second_floor(driver)
	await driver.visit(session.world.layout.boss_id)
	var beast_driver = preload("res://tests/beast_fight_driver.gd").new(test)
	await beast_driver.run()
	test.check(beast_driver.completed and session.bosses_defeated == 2 and not session.run_completed, "Actual beast victory counts second Boss, awaits return interaction")
	var world := session.world
	var room := world.current_room
	var run_exit := room.get_node("RunExit") as RunExit
	test.check(room.room_state.status == RoomState.Status.CLEARED and room.doors.values().all(func(door: Door) -> bool: return door.is_open) and not world.hud.boss_display.visible and not room.has_node("FloorExit"), "Final Boss clears/unlocks/hides HUD and creates only RunExit")
	world.player.position = run_exit.position+Vector2(100,0)
	test.check(not run_exit.request() and not session.run_completed, "RunExit rejects E beyond64px")
	world.player.position = run_exit.position+Vector2(64,0)
	hp = world.player.health.current_hp
	ids = world.player.relics.inventory.ids()
	test.capture("return_exit")
	test.key(KEY_E)
	test.check(run_exit.used and not run_exit.request() and session.run_completed and not world.player.controls_enabled, "E at64px completes once and stops controls")
	await test.frames(3)
	var screen := session.complete_screen
	var result := screen.result
	test.check(result.run_seed == run_seed and result.floors_cleared == 2 and result.current_hp == hp and result.max_hp == 80, "RunResult snapshots Seed/two floors/currentHP/maxHP")
	test.check(result.relic_names.size() == ids.size() and result.relic_names.size() == 3 and result.bosses_defeated == 2 and result.combat_clears == session.rewards.combat_clears, "RunResult snapshots three earned relic names/combat/Boss statistics")
	test.check(screen.label.text.contains(str(run_seed)) and screen.label.text.contains("清理墓层：2") and screen.label.text.contains("剩余生命：%.1f / 80" % hp) and screen.label.text.contains("Boss击败：2") and screen.label.text.contains("普通战斗房清理：%d" % result.combat_clears), "Complete screen shows correct Seed/floors/HP/Bosses/combat counts")
	for name in result.relic_names: test.check(screen.label.text.contains(name), "Complete screen shows earned relic " + name)
	verify_result(result)
	test.capture("run_complete")
	Input.action_press("attack")
	await test.frames(6)
	Input.action_release("attack")
	world.player.weapon.cooldown_remaining = 0
	world.player.weapon.try_attack(world.player.position,Vector2.RIGHT,world.player.stats)
	test.check(room.projectiles.get_child_count() == 0 and not world.request_traversal(room.doors.keys()[0]) and not session.request_run_complete() and not session.request_next_floor(), "Completed Run forbids attack spawning/traversal/repeated finish/third floor")
	await test.reset(KEY_R)
	test.check(not is_instance_valid(screen) and not session.run_completed and session.floor_number == 1 and session.run_seed == run_seed and session.world.layout.signature() == original, "R from complete destroys screen and restarts identical floor1 Seed")
	test.check(session.world.player.health.current_hp == 80 and session.world.player.relics.inventory.ids().is_empty() and session.rewards.combat_clears == 0 and session.bosses_defeated == 0, "R resets HP80/Build/rewards/Boss count")
	# 独立N边界：不伪造主流程。重新建立仅结算快照界面，验证新局清理。
	var fixture_screen := RunCompleteScreen.new()
	fixture_screen.result = result
	session.complete_screen = fixture_screen
	session.add_child(fixture_screen)
	session.run_completed = true
	session.world.run_finished = true
	session.world.player.set_controls_enabled(false)
	session._seed_rng.seed = 20261006
	await test.reset(KEY_N)
	test.check(not is_instance_valid(fixture_screen) and not session.run_completed and session.floor_number == 1 and session.run_seed != run_seed and session.world.player.health.current_hp == 80 and session.world.player.relics.inventory.ids().is_empty() and session.bosses_defeated == 0, "N from complete starts fresh Seed/floor1/empty Build and frees screen")
	completed = true


func prepare_first_floor(_driver: RefCounted) -> void: pass


func prepare_second_floor(_driver: RefCounted) -> void: pass


func verify_result(_result: RunResult) -> void: pass
