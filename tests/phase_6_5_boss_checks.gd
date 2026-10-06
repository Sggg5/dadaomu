extends RefCounted
## 专项边界夹具可直接设状态/HP；完整两层实战由另一套件独立执行。
var test: SceneTree
var completed: bool = false
var world: RoomController
var room: Room
var boss: TombGuardianBeast
var player: Player


func _init(context: SceneTree) -> void: test = context


func arena() -> void:
	await test.reset()
	world = test.session.world
	world._switch_room(world.layout.boss_id,-1)
	test.check(world.current_room.boss_encounter.boss is WarlordBoss, "Floor1 still resolves original warlord scene")
	world.current_room.boss_encounter.boss.take_damage(845)
	test.session.request_next_floor()
	await test.frames(4)
	world = test.session.world
	world._switch_room(world.layout.boss_id,-1)
	room = world.current_room
	boss = room.boss_encounter.boss as TombGuardianBeast
	player = world.player
	quiet()


func quiet() -> void:
	boss.state = TombGuardianBeast.State.RECOVERY
	boss._timer = 999
	boss.position = Vector2(700,368)
	player.position = Vector2(400,368)
	player.health.restore(80)
	player.invulnerability_remaining = 0


func attacks(type: String) -> Array:
	return room.projectiles.get_children().filter(func(node: Node) -> bool: return node.is_class(type) if type == "Projectile" else ((node is TombSpike) if type == "spike" else (node is EnemyProjectile)))


func clean_attacks() -> void:
	room.discard_projectiles()
	await test.frames(3)


