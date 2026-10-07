extends RefCounted
var test: SceneTree


func _init(context: SceneTree) -> void: test = context


func resource_values(data: Resource) -> Dictionary:
	var values: Dictionary = {"path":data.resource_path}
	for property in data.get_property_list():
		if (property.usage & PROPERTY_USAGE_STORAGE) == 0: continue
		var value: Variant = data.get(property.name)
		if value is int or value is float or value is bool or value is String or value is StringName: values[str(property.name)] = value
		elif value is Resource: values[str(property.name)] = value.resource_path
		elif value is Dictionary: values[str(property.name)] = value.duplicate(true)
	return values


func snapshot(session: DungeonSession) -> Dictionary:
	var player := session.world.player
	var stats: Dictionary = {}
	for key in ["max_hp","move_speed","attack_damage","attack_speed","projectile_speed","hurt_invulnerability"]: stats[key] = player.stats.get(key)
	var offers: Array[String] = []
	for floor in [1,2]:
		var layout := session.world.layout if floor == 1 else session.next_floor_layout()
		for offer in preload("res://tests/phase_7b_plan_checks.gd").offers(session.run_seed,floor,layout): offers.append("%d|%s|%s" % [floor,offer.room,offer.definition.id])
	var bosses: Array[Dictionary] = []
	for floor in [1,2]: bosses.append(resource_values(session.boss_for_floor(floor)))
	var enemies: Array[Dictionary] = []
	for template in session.config.templates:
		for spawn in template.spawns: enemies.append(resource_values(spawn.enemy_definition))
	var relics: Array[Dictionary] = []
	for item in session.rewards.sequence: relics.append(resource_values(item))
	return {"stats":stats,"actual_player_hp":player.health.max_hp,"inventory_capacity":player.antiques.capacity,"layout":session.world.layout.signature(),"floor2":session.next_floor_layout().signature(),"drops":offers,"bosses":bosses,"enemies":enemies,"relics":relics}


func run() -> void:
	var baseline: Dictionary
	for level in [0,1,2]:
		var flow := preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
		flow.profile_store = MuseumProfileStore.in_memory()
		var state := MuseumState.new()
		state.museum_level = level
		flow.profile_store.save_profile(state)
		test.root.add_child(flow)
		await test.frames(3)
		flow.start_night()
		await test.frames(5)
		var actual := snapshot(flow.dungeon)
		test.check(flow.dungeon.world.player.health.max_hp == 80 and flow.dungeon.world.player.antiques.capacity == 8 and not actual.stats.has("museum_level"),"Night starts with80HP/eight slots and no museum stats")
		if level == 0: baseline = actual
		test.check(actual == baseline,"Museum level%d cannot alter Player/backpack/enemies/Boss/relics/drops/Seed" % level)
		flow.queue_free()
		await test.frames(3)
