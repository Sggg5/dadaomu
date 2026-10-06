extends RefCounted
var test: SceneTree
var arena: RefCounted
var completed: bool = false


func _init(context: SceneTree, helpers: RefCounted) -> void:
	test = context
	arena = helpers


func burn_on(enemy: Enemy) -> Burn:
	for child in enemy.get_children():
		if child is Burn and not child.cancelled:
			return child
	return null


func run() -> void:
	var player: Player = test.session.world.player
	var inventory := player.relics.inventory
	inventory.add(arena.definition(&"corpse_oil_lamp"))
	var a: Enemy = arena.enemy(Vector2(850, 368))
	arena.fire()
	await arena.until_hit(a)
	var burn := burn_on(a)
	test.check(burn != null and burn.ticks_left == 3, "Oil lamp creates one lightweight three-tick burn")
	test.capture("burn")
	await test.frames(66)
	test.check(a.health.current_hp == 171.0 and not is_instance_valid(burn), "Burn applies exactly three damage-three ticks then releases")
	await arena.clean()
	inventory.add(arena.definition(&"corpse_oil_lamp"))
	a = arena.enemy(Vector2(850, 368))
	arena.fire()
	await arena.until_hit(a)
	burn = burn_on(a)
	var burn_id := burn.get_instance_id()
	await test.frames(22)
	arena.fire(Vector2(780, 368))
	await test.frames(9)
	test.check(burn_on(a).get_instance_id() == burn_id and burn.ticks_left == 3 and a.get_children().filter(func(node: Node) -> bool: return node is Burn).size() == 1, "Another hit refreshes duration and ticks instead of stacking burn nodes")
	await test.frames(66)
	test.check(a.health.current_hp == 148.0, "Refresh produces one old tick plus three refreshed ticks without unbounded DOT")
	await arena.clean()
	inventory.add(arena.definition(&"five_emperor_coins"))
	inventory.add(arena.definition(&"corpse_oil_lamp"))
	var origin := Vector2(640, 368)
	a = arena.enemy(origin + Vector2.RIGHT.rotated(deg_to_rad(-5.0)) * 210)
	var b: Enemy = arena.enemy(origin + Vector2.RIGHT.rotated(deg_to_rad(5.0)) * 210)
	arena.fire()
	await test.frames(24)
	test.check(burn_on(a) != null and burn_on(b) != null and burn_on(a) != burn_on(b), "Coins plus oil lamp naturally ignite separate enemies with independent burns")
	test.capture("dual_burn")
	await test.frames(66)
	test.check(a.health.current_hp == 175.0 and b.health.current_hp == 175.0, "Both targets independently receive scaled shot plus full burn damage")
	await arena.clean()
	inventory.add(arena.definition(&"corpse_oil_lamp"))
	a = arena.enemy(Vector2(850, 368))
	arena.fire()
	await arena.until_hit(a)
	var hp := a.health.current_hp
	inventory.remove(&"corpse_oil_lamp")
	await test.frames(66)
	test.check(a.health.current_hp == hp and burn_on(a) == null and player.relics.projectile_hit.get_connections().size() == 1, "Removing oil lamp cancels active DOT and removes its hit connection")
	await arena.clean()
	completed = true
