extends RefCounted
## 可直接设HP/状态的单项边界；完整击杀另由Floor检查使用真实弹丸。
var test: SceneTree
var completed: bool = false
var deaths: int = 0


func _init(context: SceneTree) -> void: test = context


func run() -> void:
	var world: RoomController = test.session.world
	var node := world.layout.rooms[world.layout.boss_id]
	var deepest: int = 0
	for item in world.layout.rooms.values(): deepest = maxi(deepest, item.distance_from_start)
	test.check(node.neighbors.size() == 1 and node.distance_from_start == deepest, "BOSS remains deepest leaf")
	test.check(not test.session.request_next_floor(), "No floor advance before Boss victory")
	world._switch_room(world.layout.boss_id, -1)
	await test.frames(2)
	var room := world.current_room
	var encounter := room.boss_encounter
	var boss := encounter.boss as WarlordBoss
	var player := world.player
	var data := boss.boss_data
	test.check(not room.enemy_spawner.started and room.enemy_spawner.get_child_count() == 0 and room.definition.spawns.size() > 0, "Formal BOSS ignores nonempty template spawns")
	test.check(encounter.get_child_count() == 1 and boss is WarlordBoss, "Exactly one formal Boss")
	room.enter()
	test.check(room.boss_encounter == encounter and encounter.get_child_count() == 1, "Repeated ACTIVE enter never duplicates BossEncounter or Boss")
	test.check(data.id == &"jinbei_warlord_corpse" and data.display_name == "晋北大帅尸" and data.max_hp == 650 and data.move_speed == 95, "Boss resource identity/base HP/speed")
	test.check(is_equal_approx(boss.health.max_hp, 845) and data.max_hp == 650, "Tier3 scales instance HP to 845 without mutating Definition")
	test.check(room.room_state.status == RoomState.Status.ACTIVE and room.doors.values().all(func(door: Door) -> bool: return not door.is_open), "Living Boss closes every connected Door")
	test.check(world.hud.boss_display.visible and world.hud.boss_display.label.text.contains("晋北大帅尸"), "Formal Boss HUD shows name and HP")
	player.position = boss.position + Vector2(80,0)
	await test.frames(30)
	test.check(player.health.current_hp == 80 and boss.state == WarlordBoss.State.INTRO, "INTRO does not immediately hurt Player")
	# 选无障碍水平走廊；前摇结束才锁定方向。
	boss.position = Vector2(400,240)
	player.position = Vector2(560,240)
	boss.state = WarlordBoss.State.CHARGE_WINDUP
	boss._timer = data.charge_windup
	await test.frames(20)
	test.check(boss.state == WarlordBoss.State.CHARGE_WINDUP and boss.position == Vector2(400,240), "Charge has stationary 0.65s windup")
	await test.frames(22)
	var locked := boss.charge_direction
	player.position = Vector2(560,400)
	await test.frames(8)
	test.check(boss.charge_direction.is_equal_approx(locked), "Charge direction stays locked after lateral Player movement")
	await test.frames(32)
	test.check(player.health.current_hp == 80, "Lateral dodge avoids locked charge")
	player.position = Vector2(500,544)
	boss.position = Vector2(410,544)
	boss.state = WarlordBoss.State.CHARGE
	boss.charge_direction = Vector2.RIGHT
	boss._charge_hit = false
	boss._timer = .45
	player.invulnerability_remaining = 0
	await test.frames(30)
	test.check(is_equal_approx(player.health.current_hp,55.7), "One Tier3 charge deals 24.3 exactly once")
	test.check(boss.position.x < 460 and boss.state == WarlordBoss.State.RECOVERY, "Direct Player collision deals charge damage and stops movement")
	player.health.restore(80)
	player.invulnerability_remaining = 0
	boss.position = Vector2(410,544)
	boss.state = WarlordBoss.State.CHARGE
	boss.charge_direction = Vector2.RIGHT
	boss._charge_hit = false
	boss._timer = data.charge_duration
	# 仅测试夹具排除玩家物理碰撞，单独验证无碰撞的近距分支仍有效且只伤一次。
	boss.add_collision_exception_with(player)
	await test.frames(6)
	test.check(boss.state == WarlordBoss.State.CHARGE and boss._charge_hit and is_equal_approx(player.health.current_hp,55.7), "Unobstructed proximity hits once without a physical collision")
	await test.frames(24)
	test.check(is_equal_approx(player.health.current_hp,55.7), "Unobstructed proximity never repeats damage in the same charge")
	boss.remove_collision_exception_with(player)
	player.health.restore(80)
	player.invulnerability_remaining = 0
	player.position = Vector2(900,450)
	boss.position = Vector2(1170,240)
	boss.state = WarlordBoss.State.CHARGE
	boss.charge_direction = Vector2.RIGHT
	boss._timer = .45
	await test.frames(6)
	test.check(boss.state == WarlordBoss.State.RECOVERY and boss.position.x < 1200, "Wall collision terminates charge early")
	# 薄障碍使双方身体不重叠，但停止后的中心距仍<50，复现旧距离分支隔墙命中。
	var barrier := StaticBody2D.new()
	barrier.collision_layer = 1
	barrier.collision_mask = 0
	barrier.position = Vector2(600,544)
	var barrier_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(1,96)
	barrier_shape.shape = rectangle
	barrier.add_child(barrier_shape)
	room.add_child(barrier)
	await test.frames(1)
	boss.position = Vector2(550,544)
	player.position = Vector2(617,544)
	boss.state = WarlordBoss.State.CHARGE
	boss.charge_direction = Vector2.RIGHT
	boss._charge_hit = false
	boss._timer = data.charge_duration
	await test.frames(4)
	test.check(boss.position.x < 599.5 and player.position.x > 600.5 and boss.position.distance_to(player.position) < 50, "Barrier separates Boss/Player inside old proximity threshold")
	test.check(boss.state == WarlordBoss.State.RECOVERY, "Charge hitting intervening obstacle immediately enters RECOVERY")
	test.check(player.health.current_hp == 80 and not boss._charge_hit, "Obstacle collision never deals proximity damage through wall")
	barrier.queue_free()
	player.health.restore(80)
	await test.frames(1)
	boss.position = Vector2(640,368)
	player.position = Vector2(920,368)
	boss.state = WarlordBoss.State.SHOCKWAVE_WINDUP
	boss._timer = .8
	await test.frames(24)
	test.check(boss.state == WarlordBoss.State.SHOCKWAVE_WINDUP and player.health.current_hp == 80, "Shockwave has 0.8s warning before damage")
	await test.frames(30)
	test.check(player.health.current_hp == 80, "Outside radius 180 avoids shockwave")
	player.position = Vector2(740,368)
	boss.state = WarlordBoss.State.SHOCKWAVE
	player.invulnerability_remaining = 0
	await test.frames(20)
	test.check(is_equal_approx(player.health.current_hp,58.4), "Inside shockwave takes Tier3 21.6 once, not every frame")
	test.check(not boss.phase_two and encounter.summons.is_empty(), "Above half HP never summons")
	boss.health.restore(boss.health.max_hp * .5)
	test.check(boss.phase_two and encounter.summons.size() == 3, "First half-HP boundary summons exactly three scarabs")
	for actor in encounter.summons:
		test.check(actor.definition == BossEncounter.SCARAB_DATA and is_equal_approx(actor.health.max_hp,65*1.3) and actor.difficulty == room.difficulty, "Summon uses official scarab resource and encounter tier")
		test.check(actor.position.distance_to(player.position) >= 100 and not room.definition.obstacles.any(func(rect: Rect2) -> bool: return rect.grow(18).has_point(actor.position)), "Summon avoids Player and obstacles")
	boss.health.restore(200)
	boss._check_phase(100,boss.health.max_hp)
	test.check(encounter.summons.size() == 3 and data.charge_windup == .65 and data.shockwave_windup == .8, "Phase two never repeats summons or shortens windups")
	encounter.defeated.connect(func() -> void: deaths += 1)
	var summons := encounter.summons.duplicate()
	boss.take_damage(300)
	boss.take_damage(300)
	await test.frames(3)
	test.check(deaths == 1 and encounter.finished and not boss.ai_enabled, "Boss death settles once and stops AI")
	test.check(summons.all(func(actor) -> bool: return not is_instance_valid(actor)), "Boss victory removes still-living summons")
	test.check(room.room_state.status == RoomState.Status.CLEARED and room.doors.values().all(func(door: Door) -> bool: return door.is_open), "Boss victory clears Room and reopens all Doors")
	test.check(not world.hud.boss_display.visible, "Boss victory hides HUD")
	test.check(room.get_node_or_null("FloorExit") is FloorExit, "Victory creates one floor exit")
	# 已清Boss房重访必须仍有出口，不得再次生成Boss。
	world._switch_room(world.layout.start_id,-1)
	world._switch_room(world.layout.boss_id,-1)
	await test.frames(2)
	test.check(world.current_room.boss_encounter == null and world.current_room.has_node("FloorExit") and world.current_room.room_state.status == RoomState.Status.CLEARED, "Revisit defeated Boss keeps exit without respawning Boss")
	# 新Run进入仍活着的Boss房，再真实触发玩家死亡；同步断言HUD立即隐藏。
	await test.reset()
	world = test.session.world
	world._switch_room(world.layout.boss_id,-1)
	boss = world.current_room.boss_encounter.boss
	test.check(world.hud.boss_display.visible, "Living Boss HUD visible before Player death")
	world.player.health.take_damage(world.player.health.max_hp)
	test.check(not world.hud.boss_display.visible, "Player death immediately hides Boss HUD")
	test.check(world.hud.get_node("Root/Death").visible and world.hud.get_node("Root/Death").text.contains("你已倒下") and not boss.ai_enabled, "Boss-room death still shows Death UI and stops combat")
	completed = true
