extends RefCounted
var test:SceneTree
func _init(context:SceneTree)->void:test=context
func run()->void:
	for site_id in [&"LUOYANG_EAST",&"GUANZHONG_MOUND"]:
		for seed_value in [33,52]:
			var flow:=preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
			flow.profile_store=MuseumProfileStore.in_memory()
			flow.campaign_seed_override=52
			flow.forced_night_seed=seed_value
			test.flow=flow
			test.root.add_child(flow)
			await test.frames(3)
			var daytime=preload("res://tests/phase_8a_flow_checks.gd").new(test,flow)
			await daytime.walk_to(Vector2(940,450))
			await daytime.walk_to(Vector2(940,210))
			await daytime.walk_to(flow.museum.board.position+Vector2(-40,20))
			test.key(KEY_E)
			await test.frames(3)
			await test.choose_region(flow.site_registry.site(site_id).region_id)
			await test.choose_row(0)
			test.capture(str(site_id)+"_map")
			await test.click(flow.museum.expedition_map.confirm_button.get_global_rect().get_center())
			await test.frames(4)
			test.session=flow.dungeon
			var session:DungeonSession=test.session
			test.check(session!=null and session.tomb==flow.site_registry.site(site_id).tomb_definition and session.site_loot_profile!=null,"Actual map confirms region-specific GameFlow dungeon")
			for number in [1,2]:
				var driver=preload("res://tests/threat_fight_driver.gd").new(test)
				driver.avoid_optional_rooms=true
				var world:=session.world
				driver.picked.assign(world.player.relics.inventory.ids())
				await driver.visit(world.layout.relic_id)
				for id in world.layout.ordered_ids():
					if world.layout.rooms[id].room_type==RoomDefinition.Type.COMBAT:
						await driver.visit(id)
						if world.current_room.hazards.get_child_count()>0:test.capture(str(site_id)+"_F"+str(number)+"_hazard")
				for id in [world.layout.antique_id,world.antique_loot.selected_rooms[0]]:
					await driver.visit(id)
					var source:StringName=&"antique_room" if id==world.layout.antique_id else &"combat_cache"
					var definition:=world._pick_antique(id,source)
					if not world.player.antiques.can_add(definition):continue
					var cargo=preload("res://tests/phase_7b_run_driver.gd").new(test)
					await cargo.take_current({"room":id,"source":source,"definition":definition})
					test.check(world.player.antiques.items().has(definition),"Real E acquires regional prototype from actual pedestal")
					test.capture(str(site_id)+"_pickup")
				await driver.visit(world.layout.boss_id)
				await driver.boss_fight()
				var exit:=world.current_room.get_node("RunExit" if number==2 else "ExpeditionExit") as Node2D
				world.player.position=exit.position+Vector2(24,0)
				test.key(KEY_F if seed_value==52 and number==1 else KEY_E)
				await test.frames(5)
				if session.run_ended:break
			test.check(session.run_ended and session.complete_screen.result.antique_ids.size()>0,"Regional complete/extracted Run contains real carried cargo")
			test.key(KEY_E)
			await test.frames(5)
			test.check(flow.current_day==2 and flow.dungeon==null and flow.museum_state.collection.all_items().size()>0,"Actual result returns cargo as unique OwnedAntique instances")
			var state:=flow.museum_state
			var local:OwnedAntique
			for item in state.collection.all_items():
				var archive:CollectionResearchRecord=state.collection.archives[item.instance_id]
				test.check(archive.source.site_id==str(site_id) and archive.source.region_id==str(flow.site_registry.site(site_id).region_id) and archive.source.run_seed==seed_value,"11G actual regional pickup and return records confirmed expedition source")
				var definition:=MuseumState.POOL.find_by_id(item.definition_id)
				if definition.region_ids.size()==1 and definition.region_ids[0]==flow.site_registry.site(site_id).region_id:local=item;break
			test.check(local!=null,"A local new prototype actually reaches museum")
			if local!=null:
				test.check(state.collection_history.has(str(local.definition_id)) and str(flow.site_registry.site(site_id).region_id) in state.collection_history[str(local.definition_id)].regions,"11H real regional return records collectible discovery region")
			if local!=null:
				await daytime.appraise(local.instance_id)
				await daytime.place(1,local.instance_id)
				test.check(state.unit_items(&"CASE_2").has(local) and state.display_catalog.accepts(state.display_catalog.units[&"CASE_2"],state.display_catalog.profiles[str(local.definition_id)]),"Actual appraisal/combination-case UI exhibits legal new prototype")
				test.capture(str(site_id)+"_new_exhibit")
				var loaded:=flow.profile_store.load_profile()
				test.check(loaded.collection.find(local.instance_id)!=null and loaded.case_for(local.instance_id)==state.case_for(local.instance_id),"New prototype and stable display identity persist with unchanged v5 schema")
				# Unit transaction coverage uses isolated funds, separate from above real pickup/return/exhibit.
				state.unassign(state.case_for(local.instance_id))
				state.cash=10000
				local.condition=65
				test.check(state.repair(local.instance_id) and local.condition==100,"New prototype restoration uses existing transaction")
				test.check(state.consign(local.instance_id,0) and not state.sell_to_dealer(local.instance_id),"New prototype consignment locks sale")
				state.cancel_consignment()
				test.check(state.sell_to_dealer(local.instance_id) and state.collection.find(local.instance_id)==null,"New prototype dealer sale removes exactly its owned instance")
				var auction_item:OwnedAntique
				for owned in state.collection.all_items():
					if MuseumState.POOL.find_by_id(owned.definition_id).content_review_status==&"PLAYTEST_PENDING_HISTORICAL_REVIEW":auction_item=owned;break
				if auction_item!=null:
					state.identify(auction_item.instance_id)
					test.check(state.consign(auction_item.instance_id,0) and flow.start_auction(),"New actual-cargo prototype enters original Auction GameFlow")
					await test.frames(5)
					for round_index in range(200):
						if flow.auction.bidding.finished:break
						test.key(KEY_E)
						await test.frames(1)
					test.check(flow.auction.bidding.finished and flow.auction.lot_name==MuseumState.POOL.find_by_id(auction_item.definition_id).display_name,"Real E bidding settles a new prototype lot")
					test.capture(str(site_id)+"_auction")
					test.key(KEY_E)
					await test.frames(5)
					test.check(flow.auction==null and flow.current_day==3 and state.auction_lot_instance_id==&"","New prototype auction returns once and unlocks lot")
			flow.queue_free()
			await test.frames(4)
