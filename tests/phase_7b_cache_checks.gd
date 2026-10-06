extends RefCounted
var test: SceneTree
var completed: bool = false


func _init(context: SceneTree) -> void: test = context


func run() -> void:
	var world: RoomController = test.session.world
	var signature := world.antique_loot.selected_rooms.duplicate()
	var context := RoomClearContext.new()
	context.room_id = &"fixture_prior_clear"
	context.room_type = RoomDefinition.Type.COMBAT
	context.was_combat = true
	test.session.rewards.on_room_cleared(context)
	var id := world.antique_loot.selected_rooms[0]
	world._switch_room(id,-1)
	test.check(not world.current_room.has_node("AntiqueCache"), "Selected COMBAT has no cache before CLEARED")
	for actor in world.current_room.enemy_spawner.get_children(): actor.take_damage(actor.health.max_hp)
	await test.frames(3)
	var cache := world.current_room.get_node("AntiqueCache") as AntiqueCache
	var relic := world.current_room.get_node("RelicPedestal") as RelicPedestal
	test.check(world.current_room.room_state.status == RoomState.Status.CLEARED and cache != null and relic != null and cache.position.distance_to(relic.position) >= 160, "Cache after clear coexists with separated RelicPedestal")
	await test.frames(2)
	test.capture("dual_loot")
	world.player.position = relic.position+Vector2(24,0)
	test.key(KEY_E)
	test.check(relic.claimed and world.player.relics.inventory.has(relic.definition.id), "Actual E can claim relic separately in same cache room")
	var progress: int = test.session.rewards.combat_clears
	var clears: int = test.contexts.size()
	world.player.position = cache.position+Vector2(100,0)
	test.check(not cache.try_pickup(), "Cache outside64px refuses E")
	var definition := cache.definition
	for index in range(8): world.player.antiques.add(preload("res://data/antiques/republic_silver_coin.tres"))
	world.player.position = cache.position
	test.key(KEY_E)
	test.check(not world.current_room.room_state.is_loot_claimed(&"combat_cache") and cache.label.text.contains("背包空间不足"), "Full bag cache E refuses without consuming source")
	await test.walk(world.layout.rooms[id].neighbors.keys()[0])
	world._switch_room(id,-1)
	await test.frames(2)
	cache = world.current_room.get_node("AntiqueCache") as AntiqueCache
	test.check(cache.definition == definition, "Unclaimed cache returns same Definition after actual Door exit")
	clears = test.contexts.size()
	world.player.antiques.clear()
	world.player.position = cache.position
	test.capture("cache_revisit")
	test.key(KEY_E)
	test.check(world.current_room.room_state.is_loot_claimed(&"combat_cache") and not cache.try_pickup() and world.player.antiques.items() == [definition], "Real E cache pickup claims source once")
	world.player.antiques.remove_at(0)
	world._switch_room(world.layout.start_id,-1)
	world._switch_room(id,-1)
	await test.frames(2)
	test.check(not world.current_room.has_node("AntiqueCache"), "Claimed then discarded cache never respawns")
	test.check(test.session.rewards.combat_clears == progress and test.contexts.size() == clears and world.states[id].status == RoomState.Status.CLEARED, "Cache pickup/revisit never adds clear or relic progress")
	for other in world.layout.rooms:
		if world.layout.rooms[other].room_type == RoomDefinition.Type.COMBAT and not world.antique_loot.has_cache(other):
			world._switch_room(other,-1)
			for actor in world.current_room.enemy_spawner.get_children(): actor.take_damage(actor.health.max_hp)
			await test.frames(2)
			test.check(not world.current_room.has_node("AntiqueCache"), "Unselected COMBAT never spawns cache even when cleared")
			break
	await test.reset(KEY_R)
	test.check(test.session.world.antique_loot.selected_rooms == signature, "R same Seed repeats same cache selection")
	completed = true
