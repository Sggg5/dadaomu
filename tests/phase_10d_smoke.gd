extends "res://tests/phase_7b_smoke.gd"
const FLOW_SCENE: PackedScene = preload("res://scenes/main/game_flow.tscn")
func capture(label: String) -> void:
 if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
  DirAccess.make_dir_recursive_absolute("res://logs/phase10d")
  await frames(2)
  RenderingServer.force_draw()
  var snapshot:=root.get_texture().get_image()
  var folder:="res://logs/phase10d/%dx%d" %[snapshot.get_width(),snapshot.get_height()]
  DirAccess.make_dir_recursive_absolute(folder)
  snapshot.save_png(folder+"/"+label+".png")
func run() -> void:
 var flow := FLOW_SCENE.instantiate() as GameFlow
 flow.profile_store = MuseumProfileStore.in_memory()
 root.add_child(flow)
 await frames(3)
 var museum := flow.museum
 var panel := museum.codex_panel
 check(flow.museum_state.collection.all_items().is_empty(),"formal empty owned collection")
 var walker = preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
 await walker.walk_to(Vector2(930,450))
 await walker.walk_to(Vector2(930,230))
 await capture("research_desk")
 await frames(2)
 key(KEY_E)
 await frames(2)
 check(panel.panel.visible and not museum.player.controls_enabled,"real E opens and locks control")
 check(panel.result_ids.is_empty(),"empty collection list")
 await capture("empty_owned")
 var a:=flow.museum_state.collection.add(&"tang_sancai_horse",1,41,false)
 var b:=flow.museum_state.collection.add(&"tang_sancai_horse",1,87,true)
 panel.refresh()
 check(panel.result_ids.size()==2,"duplicate definition distinct instances")
 panel.select_entry(0)
 check(not panel.detail.text.contains("品相41"),"unidentified condition hidden")
 panel.list.select(1)
 panel.select_entry(1)
 check(panel.detail.text.contains("品相87"),"identified condition visible")
 await capture("owned_instances")
 panel.set_mode(1)
 check(panel.result_ids.size()==1441 and panel.list.item_count==40,"paginated research")
 await capture("global_directory")
 for keyword in ["唐代海兽", "Wine Cup"]:
  panel.search_box.text=keyword
  panel.refresh()
  await capture("photo_detail" if keyword=="唐代海兽" else "placeholder")
  if keyword=="唐代海兽":
   await frames(2)
   panel.detail.get_v_scroll_bar().value=panel.detail.get_v_scroll_bar().max_value
   await capture("article_sources")
   check(panel.detail.get_v_scroll_bar().value>0,"body and source can scroll")
   panel.detail.get_v_scroll_bar().value=0
 panel.search_box.text=""
 var photo_count:=0
 for id:String in panel.catalog.ids():
  var row:=panel.catalog.record(id)
  if row.media_asset_id!=null:
   panel.result_ids=[id];panel.render_page()
   check(panel.image.texture!=null,"photo visible in actual panel")
   await capture("photo_"+str(photo_count))
   photo_count+=1
 panel.set_mode(2)
 panel.set_mode(2)
 panel.search_box.text="Trilobite"
 panel.refresh()
 check(not panel.result_ids.is_empty(),"English natural search")
 await capture("fossil_detail")
 panel.search_box.text=""
 panel.set_mode(3)
 check(panel.exhibitions.ids().size()==4,"four exhibition plans")
 for exhibition:String in panel.exhibitions.ids():
  panel.exhibition_id=exhibition
  panel.refresh()
  check(panel.result_ids==panel.exhibitions.plan(exhibition).reading_order and panel.result_ids.size()==8,"exhibition ordered eight objects")
  check(panel.detail.text.contains("DRAFT_PENDING_REVIEW"),"exhibition remains draft")
  await capture("exhibition_"+exhibition)
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
 # Opening via E, closing via E must consume input and not reopen.
 check(panel.open(),"reopen one panel")
 panel.search_box.text=""
 panel.search_box.grab_focus()
 var text_event:=InputEventKey.new()
 text_event.physical_keycode=KEY_E
 text_event.keycode=KEY_E
 text_event.unicode=101
 text_event.pressed=true
 root.push_input(text_event)
 await frames(2)
 check(panel.panel.visible and panel.search_box.text=="e","English E search does not close panel")
 panel.search_box.release_focus()
 key(KEY_E)
 await frames(2)
 check(not panel.panel.visible and museum.player.controls_enabled,"E close does not reopen")
 var profile_before:=JSON.stringify(flow.profile_store.encode(flow.museum_state))
 var saves_before:=flow.profile_store.save_count
 var changed_count:=[0]
 flow.museum_state.changed.connect(func()->void:changed_count[0]+=1)
 panel.open();panel.set_mode(1);panel.close()
 check(JSON.stringify(flow.profile_store.encode(flow.museum_state))==profile_before and flow.profile_store.save_count==saves_before and changed_count[0]==0,"read-only profile and signals unchanged")
 check(flow.museum_state.assign(flow.museum_state.case_ids()[0],b.instance_id),"identified fixture assigned for real business")
 await walker.walk_to(Vector2(930,450))
 await walker.walk_to(Vector2(1080,540))
 key(KEY_E)
 await frames(2)
 check(museum.business.running and flow.museum_state.phase==MuseumState.Phase.OPEN,"real ticket E starts actual business")
 await walker.walk_to(Vector2(930,450))
 await walker.walk_to(Vector2(930,230))
 key(KEY_E)
 await frames(2)
 check(panel.panel.visible and museum.business.running and flow.museum_state.phase==MuseumState.Phase.OPEN,"real desk E reads during actual OPEN")
 await capture("open_reading")
 check(museum.business.income_today==museum.business.visitors_today*flow.museum_config.ticket_price,"reading adds no extra ticket income")
 var unloaded_panel: WeakRef = weakref(panel)
 flow.queue_free()
 await frames(2)
 check(unloaded_panel.get_ref()==null,"scene unload releases open panel and textures")
 if "--flow" in OS.get_cmdline_user_args():
  await preload("res://tests/phase_10d_flow_checks.gd").new(self).run()
 print("Phase 10D UI: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
