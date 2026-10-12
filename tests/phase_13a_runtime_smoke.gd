extends "res://tests/phase_5b_smoke.gd"
func run() -> void:
	var flow = preload("res://scenes/main/game_flow.tscn").instantiate()
	flow.profile_store=MuseumProfileStore.in_memory(); flow.campaign_seed_override=52
	root.add_child(flow); await frames(4)
	var choice := ExpeditionSelection.capture(SiteRegistry.load_default().site(&"DEFAULT_TOMB"),52,1,522269330,&"MOJIN")
	check(flow.start_night(choice),"Snapshot safely enters production GameFlow")
	await frames(6)
	var session: DungeonSession = flow.dungeon
	var world: RoomController = session.world
	var runtime: ProfessionRuntime = world.profession_runtime
	var state := session.profession_state
	check(runtime.available(),"Safe START allows management")
	for id in [&"FAQIU",&"BANSHAN",&"XIELING"]:state.search(StringName("unit:"+str(id)),id,{"name":"unit fixture"})
	var topology := world.layout.signature()
	var relic_ids := world.player.relics.inventory.ids()
	check(runtime.use_ability() and state.used(runtime.clue_key())==1 and not state.clues[1].is_empty(),"Mojin genuinely references existing map once per floor")
	check(runtime.equip(&"BANSHAN") and world.player.profession_movement_multiplier==1.08,"Banshan installs isolated 8 percent movement")
	var enemy := Enemy.new();var hp_node := Health.new();hp_node.name="Health";enemy.add_child(hp_node);enemy.definition=EnemyDefinition.new();enemy.definition.max_hp=1000;root.add_child(enemy)
	var request := AttackRequest.new();request.damage=20;request.speed=0;request.lifetime=1;request.direction=Vector2.RIGHT
	for i in range(4):
		var batch: Array[AttackRequest] = world.player.relics.prepare_attack(request)
		var bullet: Projectile = preload("res://scenes/player/projectile.tscn").instantiate();world.current_room.projectiles.add_child(bullet);bullet.setup(batch[0]);runtime.bind_projectile(bullet,batch[0]);world.player.relics.bind_projectile(bullet)
		bullet._apply_hit(enemy);bullet._apply_hit(enemy)
		check(state.banshan_hits==i+1,"Multiple contacts in one attack credit once")
		bullet.queue_free()
	check(state.banshan_ready,"Four effective weapon batches prepare enhancement")
	check(runtime.equip(&"MOJIN") and world.player.profession_movement_multiplier==1.0 and not runtime.use_ability(),"Switch unloads Banshan movement and cannot refill Mojin clue")
	check(runtime.equip(&"BANSHAN") and state.banshan_ready,"Prepared enhancement survives switch")
	var enhanced: Array[AttackRequest] = world.player.relics.prepare_attack(request)
	check(enhanced[0].damage==25 and state.banshan_ready,"Next attack is 25 percent stronger; preparation alone does not consume")
	world._spawn_projectile(enhanced[0])
	check(not state.banshan_ready and state.used(&"BANSHAN:EMPOWER")==1,"Actual spawned projectile consumes enhancement once")
	var false_hit := ProjectileHitContext.new();false_hit.target=enemy;false_hit.damage=5;false_hit.tags=[&"burn"]
	runtime.weapon_hit(false_hit);check(state.banshan_hits==0,"Continuous damage and uncredited relic procs do not count")
	enemy.queue_free()
	check(runtime.equip(&"FAQIU"),"Faqiu equippable after safe test firing")
	var original_type := world.current_room.room_type
	world.current_room.room_type=RoomDefinition.Type.COMBAT;runtime.current_key=&"F1:UNIT_COMBAT";runtime.first_visit=state.visit_room(runtime.current_key)
	var hp := world.player.health.current_hp
	check(not world.player.take_damage(0) and not state.damaged_rooms.has(runtime.current_key),"Zero damage does not consume first-hit mitigation")
	world.player.take_damage(10)
	check(is_equal_approx(world.player.health.current_hp,hp-7),"Real Health loses 7 from first positive 10 damage")
	check(not world.player.take_damage(10) and state.used(&"FAQIU:SHIELD:F1:UNIT_COMBAT")==1,"Invulnerability cannot double-consume shield")
	await frames(18);world.player.take_damage(10)
	check(is_equal_approx(world.player.health.current_hp,hp-17),"Second positive hit has no reduction")
	runtime.first_visit=state.visit_room(runtime.current_key);await frames(18);world.player.take_damage(10)
	check(is_equal_approx(world.player.health.current_hp,hp-27) and not runtime.first_visit,"Revisited room never refreshes shield")
	world.current_room.room_type=original_type
	check(runtime.equip(&"XIELING") and ProfessionRegistry.token_name(&"XIELING")=="卸岭旗","Xieling capacity and unified token name")
	var coin := MuseumState.POOL.find_by_id(&"republic_silver_coin")
	for i in range(10):check(world.player.antiques.add(coin),"Legal ten-slot unit inventory")
	var value := world.player.antiques.total_value()
	check(world.player.antiques.capacity==10 and world.player.encounter_movement_modifiers[ProfessionRuntime.OVERLOAD_KEY]==.95,"9-10 slots are normal loaded state at 95 percent speed")
	var observed: Array=[]
	var observer: Callable=func():observed.append([state.active_id,world.player.antiques.capacity,world.player.profession_movement_multiplier])
	state.changed.connect(observer)
	check(runtime.equip(&"BANSHAN"),"Atomic overloaded switch retains antiques")
	check(observed==[[&"BANSHAN",8,1.08]],"Only complete new effects are observable")
	state.changed.disconnect(observer)
	check(world.player.antiques.used_slots()==10 and world.player.antiques.total_value()==value and not world.player.antiques.can_add(coin) and world.player.encounter_movement_modifiers[ProfessionRuntime.OVERLOAD_KEY]==.8,"Overload keeps all value/items, blocks pickup, slows to 80 percent")
	check(runtime.equip(&"XIELING") and world.player.encounter_movement_modifiers[ProfessionRuntime.OVERLOAD_KEY]==.95,"Re-equip returns normal load without stacking")
	var carry := RunCarryState.capture(world.player)
	var next = preload("res://scenes/player/player.tscn").instantiate();root.add_child(next);await frames(2);carry.apply(next)
	check(next.antiques.used_slots()==10 and next.antiques.total_value()==value,"Existing carry survives new eight-slot inventory intact")
	next.queue_free()
	check(world.player.relics.inventory.ids()==relic_ids and world.layout.signature()==topology,"Independent faction inventory never changes relic/topology")
	var ledger := state.consumption_ledger()
	world.transitioning=true;check(not runtime.equip(&"MOJIN") and not runtime.use_ability(),"Transition denies switch/use");world.transitioning=false
	world.current_room.room_state.status=RoomState.Status.ACTIVE;check(not runtime.equip(&"MOJIN"),"Combat denies switch");world.current_room.room_state.status=RoomState.Status.CLEARED
	session._changing=true;check(not runtime.equip(&"MOJIN"),"Session transition denies switch");session._changing=false
	var risk := TombRiskContent.new();world.current_room.risk_content=risk
	risk.confirming=true;check(not runtime.equip(&"MOJIN"),"Risk confirmation denies switch");risk.confirming=false;risk.resolving=true;check(not runtime.equip(&"MOJIN"),"Risk settlement denies switch");world.current_room.risk_content=null;risk.free()
	check(state.consumption_ledger()==ledger,"Rejected operations cannot reset usage")
	var corpse=preload("res://scripts/professions/profession_corpse.gd").new();corpse.runtime=runtime;corpse.faction_id=&"FAQIU";corpse.source_key=&"unit_range";corpse.position=world.player.position+Vector2(200,0);world.current_room.add_child(corpse);await frames(2)
	check(not corpse.search(),"Out-of-range corpse cannot be searched")
	corpse.position=world.player.position+Vector2(32,0)
	var count := state.tokens().size();check(corpse.search() and not corpse.search() and count==state.tokens().size(),"Duplicate searches/tokens never stack")
	state.end();await frames(2)
	check(world.player.profession_movement_multiplier==1.0 and world.player.antiques.capacity==8 and state.tokens().is_empty() and state.clues.is_empty() and state.damaged_rooms.is_empty(),"Run end clears all faction ledgers and effects")
	key(KEY_R);await frames(6)
	check(session.world.layout.signature()==topology and state.tokens()==[&"MOJIN"] and state.consumption_ledger().is_empty() and session.world.player.antiques.items().is_empty(),"R begins clean same-Seed run with chosen initial token")
	var old_seed := session.run_seed;key(KEY_N);await frames(6)
	check(session.run_seed!=old_seed and state.active_id==&"MOJIN" and state.tokens()==[&"MOJIN"],"N begins clean new-Seed run")
	flow.queue_free();await frames(4)
	print("[Phase13A runtime] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
