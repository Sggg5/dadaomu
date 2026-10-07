extends RefCounted
## 活跃敌人接入随机图：真实咬击、枪手发射、玩家弹丸击杀和物理过门。

const SESSION: PackedScene = preload("res://scenes/main/dungeon_test.tscn")
const BULLET: PackedScene = preload("res://scenes/enemies/enemy_projectile.tscn")
const MOVES: Array[StringName] = [&"move_up", &"move_right", &"move_down", &"move_left"]
var tree: SceneTree
var check: Callable
var capture: Callable
var session: DungeonSession


func _init(context: SceneTree, assertion: Callable, screenshot: Callable) -> void:
	tree = context
	check = assertion
	capture = screenshot


func frames(count: int) -> void:
	for frame in range(count):
		await tree.physics_frame
	await tree.process_frame


func count_players(node: Node) -> int:
	var count: int = int(node is Player)
	for child in node.get_children():
		count += count_players(child)
	return count


func shoot_enemy(enemy: Enemy) -> void:
	# 移动玩家到无遮挡的射击点，再从真实玩家位置发射；AI 保持活跃。
	for attempt in range(16):
		if not is_instance_valid(enemy) or enemy.health.is_dead or session.world.player.health.is_dead:
			break
		for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
			var origin: Vector2 = enemy.global_position + direction * 80
			var query := PhysicsRayQueryParameters2D.create(enemy.global_position, origin, 5, [enemy.get_rid()])
			if enemy.get_world_2d().direct_space_state.intersect_ray(query).is_empty() and Room.ROOM_RECT.grow(-20).has_point(origin):
				session.world.player.position = origin
				break
		var player := session.world.player
		var fired := player.weapon.try_attack(player.global_position, (enemy.global_position - player.global_position).normalized(), player.stats)
		check.call(fired, "Player fires at active " + str(enemy.definition.id))
		await frames(14)
	check.call(not is_instance_valid(enemy) or enemy.health.is_dead, "Active enemy defeated through Player weapon")


func enemy_bullet(room: Room, player: Player) -> EnemyProjectile:
	var request := AttackRequest.new()
	request.origin = Vector2(640, 550)
	request.direction = Vector2.RIGHT
	request.speed = 1.0
	request.damage = 12.0
	request.lifetime = 100.0
	var bullet := BULLET.instantiate() as EnemyProjectile
	room.projectiles.add_child(bullet)
	bullet.setup(request)
	bullet.track_player(player)
	return bullet


func walk(side: int, stop_on_entry: bool = false) -> void:
	var world := session.world
	world.player.position = world.current_room.get_entry_position(side)
	world.player.velocity = Vector2.ZERO
	await frames(2)
	Input.action_press(MOVES[side])
	var source_id := world.current_id
	var checked_entry: bool = false
	for frame in range(28):
		await frames(1)
		if world.current_id != source_id and not checked_entry:
			checked_entry = true
			var enemies := world.current_room.enemy_spawner.get_children()
			if not enemies.is_empty():
				check.call(enemies.all(func(enemy: Enemy) -> bool: return enemy.activation_remaining > 0.0 and enemy.velocity.is_zero_approx()), "Holding movement through a door retains destination entry protection")
			if stop_on_entry:
				break
	Input.action_release(MOVES[side])
	if not stop_on_entry:
		await frames(12)


func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	tree.root.push_input(event)


