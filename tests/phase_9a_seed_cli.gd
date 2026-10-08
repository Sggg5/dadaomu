extends SceneTree
## 独立进程验证真正--seed参数，不在同一进程假装修改OS参数。
var flow: GameFlow
func _initialize() -> void: run.call_deferred()

func frames(count: int) -> void:
	for index in range(count): await physics_frame
	await process_frame

func key_e() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = true
	root.push_input(event)

func run() -> void:
	var hub := "--mode=hub" in OS.get_cmdline_user_args()
	if not hub:
		var session := preload("res://scenes/main/dungeon_test.tscn").instantiate() as DungeonSession
		session.progressive_relics = false
		session.tomb = preload("res://tests/fixtures/legacy_two_floor_tomb.tres")
		root.add_child(session)
		await frames(3)
		var valid := session.run_seed == 52 and not session.hub_mode
		print("[SeedCLI solo] run=%d valid=%s" % [session.run_seed, valid])
		quit(0 if valid else 1)
		return
	flow = preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
	flow.progressive_relics = false
	flow.tomb = preload("res://tests/fixtures/legacy_two_floor_tomb.tres")
	flow.profile_store = MuseumProfileStore.in_memory()
	root.add_child(flow)
	await frames(3)
	preload("res://tests/expedition_map_fixture.gd").confirm(flow)
	await frames(4)
	var first := flow.dungeon.run_seed
	# CLI单位生命周期，用正式Health死亡回馆；真正战斗三日流程另有专项。
	flow.dungeon.world.player.health.take_damage(1000)
	await frames(2)
	key_e()
	await frames(4)
	preload("res://tests/expedition_map_fixture.gd").confirm(flow)
	await frames(4)
	var second := flow.dungeon.run_seed
	var valid := flow.museum_state.campaign_seed == 52 and flow.forced_night_seed == 0 and first == ExpeditionSeedService.derive(52, 1) and second == ExpeditionSeedService.derive(52, 2) and first != second and first != 52
	print("[SeedCLI hub] campaign=%d day1=%d day2=%d valid=%s" % [flow.museum_state.campaign_seed, first, second, valid])
	quit(0 if valid else 1)
