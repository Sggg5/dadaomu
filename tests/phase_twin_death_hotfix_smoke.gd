extends "res://tests/phase_9b32_smoke.gd"
func run()->void:
	var fixture=preload("res://tests/phase_9b32_mechanic_checks.gd").new(self)
	for first in [0,1]:
		await fixture.setup(preload("res://data/bosses/twin_revenants.tres"))
		var boss:Enemy=fixture.boss
		var members:Array=boss.get("members")
		var survivor:Enemy=members[1-first]
		var emissions:Dictionary={"count":0}
		fixture.world.current_room.boss_encounter.defeated.connect(func()->void:emissions.count+=1)
		members[first].health.take_damage(99999)
		await frames(ceili(members[first].definition.death_duration*60)+12)
		check(not is_instance_valid(members[first]),"Member %d actually freed before survivor damage"%first)
		var old_turn:int=boss.turn
		boss._advance_turn(first)
		boss._support(first)
		boss._member_dead(first)
		check(boss.turn==old_turn and boss.combat_targets().size()==1,"Freed member cannot reclaim turn or support")
		var before:float=boss.health.current_hp
		survivor.health.take_damage(10)
		check(is_equal_approx(boss.health.current_hp,before-10),"Order %d survivor damage synchronizes shared HP"%first)
		check(survivor.solo and survivor.may_attack,"Order %d solo attack remains enabled"%first)
		survivor.health.take_damage(99999)
		await frames(3)
		check(fixture.world.current_room.boss_encounter.finished,"Order %d encounter completes"%first)
		check(emissions.count==1 and fixture.session.bosses_defeated==1,"Single parent settlement")
		print("[Lifecycle] first=",first," valid=",members.map(func(member)->bool:return is_instance_valid(member))," turn=",boss.turn," sharedHP=",boss.health.current_hp," finished=",fixture.world.current_room.boss_encounter.finished," remaining=",fixture.world.current_room.enemy_spawner.get_remaining()," defeated=",emissions.count)
	await fixture.setup(preload("res://data/bosses/twin_revenants.tres"))
	var parent:Enemy=fixture.boss
	var pair:Array=parent.get("members")
	var simultaneous:Dictionary={"count":0}
	fixture.world.current_room.boss_encounter.defeated.connect(func()->void:simultaneous.count+=1)
	pair[0].health.take_damage(99999)
	await frames(1)
	pair[1].health.take_damage(99999)
	await frames(30)
	check(simultaneous.count==1 and fixture.session.bosses_defeated==1,"Adjacent frame deaths settle once")
	check(fixture.world.current_room.boss_encounter.finished and fixture.world.current_room.room_state.status==RoomState.Status.CLEARED,"Adjacent deaths clear room")
	check(fixture.world.current_room.get_children().all(func(node:Node)->bool:return not (node is BossTelegraph)),"Death cancels owned warnings")
	fixture.session.queue_free()
	await frames(3)
	await preload("res://tests/twin_hotfix_weapon_checks.gd").new(self).run()
	if "--manual" in OS.get_cmdline_user_args():return
	print("[Twin hotfix] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
