extends "res://tests/phase_5b_smoke.gd"
func run() -> void:
	var flow = preload("res://scenes/main/game_flow.tscn").instantiate()
	flow.profile_store = MuseumProfileStore.in_memory(); flow.campaign_seed_override=52
	root.add_child(flow); await frames(4)
	var choice := ExpeditionSelection.capture(SiteRegistry.load_default().site(&"DEFAULT_TOMB"),52,1,522269330,&"MOJIN")
	check(flow.start_night(choice),"Production flow accepts explicit immutable profession choice")
	await frames(6)
	var session: DungeonSession = flow.dungeon
	var world: RoomController = session.world
	var runtime: ProfessionRuntime = world.profession_runtime
	var state := session.profession_state
	check(runtime.available(),"Safe START allows token management")
	for id in [&"FAQIU",&"BANSHAN",&"XIELING"]: state.search(StringName("fixture:"+str(id)),id,{"name":"DRAFT fixture"})
	var relic_ids := world.player.relics.inventory.ids()
	var topology := world.layout.signature()
	check(runtime.equip(&"BANSHAN") and runtime.use_ability(),"Banshan arming uses real runtime service")
	var hp := world.player.health.current_hp
	check(runtime.equip(&"MOJIN"),"Safe atomic switch away from armed Banshan")
	world.player.take_environment_damage(5)
	check(world.player.health.current_hp==hp-5 and state.guard_ready,"Inactive Banshan cannot cancel damage; prepared guard retained")
	await frames(18)
	check(runtime.equip(&"BANSHAN"),"Re-equipping armed Banshan")
	hp=world.player.health.current_hp
	world.player.take_environment_damage(5)
	check(world.player.health.current_hp==hp and not state.guard_ready and state.used(&"BANSHAN:GUARD")==1,"Active Banshan cancels actual Player damage once")
	await frames(18); world.player.take_environment_damage(5)
	check(world.player.health.current_hp==hp-5 and not runtime.use_ability(),"Guard exhausted and ability cannot refill after damage")
	var coin := MuseumState.POOL.find_by_id(&"republic_silver_coin")
	check(runtime.equip(&"XIELING") and world.player.antiques.capacity==10,"Xieling grants exactly two runtime slots")
	for i in range(10): check(world.player.antiques.add(coin),"Fixture reaches legal Xieling capacity")
	var observed: Array = []
	var observer: Callable = func(): observed.append([state.active_id,world.player.antiques.capacity,world.player.profession_wall_multiplier])
	state.changed.connect(observer)
	check(runtime.equip(&"MOJIN"),"Overloaded switch succeeds without discarding antiques")
	check(observed==[[&"MOJIN",8,1.5]],"Subscribers see only complete atomic new effects")
	check(world.player.antiques.items().size()==10 and not world.player.antiques.can_add(coin) and world.player.encounter_movement_modifiers.get(ProfessionRuntime.OVERLOAD_KEY)==.8,"Overload keeps items, rejects pickup and visibly slows")
	check(world.player.relics.inventory.ids()==relic_ids and world.layout.signature()==topology,"Runtime effects do not alter relic inventory or topology")
	check(runtime.equip(&"FAQIU") and runtime.use_ability() and not state.catalog_note.is_empty(),"Faqiu catalog uses actual bag without changing values")
	var ledger := state.consumption_ledger()
	world.transitioning=true; check(not runtime.equip(&"XIELING") and not runtime.use_ability(),"Scene transition rejects switch and use"); world.transitioning=false
	world.current_room.room_state.status=RoomState.Status.ACTIVE
	check(not runtime.equip(&"XIELING"),"Combat rejects switch")
	world.current_room.room_state.status=RoomState.Status.CLEARED
	session._changing=true; check(not runtime.equip(&"XIELING"),"Session transition guard rejects switch"); session._changing=false
	var risk := TombRiskContent.new()
	world.current_room.risk_content=risk
	risk.confirming=true; check(not runtime.equip(&"XIELING"),"Risk confirmation rejects switch")
	risk.confirming=false; risk.resolving=true; check(not runtime.equip(&"XIELING"),"Synchronous danger settlement rejects switch")
	risk.resolving=false; world.current_room.risk_content=null; risk.free()
	check(state.consumption_ledger()==ledger,"Rejected transactions cannot reset ledger")
	var carry := RunCarryState.capture(world.player)
	var new_player = preload("res://scenes/player/player.tscn").instantiate()
	root.add_child(new_player); await frames(2); carry.apply(new_player)
	check(new_player.antiques.items().size()==10 and new_player.antiques.capacity==8,"Actual carry apply retains all overloaded antiques")
	new_player.queue_free()
	var corpse = preload("res://scripts/professions/profession_corpse.gd").new()
	corpse.runtime=runtime; corpse.faction_id=&"FAQIU"; corpse.source_key=&"fixture_range"
	corpse.position=world.player.position+Vector2(200,0); world.current_room.add_child(corpse)
	await frames(2); check(not corpse.search(),"Corpse cannot be searched outside 64px")
	corpse.position=world.player.position+Vector2(32,0)
	var count := state.tokens().size()
	check(corpse.search() and not corpse.search() and state.tokens().size()==count,"Nearby duplicate token records identity once without stacking")
	state.end(); await frames(2)
	check(world.player.profession_wall_multiplier==1.0 and world.player.antiques.capacity==8 and state.tokens().is_empty(),"End removes effects and clears independent state")
	state.changed.disconnect(observer)
	key(KEY_R); await frames(6)
	check(session.world.layout.signature()==topology and state.tokens()==[&"MOJIN"] and state.consumption_ledger().is_empty() and session.world.player.antiques.items().is_empty(),"Actual R retains initial selection and Seed while rebuilding new run state")
	var before_n := session.run_seed
	key(KEY_N)
	await frames(6)
	check(session.run_seed!=before_n,"Actual N key chooses a new Seed")
	check(session.world.layout.signature()!=topology and state.active_id==&"MOJIN" and state.tokens()==[&"MOJIN"] and state.consumption_ledger().is_empty(),"New Seed retains chosen initial faction but never old discovered tokens/uses")
	flow.queue_free(); await frames(3)
	print("[Phase13A runtime] %d checks, %d failures"%[checks,failures]); quit(0 if failures==0 else 1)
