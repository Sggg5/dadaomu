extends RefCounted
## 程序驾驶非人工手感：活跃AI、真实弹丸；读预警选择安全点，不改HP、不用F2。
var test: SceneTree
var completed: bool = false


func _init(context: SceneTree) -> void: test = context


func run() -> void:
	var world: RoomController = test.session.world
	var room := world.current_room
	var boss := room.boss_encounter.boss as TombGuardianBeast
	var ticks: int = 0
	var saw_pounce: bool = false
	var saw_roar: bool = false
	var saw_spikes: bool = false
	var saw_rage: bool = false
	while is_instance_valid(boss) and not boss.health.is_dead and not world.player.health.is_dead and ticks < 5400:
		var safest := world.player.position
		var best: float = -INF
		for y in range(208,538,48):
			for x in range(160,1160,48):
				var point := Vector2(x,y)
				var distance := point.distance_to(boss.position)
				if distance < 220 or distance > 430: continue
				if room.definition.obstacles.any(func(rect: Rect2) -> bool: return rect.grow(22).has_point(point)): continue
				var ray := PhysicsRayQueryParameters2D.create(boss.position,point,1,[boss.get_rid()])
				if not boss.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
				var score: float = 500-absf(distance-300)
				if boss.state in [TombGuardianBeast.State.POUNCE_WINDUP,TombGuardianBeast.State.POUNCE]: score = minf(score,point.distance_to(boss.pounce_target))
				for attack in room.projectiles.get_children():
					if attack is TombSpike: score = minf(score,point.distance_to(attack.global_position)*2)
					if attack is EnemyProjectile:
						var closest := Geometry2D.get_closest_point_to_segment(point,attack.position,attack.position+attack.velocity*.35)
						score = minf(score,point.distance_to(closest)*2)
				if score > best:
					best = score
					safest = point
		world.player.position = safest
		world.player.velocity = Vector2.ZERO
		saw_pounce = saw_pounce or boss.pounces > 0
		saw_roar = saw_roar or boss.roars > 0
		saw_spikes = saw_spikes or boss.spike_batches > 0
		if not saw_rage and boss.rage:
			test.capture("beast_rage")
			saw_rage = true
		# 延迟收尾观察狂暴的扇弹和地刺；不改变Boss生命或AI。
		var observe_rage := boss.rage and (boss.roars < 2 or boss.spike_batches < 2)
		if not observe_rage and boss.state in [TombGuardianBeast.State.DECIDE,TombGuardianBeast.State.RECOVERY]: world.player.weapon.try_attack(safest,(boss.position-safest).normalized(),world.player.stats)
		if ticks == 180: test.capture("beast_pounce")
		if ticks == 330: test.capture("beast_roar")
		if ticks == 480: test.capture("beast_spikes")
		await test.frames(6)
		ticks += 6
	test.check(room.boss_encounter.finished and not world.player.health.is_dead, "Actual Weapon/Projectile defeats active tomb beast")
	test.check(saw_pounce and saw_roar and saw_spikes and saw_rage, "Live beast performs pounce/roar/spikes/Rage")
	print("[Live beast] physics %.2fs, HP %.2f" % [ticks/60.0,world.player.health.current_hp])
	await test.frames(12)
	completed = true
