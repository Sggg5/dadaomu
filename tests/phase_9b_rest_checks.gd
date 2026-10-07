extends RefCounted
var test: SceneTree
func _init(context: SceneTree) -> void: test = context
func run() -> void:
	var session := preload("res://scenes/main/dungeon_test.tscn").instantiate() as DungeonSession
	session.exploration_enabled = false
	test.root.add_child(session)
	await test.frames(3)
	var player := session.world.player
	var state := RoomState.new()
	var rest := RestPoint.new()
	rest.player = player
	rest.room_state = state
	rest.amount = 15
	rest.position = player.position
	session.world.add_child(rest)
	await test.frames(1)
	test.check(player.health.max_hp == 80 and player.antiques.capacity == 8, "80HP and eight slots frozen")
	test.check(not rest.request() and not state.is_loot_claimed(&"rest_point"), "Full HP never consumes rest")
	player.health.restore(34)
	test.check(rest.request() and player.health.current_hp == 49 and state.is_loot_claimed(&"rest_point") and not rest.request(), "34+15=49 exactly once")
	await test.frames(2)
	for starting in [72, 34]:
		rest = RestPoint.new()
		rest.player = player
		rest.room_state = RoomState.new()
		rest.amount = 15 if starting == 72 else 20
		rest.position = player.position
		session.world.add_child(rest)
		player.health.restore(starting)
		test.check(rest.request() and player.health.current_hp == (80 if starting == 72 else 54), "Rest caps HP or restores Floor4 twenty")
		await test.frames(2)
	rest = RestPoint.new()
	rest.player = player
	rest.room_state = RoomState.new()
	rest.amount = 20
	rest.position = player.position
	session.world.add_child(rest)
	player.health.take_damage(1000)
	test.check(not rest.request() and not rest.room_state.is_loot_claimed(&"rest_point"), "Rest cannot resurrect dead player")
	session.queue_free()
	await test.frames(3)
