extends "res://tests/phase_9b32_smoke.gd"
func click(point:Vector2)->void:
	var motion:=InputEventMouseMotion.new()
	motion.position=point
	root.push_input(motion,true)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.position=point
		event.global_position=point
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=pressed
		root.push_input(event,true)
	await frames(2)
func choose_region(id:StringName)->void:
	for node in flow.museum.expedition_map.nodes:
		if node.definition.region_id==id:
			print("[Map click] ",id," rect=",node.get_global_rect()," viewport=",root.get_visible_rect())
			await click(node.get_global_rect().position+Vector2(42,22))
func choose_row(index:int)->void:
	var list:=flow.museum.expedition_map.sites_list
	await click(list.get_global_rect().position+list.get_item_rect(index).get_center())
func capture(label:String)->void:
	if DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://logs/11a_%s.png"%label)
func run()->void:
	var registry:=SiteRegistry.load_default()
	check(registry.regions.size()==3 and registry.sites.size()==6,"Three regions / six explicit site archives")
	var unique:Dictionary={}
	for site in registry.sites:
		check(not unique.has(site.site_id) and registry.region(site.region_id)!=null,"Unique site identity and real region reference")
		unique[site.site_id]=true
		check(site.background.contains("虚构") and not site.enemy_intel.is_empty() and not site.artifact_intel.is_empty(),"Fiction and uncertain intelligence explicit")
		check(registry.can_depart(site.site_id)==(site.site_id in [&"DEFAULT_TOMB",&"LUOYANG_EAST",&"GUANZHONG_MOUND"]),"Only fully tested released/playtest sites playable")
	check(registry.loot_profile(&"FORMAL_DEFAULT").approved_pool.antiques.size()==8,"Regional interface retains original eight approved artifacts")
	var base_site:=registry.site(&"DEFAULT_TOMB")
	var boss_signature:=BossRunPlan.build(33,base_site.tomb_definition).signature()
	var relic_signature:=RelicRewardPlan.build(33,5,RelicRewardService.PRODUCTION_POOL).signature()
	var antique_id:=MuseumState.POOL.pick(33,1,&"ROOM_TEST").id
	var alternate:=base_site.duplicate() as SiteDefinition
	alternate.site_id=&"ISOLATED_SECOND_SITE"
	var choice:=ExpeditionSelection.capture(alternate,52,1)
	check(choice.seed_value!=ExpeditionSeedService.derive(52,1),"Valid alternate site has a distinct natural Seed")
	check(TombFloorGenerator.generate(choice.seed_value,1,choice.tomb_definition).spatial_signature()!=TombFloorGenerator.generate(ExpeditionSeedService.derive(52,1),1,base_site.tomb_definition).spatial_signature(),"Two configured Site domains yield different actual layouts")
	alternate.site_id=&"MUTATED_UI_SITE"
	alternate.tomb_definition=null
	check(choice.site_id==&"ISOLATED_SECOND_SITE" and choice.tomb_definition!=null,"Confirmation snapshot detached from later site-field edits")
	check(BossRunPlan.build(33,base_site.tomb_definition).signature()==boss_signature and RelicRewardPlan.build(33,5,RelicRewardService.PRODUCTION_POOL).signature()==relic_signature and MuseumState.POOL.pick(33,1,&"ROOM_TEST").id==antique_id,"Selection does not perturb independent Boss/Relic/Antique streams")
	check(not registry.can_depart(&"UNKNOWN_SITE") and registry.loot_profile(&"UNREVIEWED_CANDIDATES")==null,"Unknown site and unpublished regional pools rejected")
	var seen:Dictionary={}
	for index in range(100):
		var seed:=ExpeditionSeedService.derive(52,1,StringName("SITE_"+str(index)))
		check(not seen.has(seed) and seed==ExpeditionSeedService.derive(52,1,StringName("SITE_"+str(index))),"Independent reproducible Site Seed domain")
		seen[seed]=true
	flow=preload("res://scenes/main/game_flow.tscn").instantiate()
	flow.profile_store=MuseumProfileStore.in_memory()
	flow.campaign_seed_override=52
	root.add_child(flow)
	await frames(3)
	check(not flow.start_night() and flow.dungeon==null,"No unconfirmed direct departure")
	var day_driver=preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await day_driver.walk_to(Vector2(940,450))
	await day_driver.walk_to(Vector2(940,210))
	await day_driver.walk_to(flow.museum.board.position+Vector2(-40,20))
	key(KEY_E)
	await frames(3)
	var map:=flow.museum.expedition_map
	check(map.panel.visible and not flow.museum.player.controls_enabled and flow.dungeon==null and flow.current_phase==MuseumState.Phase.MORNING,"Actual board E opens map without starting NIGHT")
	capture("region_map")
	await choose_region(&"LUOYANG")
	await choose_row(1)
	check(map.selected_region==&"LUOYANG" and map.selected_site==&"LUOYANG_RIVER" and map.detail.text.contains("情报调查中"),"Actual mouse selects region and investigation archive")
	check(map.confirm_button.disabled and not map.confirm() and flow.dungeon==null,"Unavailable site cannot depart")
	capture("investigation_archive")
	map.show_regions()
	check(map.selected_site==&"" and map.confirm_button.disabled,"Back to regions clears stale selection")
	await choose_region(&"GUANZHONG")
	await choose_row(1)
	check(map.selected_site==&"GUANZHONG_PASS" and map.confirm_button.disabled,"Second investigation region/row clickable")
	key(KEY_ESCAPE)
	await frames(2)
	check(not map.panel.visible and flow.museum.player.controls_enabled and flow.current_phase==MuseumState.Phase.MORNING,"Esc cancels map and restores ground control")
	key(KEY_E)
	await frames(2)
	await choose_region(&"JINBEI")
	await choose_row(0)
	check(map.selected_site==&"DEFAULT_TOMB" and not map.confirm_button.disabled,"Playable Jinbei site selected with mouse")
	capture("jinbei_confirmation")
	flow.museum_state.last_day_visitors=9
	flow.museum_state.last_day_ticket_income=45
	flow.profile_store.write_blocked=true
	await click(map.confirm_button.get_global_rect().get_center())
	check(flow.dungeon==null and flow.current_phase==MuseumState.Phase.MORNING and map.panel.visible and map.detail.text.contains("保存失败"),"Save failure prevents dungeon and allows retry")
	check(flow.museum_state.last_day_visitors==9 and flow.museum_state.last_day_ticket_income==45,"Failed departure preserves previous business totals")
	flow.profile_store.write_blocked=false
	await click(map.confirm_button.get_global_rect().get_center())
	await frames(4)
	session=flow.dungeon
	check(session!=null and flow.museum==null and flow.current_phase==MuseumState.Phase.NIGHT,"Actual map confirmation loads real GameFlow dungeon")
	check(session.tomb==registry.site(&"DEFAULT_TOMB").tomb_definition and session.tomb.floors.size()==5,"Selected TombDefinition is original tested five-floor tomb")
	check(session.run_seed==ExpeditionSeedService.derive(52,1) and flow.active_expedition.site_id==&"DEFAULT_TOMB","Old default Site Seed compatibility")
	check(not flow.confirm_expedition(&"LUOYANG_RIVER") and session.tomb.floors.size()==5,"In-flight selection cannot change dungeon")
	var signature:=session.world.layout.spatial_signature()
	key(KEY_R)
	await frames(5)
	check(session.world.layout.spatial_signature()==signature,"R preserves selected site topology")
	key(KEY_N)
	await frames(5)
	check(session.world.layout.spatial_signature()!=signature and session.tomb.floors.size()==5,"N rebuilds seed without replacing selected tomb")
	capture("real_jinbei_start")
	session.world.player.health.take_damage(9999)
	await frames(3)
	check(session.run_ended and session.complete_screen.result.outcome==RunResult.Outcome.DEAD,"Selected site retains original death lifecycle")
	key(KEY_E)
	await frames(5)
	check(flow.current_day==2 and flow.dungeon==null and flow.active_expedition==null,"Death returns Day2 museum and releases selection")
	var next_map:=flow.museum.expedition_map
	check(next_map.open(),"Returned Museum can reopen fresh map")
	next_map.select_region(&"JINBEI")
	next_map.select_site(&"DEFAULT_TOMB")
	check(ExpeditionSelection.capture(flow.site_registry.site(&"DEFAULT_TOMB"),52,2).seed_value!=ExpeditionSeedService.derive(52,1),"Next day keeps new expedition Seed")
	next_map.close()
	flow.queue_free()
	await frames(3)
	# Complete unchanged five-floor combat/relic/cargo/Boss/return route, now via map confirmation.
	if "--ui-only" not in OS.get_cmdline_user_args():
		await preload("res://tests/phase_9b3_run_checks.gd").new(self).run()
	print("[Phase 11A] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)

