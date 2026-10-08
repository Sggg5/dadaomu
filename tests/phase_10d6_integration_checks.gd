extends RefCounted
var test:SceneTree
func _init(context:SceneTree)->void:test=context
func capture(name:String)->void:
 if DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args():
  await test.frames(2)
  RenderingServer.force_draw()
  var folder:="res://logs/phase10d6"
  DirAccess.make_dir_recursive_absolute(folder)
  test.root.get_texture().get_image().save_png(folder+"/"+name+".png")
func run()->void:
 var flow:=preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
 flow.profile_store=MuseumProfileStore.in_memory()
 flow.campaign_seed_override=52
 var config:=MuseumConfig.new()
 config.open_duration=8
 config.visitor_speed=1200
 config.view_duration=.8
 flow.museum_config=config
 test.root.add_child(flow)
 await test.frames(3)
 var museum:=flow.museum
 var state:=flow.museum_state
 var driver=preload("res://tests/phase_8a_flow_checks.gd").new(test,flow)
 var samples:Array[Dictionary]=[]
 for count in [50,100,500]:
  var items:Array[OwnedAntique]=[]
  for i in range(count):
   var item:=OwnedAntique.new()
   item.instance_id=StringName("A%06d"%(i+1))
   item.definition_id=MuseumState.POOL.antiques[i%8].id
   item.acquired_day=1;item.identified=true;item.condition=70+i%31
   items.append(item)
  state.collection.restore(items,count+1)
  var begin:=Time.get_ticks_usec()
  museum.collection_panel.open()
  var open_us:=Time.get_ticks_usec()-begin
  test.check(museum.collection_panel.filtered_ids.size()==count and museum.collection_panel.list.item_count==50,"paged storage count "+str(count))
  museum.collection_panel.page=ceili(count/50.0)-1
  museum.collection_panel.refresh_library()
  test.check(museum.collection_panel._ids.back()==items.back().instance_id,"last page reaches final instance "+str(count))
  begin=Time.get_ticks_usec()
  museum.collection_panel.search_box.text="A000001"
  museum.collection_panel.refresh_library()
  var search_us:=Time.get_ticks_usec()-begin
  test.check(museum.collection_panel.list.item_count==1,"search isolates exact instance "+str(count))
  samples.append({"collection":count,"open_us":open_us,"search_us":search_us,"list_items":50,"unit_nodes":museum.cases.size()})
  museum.collection_panel.close()
 test.check(state.collection.add(&"object:research",1,100,true)==null and state.collection.add(&"candidate:test",1,100,true)==null,"research and candidate IDs cannot become owned antiques")
 museum.collection_panel.open()
 museum.collection_panel.category.select(1)
 museum.collection_panel.refresh_library()
 test.check(museum.collection_panel.filtered_ids.size()==63,"500-item coin classification filter")
 museum.collection_panel.category.select(0)
 museum.collection_panel.refresh_library()
 test.check(museum.collection_panel._ids.size()==50,"filter return restores paginated storage")
 await capture("storage_500")
 museum.collection_panel.close()
 state.collection.restore([],1)
 for def in preload("res://data/antiques/formal_pool.tres").antiques:state.collection.add(def.id,1,100,true)
 await driver.walk_to(Vector2(640,380))
 await driver.walk_to(Vector2(640,348))
 test.key(KEY_E);await test.frames(2)
 test.check(museum.collection_panel.panel.visible and museum.collection_panel.slot_list.item_count==8,"actual E opens eight slot unit manager")
 state.fill_unit(&"CASE_2",museum.collection_panel.filtered_ids)
 await capture("slot_manager_eight")
 test.key(KEY_TAB);await test.frames(2)
 await capture("combined_unit_eight")
 var first:=state.collection.all_items()[0]
 test.check(state.unassign(&"CASE_2/02") and state.unit_items(&"CASE_2").size()==7,"withdraw one retains seven")
 test.check(state.fill_unit(&"CASE_2",state.collection.all_items().map(func(i:OwnedAntique)->StringName:return i.instance_id))==1,"refill single vacancy")
 var before:=state.display_assignments.duplicate()
 test.check(state.withdraw_unit(&"CASE_2") and state.display_assignments.is_empty(),"batch withdraw returns all to storage")
 state.fill_unit(&"CASE_2",state.collection.all_items().map(func(i:OwnedAntique)->StringName:return i.instance_id))
 test.check(state.display_assignments==before,"batch arrangement reproduces same eight unique placements")
 # Two-stage actual hall UI navigation; only selected hall facility Nodes exist.
 await driver.walk_to(museum.hall_guide.position+Vector2(0,40))
 test.key(KEY_E);await test.frames(2)
 await capture("hall_navigation")
 museum.hall_panel.list.select(museum.hall_panel.ids.find(&"EAST"))
 museum.hall_panel.panel.get_child(0).get_child(2).pressed.emit()
 await test.frames(3)
 test.check(museum.active_hall_id==&"EAST" and museum.cases.size()==1 and museum.player.controls_enabled,"real E/selector crosses into east hall")
 await capture("east_hall")
 var coin:=state.collection.add(&"republic_silver_coin",1,100,true)
 test.check(state.place(&"COIN_E1/01",coin.instance_id),"coin fits dedicated small-object slot")
 var jar:=state.collection.add(&"blue_white_jar",1,100,true)
 test.check(not state.place(&"COIN_E1/02",jar.instance_id),"pottery rejects coin fixture")
 await driver.walk_to(museum.hall_guide.position+Vector2(0,40))
 test.key(KEY_E);await test.frames(2)
 museum.hall_panel.list.select(museum.hall_panel.ids.find(&"MAIN"))
 museum.hall_panel.panel.get_child(0).get_child(2).pressed.emit()
 await test.frames(3)
 test.check(museum.active_hall_id==&"MAIN" and museum.cases.size()==3,"return via actual hall selector")
 await driver.walk_to(Vector2(1080,540))
 test.key(KEY_E);await test.frames(2)
 test.check(state.phase==MuseumState.Phase.OPEN and museum.business.running,"real ticket E opens multislot business")
 await driver.walk_to(Vector2(640,380))
 await driver.walk_to(Vector2(640,348))
 test.key(KEY_E);await test.frames(2)
 var profile_before:=flow.profile_store.encode(state)
 test.check(museum.collection_panel.panel.visible and museum.collection_panel.panel.get_node("VBoxContainer/Choose").disabled,"OPEN manager shows read-only slots")
 test.check(not museum.collection_panel.choose_selected() and not state.withdraw_unit(&"CASE_2") and state.display_assignments==before.merged({&"COIN_E1/01":coin.instance_id}),"OPEN refuses assignment and bulk withdrawal")
 test.key(KEY_TAB);await test.frames(2)
 var main_viewed:=false
 var east_viewed:=false
 var geometry_ok:=true
 for frame in range(1000):
  for visitor in museum.business.active:
   if visitor.activity==MuseumVisitor.Activity.VIEW:
    if visitor.hall_id==&"MAIN" and visitor.chosen_unit_id==&"CASE_2" and visitor.viewed_instance_ids.size()>=8:
     main_viewed=true
     await capture("visitor_combined_display")
    if visitor.hall_id==&"EAST":east_viewed=true
    if visitor.visible!=(visitor.hall_id==museum.active_hall_id):geometry_ok=false
   # Visitors only use their own hall's footprints; route segments are clear of all units.
   for unit_id in state.display_catalog.unit_ids(state.museum_level,visitor.hall_id):
    var unit:=state.display_catalog.units[unit_id]
    if Rect2(unit.position-Vector2(52,30),Vector2(104,60)).grow(12).has_point(visitor.position):geometry_ok=false
  if not museum.business.running:break
  await test.frames(1)
 test.check(main_viewed,"visitor actually examines all eight displayed instances")
 test.check(east_viewed and geometry_ok,"visitor traverses east hall; stays out of footprints and wrong-hall rendering")
 test.check(state.phase==MuseumState.Phase.EVENING and state.last_day_ticket_income==state.last_day_visitors*5 and state.cash==state.last_day_ticket_income,"multihall closing settles ticket income once")
 var cash:=state.cash
 museum.business._on_paid(0)
 test.check(state.cash==cash,"late duplicate visitor payment rejected")
 # Quantify bounded duplicate contribution, not one full appeal per instance.
 var duplicate_state:=MuseumState.new()
 duplicate_state.museum_level=2
 for id in duplicate_state.display_catalog.unit_ids(2):
  var unit:=duplicate_state.display_catalog.units[id]
  for slot in unit.slots():
   var owned:=duplicate_state.collection.add(&"republic_silver_coin",1,100,true)
   duplicate_state.place(slot.id,owned.instance_id)
 test.check(duplicate_state.total_appeal()<20 and duplicate_state.display_assignments.size()>40,"many identical coins cannot stack full appeal without bound")
 if DisplayServer.get_name()!="headless":samples.append({"renderer":"graphical","resolution":str(test.root.size)})
 DirAccess.make_dir_recursive_absolute("res://logs/phase10d6")
 var output:=FileAccess.open("res://logs/phase10d6/performance_%s.json"%DisplayServer.get_name(),FileAccess.WRITE)
 output.store_string(JSON.stringify(samples,"\t"));output.close()
 flow.queue_free();await test.frames(3)
