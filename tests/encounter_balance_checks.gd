extends RefCounted
## 参数、几何和真实实例伤害；不改共享定义，不用AI读取地图。
const SCARAB = preload("res://scenes/enemies/scarab_enemy.tscn")
const SHOOTER = preload("res://scenes/enemies/bandit_shooter.tscn")
const SCARAB_DATA: EnemyDefinition = preload("res://data/enemies/scarab.tres")
const SHOOTER_DATA: RangedEnemyDefinition = preload("res://data/enemies/bandit_shooter.tres")
var test: SceneTree
var completed: bool = false


func _init(context: SceneTree) -> void:
	test = context


func run() -> void:
	test.check(SCARAB_DATA.max_hp == 65.0 and SCARAB_DATA.move_speed == 175.0 and SCARAB_DATA.contact_damage == 14.0 and SCARAB_DATA.attack_cooldown == 0.8 and SCARAB_DATA.windup_time == 0.25, "Scarab official base HP/speed/damage/cooldown/windup updated")
	test.check(SHOOTER_DATA.max_hp == 90.0 and SHOOTER_DATA.move_speed == 105.0 and SHOOTER_DATA.projectile_damage == 16.0 and SHOOTER_DATA.projectile_speed == 380.0 and SHOOTER_DATA.attack_cooldown == 1.20 and SHOOTER_DATA.windup_time == 0.4, "Shooter official parameters updated without reducing windup")
	var expected: Dictionary = {&"center": [4,0], &"north": [6,0], &"west": [0,3], &"east": [4,1], &"south": [3,2]}
	var world: RoomController = test.session.world
	for template in test.session.config.templates:
		var counts: Array[int] = [0,0]
		var safe: bool = true
		for entry in template.spawns:
			counts[0 if entry.enemy_definition.id == &"scarab" else 1] += 1
			for side in range(4):
				safe = safe and entry.position.distance_to(world.current_room.get_entry_position(side)) >= 180.0
			for rect in template.obstacles:
				safe = safe and not rect.grow(16).has_point(entry.position)
			for other in template.spawns:
				if other != entry:
					safe = safe and entry.position.distance_to(other.position) >= 40.0
			safe = safe and Room.ROOM_RECT.grow(-16).has_point(entry.position)
		test.check(counts == expected[template.room_id] and is_equal_approx(template.entry_grace_time, 0.35), "Updated composition and grace: " + str(template.room_id))
		test.check(safe, "All spawns include new point: entry180/obstacle16/actor40 safety " + str(template.room_id))
	var player := world.player
	test.check(player.stats.max_hp == 80.0 and player.stats.hurt_invulnerability == 0.25 and player.stats.move_speed == 240.0 and player.stats.attack_damage == 20.0, "Player survival changes to 80 HP / 0.25s without altering movement or attack")
	player.invulnerability_remaining = 0.0
	test.check(player.take_damage(1.0) and player.invulnerability_remaining > 0.0 and not player.take_damage(1.0), "Effective injury starts readable red flash and rejects immediate repeats")
	await test.frames(4)
	test.check(not player.take_damage(1.0), "Repeats inside 0.25 seconds remain blocked")
	await test.frames(ceili(player.invulnerability_remaining * Engine.physics_ticks_per_second) + 2)
	test.check(player.take_damage(1.0), "Damage becomes effective again after 0.25 seconds")
	# 保存PNG可能导致物理时钟追帧，因此放在无敌时间断言之后。
	await test.frames(2)
	test.capture("lethality_hurt")
	for depth in [1,2,3,4,5,8]:
		var difficulty := EncounterDifficulty.from_depth(depth)
		var hp_scale: float = 1.0 if depth < 3 else (1.15 if depth < 5 else 1.3)
		var damage_scale: float = 1.0 if depth < 3 else (1.15 if depth < 5 else 1.35)
		test.check(difficulty.hp_multiplier == hp_scale and difficulty.damage_multiplier == damage_scale, "Tier mapping for depth %d" % depth)
		player.health.initialize(80.0)
		player.invulnerability_remaining = 0.0
		player.position = Vector2(640,368)
		var scarab := SCARAB.instantiate() as ScarabEnemy
		scarab.position = Vector2(674,368)
		scarab.configure_spawn(player, world.current_room.projectiles, SCARAB_DATA, difficulty)
		world.current_room.enemy_spawner.add_child(scarab)
		test.check(is_equal_approx(scarab.health.max_hp, 65.0 * hp_scale), "Actual scarab HP at depth %d" % depth)
		await test.frames(18)
		test.check(is_equal_approx(player.health.current_hp, 80.0 - 14.0 * damage_scale), "Actual timed bite uses damage tier at depth %d" % depth)
		scarab.queue_free()
		await test.frames(2)
		var shooter := SHOOTER.instantiate() as BanditShooter
		shooter.position = Vector2(880,368)
		shooter.configure_spawn(player, world.current_room.projectiles, SHOOTER_DATA, difficulty)
		world.current_room.enemy_spawner.add_child(shooter)
		test.check(is_equal_approx(shooter.health.max_hp, 90.0 * hp_scale), "Actual gunner HP at depth %d" % depth)
		await test.frames(27)
		var bullet: EnemyProjectile
		for node in world.current_room.projectiles.get_children():
			if node is EnemyProjectile: bullet = node
		test.check(bullet != null and is_equal_approx(bullet.damage, 16.0 * damage_scale) and is_equal_approx(bullet.velocity.length(), 380.0), "Actual gunner shot scales damage but keeps speed at depth %d" % depth)
		test.check(scarab == null or not is_instance_valid(scarab), "Old melee actor released before next tier")
		shooter.queue_free()
		world.current_room.discard_projectiles()
		await test.frames(2)
	test.check(SCARAB_DATA.max_hp == 65.0 and SCARAB_DATA.contact_damage == 14.0 and SHOOTER_DATA.max_hp == 90.0 and SHOOTER_DATA.projectile_damage == 16.0, "Shared enemy resources remain pristine after all tiers")
	player.health.initialize(80.0)
	player.invulnerability_remaining = 0.0
	completed = true
