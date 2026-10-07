extends "res://tests/phase_9b3_ai_checks.gd"
var report:Dictionary={"range":[],"shots":[],"movement":[]}
func equip(ids:Array)->void:
	player.relics.inventory.clear()
	for id in ids:player.relics.inventory.add(load("res://data/relics/%s.tres"%id))
func run()->void:
	await fresh()
	var stats:=player.stats
	test.check(stats.max_hp==80 and stats.move_speed==240 and stats.attack_speed==3.5 and stats.projectile_lifetime==1 and stats.projectile_speed==750,"Production player baseline 80/240/3.5/750/1")
	test.check(stats.acceleration==1800 and stats.deceleration==2200 and stats.attack_damage==20 and stats.hurt_invulnerability==0.25,"Input response, damage and hurt window unchanged")
	test.check(RelicRewardService.PRODUCTION_POOL.relics.size()==41,"Five growth definitions join 41-item production pool")
	for ids in [[],["far_lantern"],["goose_feather"],["goose_feather","far_lantern"],["wind_still_pearl","far_lantern"]]:
		equip(ids)
		var request:=AttackRequest.new()
		request.origin=Vector2(2000,2000)
		request.direction=Vector2.RIGHT
		request.speed=stats.projectile_speed
		request.lifetime=stats.projectile_lifetime
		var modified:AttackRequest=player.relics.prepare_attack(request)[0]
		var projectile:=preload("res://scenes/player/projectile.tscn").instantiate() as Projectile
		projectile.collision_mask=0 # Isolate lifetime from room walls; actual physics/projectile remains real.
		test.root.add_child(projectile)
		projectile.setup(modified)
		var distance:=[0.0]
		projectile.tree_exiting.connect(func()->void:distance[0]=projectile.global_position.distance_to(modified.origin))
		for frame in range(240):
			if not is_instance_valid(projectile):break
			await test.frames(1)
		var theoretical:=modified.speed*modified.lifetime
		test.check(absf(distance[0]-theoretical)<=modified.speed/60+1,"Actual finite projectile flight: "+str(ids))
		report.range.append({"ids":ids,"actual":distance[0],"theoretical":theoretical})
	var fired:=[0]
	var count:=func(_request:AttackRequest)->void:fired[0]+=1
	player.weapon.attack_requested.connect(count)
	for ids in [[],["mechanism_spring"],["ghost_drum"],["mechanism_spring","ghost_drum"]]:
		equip(ids)
		fired[0]=0
		player.weapon.cooldown_remaining=0
		var cooldown:=1.0/stats.attack_speed
		if "mechanism_spring" in ids:cooldown*=0.84
		if "ghost_drum" in ids:cooldown/=1.35
		for frame in range(600):
			player.weapon.try_attack(player.global_position,Vector2.UP,stats)
			await test.frames(1)
		var expected:=int(ceil(600.0/ceil(cooldown*60)))
		test.check(absi(fired[0]-expected)<=1 and fired[0]<=70,"Real 10-second finite weapon cadence: "+str(ids))
		report.shots.append({"ids":ids,"actual":fired[0],"continuous_theory":10/cooldown,"physics_step_expected":expected})
	player.weapon.attack_requested.disconnect(count)
	for ids in [[],["flying_tiger_boots"],["wind_boots"],["shrinking_ruler"],["flying_tiger_boots","shrinking_ruler","wind_boots"]]:
		equip(ids)
		player.position=Vector2(640,368)
		player.velocity=Vector2.ZERO
		var multiplier:=1.0
		if "flying_tiger_boots" in ids:multiplier*=1.12
		if "shrinking_ruler" in ids:multiplier*=1.2
		if "wind_boots" in ids:
			await test.frames(16)
			test.check(player.take_damage(1),"Real hurt triggers temporary wind boots")
			multiplier*=1.2
		multiplier=clampf(multiplier,0.5,1.5)
		Input.action_press("move_right")
		await test.frames(14)
		test.check(is_equal_approx(player.velocity.length(),240*multiplier),"Actual accelerated movement cap: "+str(ids))
		report.movement.append({"ids":ids,"speed":player.velocity.length(),"multiplier":player.relics.movement_multiplier()})
		Input.action_release("move_right")
		await test.frames(14)
		test.check(player.velocity.is_zero_approx(),"Deceleration still stops promptly")
	equip([])
	player.weapon.cooldown_remaining=0
	player.weapon.try_attack(player.global_position,Vector2.UP,stats)
	test.check(is_equal_approx(player.weapon.cooldown_remaining,1.0/3.5),"Uninstall restores actual next weapon cooldown")
	var extreme:=preload("res://data/relics/mechanism_spring.tres").duplicate() as RelicDefinition
	extreme.id=&"unit_extreme_cooling"
	extreme.parameters={"cooldown":0.00001}
	player.relics.inventory.add(extreme)
	player.weapon.cooldown_remaining=0
	player.weapon.try_attack(player.global_position,Vector2.UP,stats)
	test.check(is_equal_approx(player.weapon.cooldown_remaining,0.5/3.5),"Final cooldown clamp prevents infinite cadence even for malformed extreme data")
	equip([])
	test.check(player.relics.movement_multiplier()==1 and stats.move_speed==240 and stats.attack_speed==3.5 and stats.projectile_lifetime==1,"Uninstall restores baseline, shared resource remains pristine")
	FileAccess.open("res://logs/player_baseline_statistics.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("[Player baseline] ",JSON.stringify(report))
	session.queue_free()
	await test.frames(3)
