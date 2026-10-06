extends RefCounted
## 独立行为检查使用真实物理帧、Player 和现有 Health，不直接调用 AI 的攻击结算。

const SCARAB: PackedScene = preload("res://scenes/enemies/scarab_enemy.tscn")
const SHOOTER: PackedScene = preload("res://scenes/enemies/bandit_shooter.tscn")
const PLAYER: PackedScene = preload("res://scenes/player/player.tscn")

var tree: SceneTree
var check: Callable
var capture: Callable
var host: Node2D
var player: Player
var room: Room


func _init(context: SceneTree, assertion: Callable, screenshot: Callable) -> void:
	tree = context
	check = assertion
	capture = screenshot


func frames(count: int) -> void:
	for frame in range(count):
		await tree.physics_frame
	await tree.process_frame


func spawn(scene: PackedScene, position: Vector2) -> Enemy:
	var enemy := scene.instantiate() as Enemy
	enemy.position = position
	enemy.configure_spawn(player, room.projectiles)
	room.enemy_spawner.add_child(enemy)
	return enemy


func reset_hp() -> void:
	player.health.initialize(player.stats.max_hp)
	player.invulnerability_remaining = 0.0


func setup() -> void:
	host = Node2D.new()
	tree.root.add_child(host)
	player = PLAYER.instantiate() as Player
	host.add_child(player)
	player.position = Vector2(640, 368)
	room = RoomController.ROOM_SCENE.instantiate() as Room
	room.configure(RoomDefinition.new(), RoomState.new(), [], RoomDefinition.Type.COMBAT, player)
	host.add_child(room)
	host.move_child(player, host.get_child_count() - 1)
	room.enter()
	await frames(3)


func melee() -> void:
	var scarab := spawn(SCARAB, Vector2(850, 368)) as ScarabEnemy
	check.call(scarab.definition.id == &"scarab" and scarab.definition.display_name == "尸蟞" and scarab.health.current_hp == scarab.definition.max_hp, "Scarab spawns and reads definition")
	var original_distance := scarab.position.distance_to(player.position)
	await frames(20)
	check.call(scarab.position.distance_to(player.position) < original_distance - 30, "Scarab actively pursues Player")
	check.call(player.health.current_hp == 100.0, "Scarab cannot hurt from far away")
	scarab.position = player.position + Vector2(34, 0)
	await frames(3)
	check.call(scarab.telegraphing and player.health.current_hp == 100.0, "Scarab shows windup before damage")
	capture.call("scarab_windup")
	await frames(14)
	check.call(player.health.current_hp == 88.0, "Scarab bite uses Player.take_damage")
	await frames(12)
	check.call(player.health.current_hp == 88.0, "Melee cooldown prevents per-frame damage")
	check.call(not player.take_damage(10.0) and player.health.current_hp == 88.0, "Existing Player invulnerability remains effective")
	await frames(65)
	check.call(player.health.current_hp == 76.0, "Scarab attacks again after cooldown")
	for frame in range(100):
		if scarab.state == ScarabEnemy.State.WINDUP:
			break
		await frames(1)
	var hp := player.health.current_hp
	player.position = Vector2(460, 240)
	await frames(18)
	check.call(player.health.current_hp == hp, "Leaving windup range avoids bite")
	scarab.queue_free()
	await frames(2)
	reset_hp()
	player.position = Vector2(640, 368)
	var first := spawn(SCARAB, player.position + Vector2(34, 0))
	var second := spawn(SCARAB, player.position - Vector2(34, 0))
	await frames(18)
	check.call(player.health.current_hp == 88.0, "Simultaneous bites respect invulnerability, not instant burst death")
	first.queue_free()
	second.queue_free()
	await frames(2)
	reset_hp()


func ranged() -> BanditShooter:
	var shooter := spawn(SHOOTER, Vector2(1050, 368)) as BanditShooter
	check.call(shooter.definition.id == &"bandit_shooter" and shooter.ranged != null and shooter.health.max_hp == 90.0, "Shooter spawns and reads ranged definition")
	var original_distance := shooter.position.distance_to(player.position)
	await frames(20)
	check.call(shooter.position.distance_to(player.position) < original_distance - 20, "Shooter approaches from far range")
	shooter.position = player.position + Vector2(120, 0)
	await frames(15)
	check.call(shooter.position.distance_to(player.position) > 130.0 and shooter.shots_fired == 0, "Shooter retreats when Player is too close")
	shooter.position = player.position + Vector2(240, 0)
	await frames(3)
	check.call(shooter.telegraphing and shooter.shots_fired == 0 and shooter.velocity.is_zero_approx(), "Shooter stops with visible aiming windup")
	capture.call("shooter_windup")
	await frames(24)
	check.call(shooter.shots_fired == 1 and room.projectiles.get_child_count() == 1, "Shooter emits enemy projectile")
	var bullet := room.projectiles.get_child(0) as EnemyProjectile
	var velocity := bullet.velocity
	check.call(shooter.last_shot_direction.is_equal_approx((player.position - shooter.position).normalized()), "Shot direction snapshots Player position at firing")
	player.position += Vector2(0, 132)
	await frames(12)
	check.call(is_instance_valid(bullet) and bullet.velocity.is_equal_approx(velocity) and is_equal_approx(bullet.position.y, 368.0), "Moving Player does not home an already fired projectile")
	shooter.stop_ai()
	room.discard_projectiles()
	await frames(2)
	return shooter


func player_damage_and_death(shooter: BanditShooter) -> void:
	var scarab := spawn(SCARAB, Vector2(850, 300))
	scarab.stop_ai()
	for enemy in [scarab, shooter]:
		var hp: float = enemy.health.current_hp
		var request := AttackRequest.new()
		request.origin = enemy.global_position - Vector2(0, 48)
		request.direction = Vector2.DOWN
		request.damage = player.stats.attack_damage
		request.speed = player.stats.projectile_speed
		request.lifetime = 2.0
		var bullet := RoomController.PROJECTILE_SCENE.instantiate() as Projectile
		room.projectiles.add_child(bullet)
		bullet.setup(request)
		await frames(4)
		check.call(enemy.health.current_hp == hp - player.stats.attack_damage, "Player projectile damages " + str(enemy.definition.id))
		check.call(enemy._flash_remaining > 0.0, "Hit flash visible for " + str(enemy.definition.id))
	capture.call("hit_feedback")
	var deaths := [0]
	scarab.killed.connect(func() -> void: deaths[0] += 1)
	scarab.take_damage(1000.0)
	check.call(scarab.dying and not scarab.take_damage(1.0) and deaths[0] == 1, "Zero HP triggers death once and stops receiving damage")
	await frames(1)
	check.call(is_instance_valid(scarab) and scarab.scale.x < 1.0, "Death remains briefly with flash and shrink")
	capture.call("death_feedback")
	await frames(14)
	check.call(not is_instance_valid(scarab) and deaths[0] == 1, "Enemy releases after death feedback")
