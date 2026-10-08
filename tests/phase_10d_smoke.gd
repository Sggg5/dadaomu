extends "res://tests/phase_7b_smoke.gd"
const FLOW_SCENE: PackedScene = preload("res://scenes/main/game_flow.tscn")
func run() -> void:
 var flow := FLOW_SCENE.instantiate() as GameFlow
 flow.profile_store = MuseumProfileStore.in_memory()
 root.add_child(flow)
 await frames(3)
 var museum := flow.museum
 var panel := museum.codex_panel
 check(flow.museum_state.collection.all_items().is_empty(),"formal empty owned collection")
 museum.player.position=museum.research_desk.position+Vector2(0,40)
 await frames(2)
 key(KEY_E)
 await frames(2)
 check(panel.panel.visible and not museum.player.controls_enabled,"real E opens and locks control")
 check(panel.result_ids.is_empty(),"empty collection list")
 var a:=flow.museum_state.collection.add(&"tang_sancai_horse",1,41,false)
 var b:=flow.museum_state.collection.add(&"tang_sancai_horse",1,87,true)
 panel.refresh()
 check(panel.result_ids.size()==2,"duplicate definition distinct instances")
 panel.select_entry(0)
 check(not panel.detail.text.contains("品相41"),"unidentified condition hidden")
 panel.select_entry(1)
 check(panel.detail.text.contains("品相87"),"identified condition visible")
 panel.set_mode(1)
 check(panel.result_ids.size()==1441 and panel.list.item_count==40,"paginated research")
 panel.set_mode(2)
 panel.search_box.text="Trilobite"
 panel.refresh()
 check(not panel.result_ids.is_empty(),"English natural search")
 panel.search_box.text=""
 panel.set_mode(3)
 check(panel.exhibitions.ids().size()==4,"four exhibition plans")
 for exhibition:String in panel.exhibitions.ids():
  panel.exhibition_id=exhibition
  panel.refresh()
  check(panel.result_ids==panel.exhibitions.plan(exhibition).reading_order and panel.result_ids.size()==8,"exhibition ordered eight objects")
  check(panel.detail.text.contains("DRAFT_PENDING_REVIEW"),"exhibition remains draft")
 key(KEY_TAB)
 await frames(2)
 check(not panel.panel.visible and museum.player.controls_enabled,"Tab closes restores control")
 check(flow.museum_state.cash==0 and not a.identified,"research no economic mutation")
 museum.collection_panel.open()
 check(not panel.open(),"other panel prevents opening")
 museum.collection_panel.close()
 flow.museum_state.phase=MuseumState.Phase.OPEN
 check(panel.open(),"read during OPEN")
 panel.close()
 check(flow.museum_state.phase==MuseumState.Phase.OPEN,"OPEN preserved")
 flow.museum_state.phase=MuseumState.Phase.MORNING
 flow.queue_free()
 await frames(2)
 print("Phase 10D UI: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
