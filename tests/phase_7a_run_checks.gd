extends "res://tests/phase_6_5_run_checks.gd"
## 在已回归的真实两层流程插入真实古董房/Door/E，不用Inventory.add代替主流程。
var first: AntiqueDefinition
var collected: Array[AntiqueDefinition] = []
var first_inventory: AntiqueInventory
var first_panel: AntiqueInventoryPanel


func take_antique(driver: RefCounted) -> AntiqueDefinition:
	var world: RoomController = test.session.world
	await driver.visit(world.layout.antique_id)
	var room := world.current_room
	var pedestal := room.get_node("AntiquePedestal") as AntiquePedestal
	test.check(room.remaining_count() == 0 and room.room_state.status == RoomState.Status.CLEARED and room.doors.values().all(func(door: Door) -> bool: return door.is_open), "Actual ANTIQUE is safe and every real Door remains open")
	world.player.position = pedestal.position+Vector2(100,0)
	test.check(not pedestal.try_pickup(), "Antique pedestal refuses interaction beyond64px")
	var item := pedestal.definition
	world.player.position = pedestal.position+Vector2(24,0)
	await test.frames(1)
	test.capture("antique_floor_%d" % test.session.floor_number)
	test.key(KEY_E)
	test.check(room.room_state.antique_claimed and not pedestal.try_pickup() and world.player.antiques.items().has(item), "Real E picks antique once through independent Inventory")
	await test.frames(3)
	test.check(not is_instance_valid(pedestal) and world.hud.antique_label.text.contains("%d / 8格" % world.player.antiques.used_slots()) and world.hud.antique_label.text.contains(AntiqueDefinition.money(world.player.antiques.total_value())), "Pickup releases and live HUD displays actual slots/value")
	collected.append(item)
	return item


func prepare_first_floor(driver: RefCounted) -> void:
	first = await take_antique(driver)
	first_inventory = test.session.world.player.antiques
	first_panel = test.session.world.antique_panel
	# 正常拾取后重访已清房，不得重复生成；之后仍继续原真实战斗和Boss流程。
	await test.walk(test.session.world.layout.rooms[test.session.world.current_id].neighbors.keys()[0])
	await driver.visit(test.session.world.layout.antique_id)
	test.check(not test.session.world.current_room.has_node("AntiquePedestal"), "Claimed antique never respawns on real Door revisit")


func prepare_second_floor(driver: RefCounted) -> void:
	test.check(test.session.world.player.antiques.items() == [first], "First-floor antique survives actual Boss/FloorExit transition")
	test.check(test.session.world.player.antiques != first_inventory and not is_instance_valid(first_panel), "Next floor creates new inventory/UI and releases old panel")
	await take_antique(driver)
	test.check(test.session.world.player.antiques.items() == collected and collected.size() == 2, "Second floor generates and E picks another antique")
	var panel: AntiqueInventoryPanel = test.session.world.antique_panel
	test.key(KEY_TAB)
	test.check(panel.panel.visible and panel.list.item_count == 2 and panel.header.text.contains(str(test.session.world.player.antiques.used_slots())), "Real Tab opens Panel showing both actual collected antiques")
	await test.frames(2)
	test.capture("carried_antique_panel")
	test.key(KEY_TAB)


func verify_result(result: RunResult) -> void:
	var expected: int = 0
	for item in collected:
		expected += item.base_value
		test.check(result.antique_names.has(item.display_name) and test.session.complete_screen.label.text.contains(item.display_name), "Complete screen displays carried antique " + item.display_name)
	test.check(result.antique_names.size() == 2 and result.antique_value == expected and test.session.complete_screen.label.text.contains("古董总估值："+AntiqueDefinition.money(expected)), "Complete snapshots/display exactly two carried antiques and total value")


func run() -> void:
	await super.run()
	test.check(completed and test.session.world.player.antiques.items().is_empty(), "Full run ends with N creating empty antique inventory")
