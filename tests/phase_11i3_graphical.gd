extends "res://tests/phase_11a_smoke.gd"
## Empty formal GameFlow audit. Actual UI clicks; no granted assets.
func capture(label:String)->void:
	if DisplayServer.get_name()=="headless":return
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://logs/11i_%s%s.png"%["midgame_" if "--midgame" in OS.get_cmdline_user_args() else "",label])
func bounds(node:Node)->void:
	for child in node.get_children():
		if child is Control and child.is_visible_in_tree() and child is Button:
			var rect:Rect2=child.get_global_rect()
			check(Rect2(0,0,1280,720).encloses(rect),"Visible button within viewport: "+str(child.text))
		bounds(child)
func run()->void:
	flow=preload("res://scenes/main/game_flow.tscn").instantiate();flow.profile_store=MuseumProfileStore.in_memory();flow.campaign_seed_override=52
	var midgame:bool="--midgame" in OS.get_cmdline_user_args()
	if midgame:
		var source:=MuseumProfileStore.new();source.save_path="res://tests/fixtures/11i_earned_midgame.json"
		flow.profile_store._memory=source.encode(source.load_profile())
	root.add_child(flow);await frames(4)
	var opening_cash:=flow.museum_state.cash;var honors:=flow.museum_state.achievements.duplicate(true)
	check(root.get_visible_rect().size==Vector2(1280,720),"Actual 1280x720 viewport")
	check(midgame or (flow.museum.message.text.contains("免费鉴定") and flow.museum.message.text.contains("情报板")),"New empty game explains first revenue path / earned snapshot restored")
	var day=preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	capture("new_game")
	await day.walk_to(Vector2(230,540));await day.walk_to(Vector2(230,230));key(KEY_E);await frames(4)
	var office:=flow.museum.office_panel
	check(office.panel.visible,"Actual desk E opens office")
	for index in range(office.tabs.get_tab_count()):
		await click(office.tabs.get_tab_bar().global_position+office.tabs.get_tab_bar().get_tab_rect(index).get_center());await frames(3)
		check(office.tabs.current_tab==index,"Actual office tab "+str(index))
		bounds(office.panel);capture("office_%d"%index)
	key(KEY_TAB);await frames(3);check(flow.museum.player.controls_enabled,"Office close restores movement")
	await day.walk_to(Vector2(115,230));await day.walk_to(Vector2(115,390));key(KEY_E);await frames(3)
	var honor:=flow.museum.reputation_panel
	for index in range(honor.tabs.get_tab_count()):
		await click(honor.tabs.get_tab_bar().global_position+honor.tabs.get_tab_bar().get_tab_rect(index).get_center());await frames(3)
		check(honor.tabs.current_tab==index,"Actual honor/codex tab "+str(index));bounds(honor.panel);capture("honor_%d"%index)
	key(KEY_TAB);await frames(3)
	await day.walk_to(Vector2(115,540));await day.walk_to(Vector2(180,540));key(KEY_E);await frames(3)
	check(flow.museum.collection_panel.panel.visible and flow.museum.collection_panel._ids.size()==flow.museum_state.collection.all_items().size(),"Warehouse lists only actual collection")
	bounds(flow.museum.collection_panel.panel);capture("empty_storage");key(KEY_TAB);await frames(3)
	await day.walk_to(Vector2(940,450));await day.walk_to(Vector2(940,230));await day.walk_to(Vector2(900,230));key(KEY_E);await frames(3)
	check(flow.museum.codex_panel.panel.visible,"Actual research table opens")
	bounds(flow.museum.codex_panel.panel);capture("empty_research");key(KEY_TAB);await frames(3)
	check(flow.museum_state.cash==opening_cash and flow.museum_state.achievements==honors,"UI queries neither generate income nor honors")
	flow.queue_free();await frames(3);print("[11I3 graphical] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