func run() -> void:
	await arena()
	var session: DungeonSession = test.session
	test.check(session.boss_for_floor(1).boss_scene != session.boss_for_floor(2).boss_scene and session.boss_for_floor(3) == null, "BossDefinition selects distinct scenes with no third-floor mapping")
	var encounter_code := FileAccess.get_file_as_string("res://scripts/bosses/boss_encounter.gd")
	test.check(not encounter_code.contains("definition.id") and not encounter_code.contains("warlord_boss.tscn"), "Generic Encounter contains no Boss ID or specific scene branch")
	test.check(boss != null and room.boss_encounter.get_child_count() == 1 and room.enemy_spawner.get_child_count() == 0 and not room.enemy_spawner.started, "Floor2 ignores template spawns and creates exactly one beast")
	room.enter()
	test.check(room.boss_encounter.get_child_count() == 1, "Repeated enter cannot duplicate beast")
	test.check(boss.definition.max_hp == 800 and boss.health.max_hp == 1040 and boss.definition.move_speed == 80, "Beast base HP800/Tier3 HP1040/speed80")
	test.check(world.hud.boss_display.visible and world.hud.boss_display.label.text.contains("镇墓兽") and room.room_state.status == RoomState.Status.ACTIVE and room.doors.values().all(func(door: Door) -> bool: return not door.is_open), "Beast HUD/name ACTIVE and locked Doors")
	test.check(CombatGeometry.targets(room).has(boss), "Beast naturally participates in Room.damage_targets")
	boss.position = Vector2(400,544)
	player.position = Vector2(600,544)
	boss._next_skill = 0
	boss._begin_skill()
	var recorded := boss.pounce_target
	await test.frames(20)
	test.check(boss.state == TombGuardianBeast.State.POUNCE_WINDUP and boss.beast_data.pounce_windup == .7 and recorded == Vector2(600,544), "Pounce warns .7s and snapshots target at start")
	test.capture("beast_pounce_warning")
	player.position = Vector2(850,544)
	await test.frames(50)
	test.check(boss.pounce_target == recorded and boss.position.distance_to(recorded) < 1, "Pounce reaches fixed recorded point after Player moves")
	test.check(player.health.current_hp == 80, "Moving out of landing radius avoids pounce")
	quiet()
	boss.position = Vector2(500,544)
	player.position = Vector2(550,544)
	boss.pounce_target = player.position
	boss._pounce_velocity = Vector2(300,0)
	boss.state = TombGuardianBeast.State.POUNCE
	boss._timer = .35
	await test.frames(30)
	test.check(player.health.current_hp == 53 and boss.state == TombGuardianBeast.State.RECOVERY, "Inside90px landing takes scaled27 once, not every frame")
	quiet()
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	wall.collision_mask = 0
	wall.position = Vector2(600,544)
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(1,96)
	collider.shape = shape
	wall.add_child(collider)
	room.add_child(wall)
	# 等待物理服务器登记静态体；图形捕获与无窗口模式都使用相同夹具。
	await test.frames(3)
	boss.position = Vector2(550,544)
	player.position = Vector2(650,544)
	await test.frames(1)
	boss.pounce_target = player.position
	boss._pounce_velocity = Vector2(400,0)
	boss.state = TombGuardianBeast.State.POUNCE
	boss._timer = .35
	await test.frames(12)
	print("[Pounce wall fixture] state=%d boss=%s player=%s distance=%.3f HP=%.1f LOS=%s" % [boss.state,boss.position,player.position,boss.position.distance_to(player.position),player.health.current_hp,boss.has_line_to_target()])
	test.check(boss.state == TombGuardianBeast.State.RECOVERY and boss.position.x < 600 and boss.position.distance_to(player.position) < 90 and player.health.current_hp == 80, "Obstacle stops pounce; landing never damages Player through wall")
	wall.queue_free()
	quiet()
	await clean_attacks()
	boss.roar_direction = Vector2.RIGHT
	boss._roar()
	var bullets := attacks("bullet")
	test.check(bullets.size() == 5, "Normal roar creates five EnemyProjectiles")
	var angles: Array[int] = [-30,-15,0,15,30]
	for index in range(bullets.size()):
		test.check(is_equal_approx(rad_to_deg(bullets[index].velocity.angle()),angles[index]) and is_equal_approx(bullets[index].damage,18.9) and is_equal_approx(bullets[index].velocity.length(),320) and bullets[index].remaining_lifetime == 3, "Roar angle/damage/speed/lifetime " + str(index))
	var fixed: Vector2 = bullets[2].velocity
	player.position = Vector2(300,208)
	await test.frames(4)
	test.check(is_instance_valid(bullets[2]) and bullets[2].velocity == fixed, "Roar projectiles never home after Player moves")
	var wall_bullet: EnemyProjectile = bullets[2]
	wall_bullet.position = Vector2(1200,544)
	await test.frames(8)
	test.check(not is_instance_valid(wall_bullet), "Roar projectile is destroyed by World wall")
	await clean_attacks()
	quiet()
	boss._next_skill = 1
	boss._begin_skill()
	await test.frames(30)
	test.check(boss.state == TombGuardianBeast.State.ROAR_WINDUP and boss.beast_data.roar_windup == .75, "Roar retains .75s directional windup")
	test.capture("beast_roar_warning")
	player.position = Vector2(1000,368)
	await test.frames(18)
	test.check(boss.roar_direction.is_equal_approx(Vector2.RIGHT), "Roar locks direction at windup completion")
	await clean_attacks()
	quiet()
	player.position = Vector2(640,368)
	boss._spikes()
	var spikes := attacks("spike")
	test.check(spikes.size() == 3 and spikes[0].global_position == player.global_position, "Normal fixed Pattern creates three warning points including Player snapshot")
	test.capture("beast_spike_warning")
	await test.frames(40)
	test.check(player.health.current_hp == 80 and not spikes[0].erupted and spikes[0].warning == .75, "Spike warning .75s never hurts before eruption")
	await test.frames(7)
	test.check(is_equal_approx(player.health.current_hp,55.7) and spikes[0].erupted, "Spike within55 deals scaled24.3 once")
	test.capture("beast_spike_eruption")
	await test.frames(20)
	test.check(is_equal_approx(player.health.current_hp,55.7) and not is_instance_valid(spikes[0]), "Spike does not repeat damage and releases after .25s visual")
	quiet()
	player.position = Vector2(640,368)
	boss._spikes()
	player.position = Vector2(1000,544)
	await test.frames(65)
	test.check(player.health.current_hp == 80, "Outside spike radius avoids damage")
	test.check(not boss.rage and boss.rage_entries == 0, "Above50% remains normal")
	boss.health.restore(520)
	boss.health.restore(400)
	test.check(boss.rage and boss.rage_entries == 1 and room.boss_encounter.summons.is_empty(), "First half HP triggers Rage once without summoning enemies")
	quiet()
	boss._decide()
	test.check(boss._timer == .8 and boss.beast_data.pounce_windup == .7 and boss.beast_data.roar_windup == .75 and boss.beast_data.spike_windup == .8, "Rage decision .8s; all skill windups unchanged")
	quiet()
	boss.roar_direction = Vector2.RIGHT
	boss._roar()
	bullets = attacks("bullet")
	test.check(bullets.size() == 7, "Rage roar has seven projectiles")
	angles = [-36,-24,-12,0,12,24,36]
	for index in range(bullets.size()): test.check(is_equal_approx(rad_to_deg(bullets[index].velocity.angle()),angles[index]), "Rage fan angle " + str(index))
	player.position = Vector2(640,368)
	boss._spikes()
	spikes = attacks("spike")
	test.check(spikes.size() == 5, "Rage has five spike warnings")
	var settlements := {"count":0}
	room.boss_encounter.defeated.connect(func() -> void: settlements.count += 1)
	boss.take_damage(500)
	boss.take_damage(500)
	await test.frames(3)
	test.check(settlements.count == 1 and room.room_state.status == RoomState.Status.CLEARED and room.doors.values().all(func(door: Door) -> bool: return door.is_open), "Beast death settles once, clears Room, opens Doors")
	test.check(not world.hud.boss_display.visible and room.projectiles.get_child_count() == 0 and spikes.all(func(node) -> bool: return not is_instance_valid(node)), "Boss death hides HUD and clears all bullets/pending spikes")
	test.check(not room.has_node("FloorExit") and room.get_node_or_null("RunExit") is RunExit and not session.run_completed, "Victory offers RunExit, no FloorExit; Run is not complete until E")
	await arena()
	player.position = Vector2(640,368)
	boss._spikes()
	spikes = attacks("spike")
	player.health.take_damage(80)
	await test.frames(60)
	test.check(spikes.all(func(node) -> bool: return not is_instance_valid(node)) and not boss.ai_enabled and not world.hud.boss_display.visible, "Player death cancels pending spikes/AI/HUD without late damage")
	completed = true