func run() -> void:
	session = SESSION.instantiate() as DungeonSession
	# 历史回归使用原主图夹具；Phase9A单独覆盖正式探索入口。
	session.exploration_enabled = false
	# 有限选择首个相邻房为混合 COMBAT 的 Seed，保持真实生成和过门链。
	var found: bool = false
	for candidate in range(100):
		var layout := DungeonGenerator.generate(candidate, session.config)
		var neighbor: DungeonRoom = layout.rooms[layout.rooms[layout.start_id].neighbors.values()[0]]
		if neighbor.room_type == RoomDefinition.Type.COMBAT and neighbor.definition.room_id == &"east":
			session.seed_value = candidate
			found = true
			break
	check.call(found, "Bounded Seed search finds adjacent mixed COMBAT")
	tree.root.add_child(session)
	tree.current_scene = session
	await frames(3)
	session._seed_rng.seed = 20261006
	var expected: Dictionary = {&"center": [4, 0], &"north": [6, 0], &"west": [0, 3], &"east": [4, 1], &"south": [3, 2]}
	for template in session.config.templates:
		var composition: Array[int] = [0, 0]
		var safe: bool = true
		for entry in template.spawns:
			composition[0 if entry.enemy_definition.id == &"scarab" else 1] += 1
			for side in range(4):
				safe = safe and entry.position.distance_to(session.world.current_room.get_entry_position(side)) >= 180.0
		check.call(composition == expected[template.room_id], "Unified composition for " + str(template.room_id))
		check.call(is_equal_approx(template.entry_grace_time, 0.35), "Template uses 0.35 second grace: " + str(template.room_id))
		check.call(safe, "Every spawn stays 180 pixels away from all entrances: " + str(template.room_id))
	var world := session.world
	check.call(world.current_id == &"START" and world.current_room.room_state.status == RoomState.Status.CLEARED and world.current_room.enemy_spawner.get_remaining() == 0 and world.current_room.enemy_spawner.get_child_count() == 0, "Initial START is CLEARED with zero enemies")
	check.call(not world.current_room.definition.spawns.is_empty() and not world.current_room.enemy_spawner.started and world.current_room.doors.values().all(func(door: Door) -> bool: return door.is_open), "START ignores populated template spawns and opens actual doors")
	var start_side: int = world.layout.rooms[world.current_id].neighbors.keys()[0]
	await walk(start_side, true)
	check.call(world.current_room.room_type == RoomDefinition.Type.COMBAT and world.current_room.enemy_spawner.get_remaining() > 0 and is_equal_approx(world.current_room.definition.entry_grace_time, 0.35), "Real Door leads from safe START into COMBAT with 0.35 second grace")
	var mixed_id := world.current_id
	var room := world.current_room
	var scarabs: Array[ScarabEnemy] = []
	var gunner: BanditShooter
	var original_enemies := room.enemy_spawner.get_children()
	for enemy in original_enemies:
		check.call(enemy is Enemy and enemy.target == world.player and enemy.projectile_parent == room.projectiles, "Spawner injects Player and local projectile parent")
		if enemy is ScarabEnemy:
			scarabs.append(enemy)
		elif enemy is BanditShooter:
			gunner = enemy
	check.call(scarabs.size() == 4 and gunner != null and room.enemy_spawner.get_remaining() == 5, "Random dungeon enters real mixed room")
	var cleared := [0]
	room.cleared.connect(func() -> void: cleared[0] += 1)
	capture.call("mixed_start")
	var spawn_positions: Array[Vector2] = []
	for enemy in original_enemies:
		spawn_positions.append(enemy.position)
	# 从实际剩余时间和物理频率推导等待帧数，不假设观察期为一秒。
	var remaining: float = original_enemies[0].activation_remaining
	await frames(maxi(1, floori(remaining * Engine.physics_ticks_per_second * 0.5)))
	var dormant: bool = world.player.health.current_hp == 80.0
	for index in range(original_enemies.size()):
		var enemy: Enemy = original_enemies[index]
		dormant = dormant and enemy.activation_remaining > 0.0 and enemy.velocity.is_zero_approx() and enemy.position == spawn_positions[index]
	check.call(dormant, "Entry observation period prevents movement and damage")
	check.call(gunner.shots_fired == 0 and room.projectiles.get_child_count() == 0 and original_enemies.all(func(enemy: Enemy) -> bool: return not enemy.telegraphing), "Observation period blocks attacks and windups")
	remaining = original_enemies[0].activation_remaining
	await frames(ceili(remaining * Engine.physics_ticks_per_second) + 4)
	check.call(original_enemies.all(func(enemy: Enemy) -> bool: return enemy.activation_remaining <= 0.0 and enemy.can_act()) and scarabs[0].position != spawn_positions[0], "AI resumes movement after configured grace expires")
	scarabs[0].position = world.player.position + Vector2(34, 0)
	await frames(18)
	check.call(world.player.health.current_hp < 80.0 and world.player.health.current_hp > 0.0, "Live random-room scarab attacks Player")
	await shoot_enemy(scarabs[0])
	check.call(room.enemy_spawner.get_remaining() == 4 and room.room_state.status == RoomState.Status.ACTIVE, "Enemy death updates remaining without early clear")
	gunner.position = world.player.position + Vector2(240, 0)
	# 清空余下尸蟞与枪手之间的干扰位置，保持 AI 活跃。
	scarabs[1].position = Vector2(240, 200)
	scarabs[2].position = Vector2(1040, 550)
	for frame in range(120):
		if gunner.shots_fired > 0:
			break
		await frames(1)
	check.call(gunner.shots_fired > 0 and room.projectiles.get_children().any(func(node: Node) -> bool: return node is EnemyProjectile), "Live random-room gunner fires readable enemy bullet")
	capture.call("mixed_shot")
	await shoot_enemy(gunner)
	for scarab in scarabs:
		if is_instance_valid(scarab):
			await shoot_enemy(scarab)
	await frames(14)
	check.call(world.player.health.current_hp > 0.0 and room.enemy_spawner.get_remaining() == 0 and cleared[0] == 1 and room.room_state.status == RoomState.Status.CLEARED, "Mixed active AI room clears exactly once")
	check.call(room.doors.values().all(func(door: Door) -> bool: return door.is_open), "Mixed room opens connected doors")
	room.enter()
	await frames(2)
	check.call(cleared[0] == 1 and room.enemy_spawner.get_child_count() == 0, "Repeated cleared enter does not spawn or clear twice")
	capture.call("mixed_cleared")
	var player_id := world.player.get_instance_id()
	var side: int = world.layout.rooms[world.current_id].neighbors.keys()[0]
	var destination := world.layout.rooms[world.current_id].neighbors[side]
	var old_bullet := enemy_bullet(room, world.player)
	await walk(side)
	check.call(world.current_id == destination and not is_instance_valid(room) and not is_instance_valid(old_bullet), "Physical door removes old Room and enemy projectile")
	check.call(original_enemies.all(func(enemy) -> bool: return not is_instance_valid(enemy)), "Old enemies cannot follow across rooms")
	check.call(world.player.get_instance_id() == player_id and count_players(tree.root) == 1, "Player instance remains unique across traversal")
	# 回房覆盖用 Health 加速邻居清场；此前混合房已通过活跃 AI 和真实弹丸。
	for enemy in world.current_room.enemy_spawner.get_children():
		enemy.take_damage(1000.0)
	await frames(14)
	await walk(Door.opposite(side))
	check.call(world.current_id == mixed_id and world.current_room.room_state.status == RoomState.Status.CLEARED and world.current_room.enemy_spawner.get_child_count() == 0, "Revisit CLEARED never respawns enemies")
	await walk(Door.opposite(start_side))
	check.call(world.current_id == &"START" and world.current_room.room_state.status == RoomState.Status.CLEARED and not world.current_room.enemy_spawner.started and world.current_room.enemy_spawner.get_child_count() == 0, "Revisit START stays safe without spawning")
	var signature := world.layout.signature()
	key(KEY_R)
	await frames(5)
	world = session.world
	check.call(world.layout.signature() == signature and world.player.health.current_hp == 80.0 and world.current_room.room_state.status == RoomState.Status.CLEARED and world.current_room.enemy_spawner.get_remaining() == 0 and not world.current_room.enemy_spawner.started, "R preserves Seed and restores safe START and HP")
	await walk(start_side, true)
	check.call(world.current_room.enemy_spawner.get_remaining() > 0, "R restart still generates combat enemies after leaving START")
	var deaths := [0]
	world.player.died.connect(func() -> void: deaths[0] += 1)
	old_bullet = enemy_bullet(world.current_room, world.player)
	var enemies := world.current_room.enemy_spawner.get_children()
	world.player.health.take_damage(1000.0)
	await frames(120)
	check.call(world.player.health.current_hp == 0.0 and deaths[0] == 1 and not world.player.take_damage(10.0), "Dead Player is never repeatedly settled or hurt")
	check.call(enemies.all(func(enemy: Enemy) -> bool: return not enemy.ai_enabled) and not is_instance_valid(old_bullet) and world.current_room.projectiles.get_child_count() == 0, "Player death stops every AI and cleans enemy bullets")
	check.call(not world.request_traversal(side), "Dead Player cannot traverse")
	capture.call("player_death")
	var previous_seed := session.seed_value
	key(KEY_N)
	await frames(5)
	world = session.world
	check.call(session.seed_value != previous_seed and world.player.health.current_hp == 80.0 and world.current_room.room_state.status == RoomState.Status.CLEARED and world.current_room.enemy_spawner.get_remaining() == 0 and not world.current_room.enemy_spawner.started and world.current_room.doors.values().all(func(door: Door) -> bool: return door.is_open) and count_players(tree.root) == 1, "N creates a different dungeon with safe open START")
	await walk(world.layout.rooms[world.current_id].neighbors.keys()[0], true)
	check.call(world.current_room.room_type == RoomDefinition.Type.COMBAT and world.current_room.enemy_spawner.get_remaining() > 0, "New Seed still generates combat enemies beyond safe START")
