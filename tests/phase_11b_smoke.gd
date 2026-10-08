extends "res://tests/phase_11a_smoke.gd"
func capture(label:String)->void:
	if DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://logs/11b_%s.png"%label)
func run()->void:
	var registry:=SiteRegistry.load_default()
	check(MuseumState.POOL.antiques.size()==50 and MuseumState.POOL.is_valid(),"Museum recognizes exactly fifty unique game prototypes")
	var reached:Dictionary={}
	var statistics:Dictionary={}
	for site_id in [&"LUOYANG_EAST",&"GUANZHONG_MOUND"]:
		var site:=registry.site(site_id)
		var profile:=registry.loot_profile(site.loot_profile_id)
		check(registry.can_depart(site_id) and profile.usable(),"New complete site and chronological profile usable")
		var counters:Dictionary={"LOCAL":0,"CIRCULATION":0,"HEIRLOOM":0}
		for seed_value in range(10000):
			var room:=StringName("R"+str(seed_value%17))
			var quality:=site.tomb_definition.floor_at(1).antique_reward_profile
			var item:=profile.pick(seed_value,1,room,&"antique_room",quality)
			check(profile.eligible(item) and item.slots<=8,"Regional reward obeys chronology / carrying capacity")
			check(item==profile.pick(seed_value,1,room,&"antique_room",quality),"Same regional Seed/source deterministic")
			reached[item.id]=true
			counters[profile.group_for(item.id)]+=1
			if seed_value<100:
				var high:=profile.pick(seed_value,2,room,&"risk_reward:secret",quality,true)
				check(profile.eligible(high) and high.rarity>=AntiqueDefinition.Rarity.RARE,"High-value risk source cannot bypass chronology")
		statistics[str(site_id)]=counters
		check(absf(counters.LOCAL/10000.0-.7)<.03 and absf(counters.CIRCULATION/10000.0-.2)<.03 and absf(counters.HEIRLOOM/10000.0-.1)<.03,"Measured 70/20/10 distribution")
		check(not profile.eligible(preload("res://data/antiques/blue_white_jar.tres")) and not profile.eligible(preload("res://data/antiques/republic_silver_coin.tres")),"Modern and later porcelain never enter either ancient site")
	for item in MuseumState.POOL.antiques:
		if item.content_review_status==&"PLAYTEST_PENDING_HISTORICAL_REVIEW":check(reached.has(item.id),"Every new prototype has observed nonzero reachable probability: "+str(item.id))
	FileAccess.open("res://logs/11b_drop_statistics.json",FileAccess.WRITE).store_string(JSON.stringify(statistics,"  "))
	print("[11B distribution] ",JSON.stringify(statistics))
	# Reuse exact legacy default selection and reward semantics.
	var legacy:=registry.loot_profile(&"FORMAL_DEFAULT")
	for seed_value in range(50):check(legacy.pick(seed_value,1,&"TEST",&"antique_room")==preload("res://data/antiques/formal_pool.tres").pick(seed_value,1,&"TEST",&"antique_room"),"Jinbei legacy eight Seed result unchanged")
	await preload("res://tests/phase_11b_flow_checks.gd").new(self).run()
	print("[Phase 11B] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
