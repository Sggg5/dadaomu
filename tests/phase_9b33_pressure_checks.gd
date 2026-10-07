extends "res://tests/phase_9b32_mechanic_checks.gd"
func run()->void:
	for number in range(1,6):
		for definition:Variant in TOMB.floor_at(number).boss_pool.bosses:
			await setup(definition,true)
			if not (boss is MechanismBoss):continue
			var actor:=boss as MechanismBoss
			actor.set_physics_process(false)
			for phase in range(1,actor.phase_thresholds.size()+2):
				actor.phase_index=phase
				actor.cycle_history.clear()
				var single_streak:=0
				for cycle in range(12):
					actor.cycles=cycle
					var actions:=actor.choose_actions(330)
					test.check(not actions.is_empty() and actions.size()<=4,"Finite readable pressure cycle "+str(definition.id))
					var combo:=actions.size()>1
					actor.cycle_history.append(combo)
					single_streak=0 if combo else single_streak+1
					test.check(single_streak<=3,"At most three ordinary cycles without pressure combo")
					for action in actions:
						test.check(action.warning>=0.25,"Attack preview never disappears")
			# First crossing hit is unmodified; subsequent hits are briefly reduced, never locked out.
			actor.phase_index=1
			actor.health.restore(actor.health.max_hp*0.8)
			actor.transition_remaining=0
			var hp:=actor.health.current_hp
			actor.take_damage(actor.health.max_hp*0.4)
			# Bronze frontal armor is a separate intentional mechanic; use its rear for this assertion.
			if definition.id!=&"bronze_king":
					test.check(is_equal_approx(hp-actor.health.current_hp,actor.health.max_hp*0.4),"Threshold crossing damage is not clamped")
					test.check(actor.state==&"TRANSITION" and is_equal_approx(actor.transition_remaining,0.4),"Visible half-second phase transition and short smoothing")
					hp=actor.health.current_hp
					actor.take_damage(10)
					test.check(is_equal_approx(hp-actor.health.current_hp,5),"Transition still accepts damage at50 percent")
					actor._tick_ai(0.51)
					hp=actor.health.current_hp
					actor.take_damage(10)
					test.check(is_equal_approx(hp-actor.health.current_hp,10),"Transition reduction expires, no permanent damage gate")
			actor._cycle_combo=false
			test.check(actor.recovery_duration()>=0.45 and actor.recovery_duration()<=1.0,"Ordinary recovery belongs to floor static data")
			actor._cycle_combo=true
			test.check(actor.recovery_duration()>=0.9 and actor.recovery_duration()<=1.3,"Pressure combo leaves clear output window")
	await setup(TOMB.floor_at(4).boss_pool.bosses[1],true)
	var twins:=boss
	var hp:float=twins.members[1].health.current_hp
	for index in range(3):twins._support(0)
	test.check(twins.support_actions==1,"Twin secondary area occurs every third shared round")
	var survivor: TwinAvatar=twins.members[1]
	var recovery:float=survivor.recovery_duration()
	twins.members[0].health.take_damage(9999)
	await test.frames(2)
	test.check(survivor.solo and is_equal_approx(survivor.recovery_duration(),recovery*0.82),"Solo rhythm is18 percent faster")
	test.check(survivor.health.current_hp<=hp,"Solo cannot heal HP")
	test.check(survivor.choose_actions(330).size()>=2,"Solo inherits melee/ranged combo")
	await setup(TOMB.floor_at(1).boss_pool.bosses[0],true)
	var encounter:=world.current_room.boss_encounter
	encounter.create_eggs(4)
	encounter.create_eggs(2,2)
	test.check(encounter.eggs.size()==2,"Low-phase egg cap retires excess without unbounded hatch")
	await setup(TOMB.floor_at(2).boss_pool.bosses[1],true)
	var chain:=boss as MechanismBoss
	chain.cycles=3
	var hook_combo:=chain.choose_actions(330)
	test.check(hook_combo[0].kind==&"HOOK" and hook_combo[1].kind==&"SWEEP" and hook_combo[1].warning+hook_combo[0].gap<0.6,"Hook slow remains relevant at follow-up sweep impact")
	await setup(TOMB.floor_at(1).boss_pool.bosses[0],true)
	test.check(is_equal_approx(world.player.stats.hurt_invulnerability,0.25),"Player i-frame stays0.25 seconds")
	world.player.take_damage(12)
	var current:=world.player.health.current_hp
	test.check(not world.player.take_damage(12) and world.player.health.current_hp==current,"Same attack immediate repeat is suppressed")
	await test.frames(16)
	test.check(world.player.take_damage(12),"Separate readable combo hit after0.25 seconds remains effective")
	session.queue_free()
	await test.frames(3)
