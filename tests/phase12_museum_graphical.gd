extends "res://tests/phase_11a_smoke.gd"
## Earned Day13 QA snapshot, memory-only, not a production save or free gift.
func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://docs/screenshots/phase_12/%d_museum_%s.png" % [ArtRenderSettings.mode,label])
func run() -> void:
	flow = preload("res://scenes/main/game_flow.tscn").instantiate()
	flow.profile_store = MuseumProfileStore.in_memory()
	var source := MuseumProfileStore.new(); source.save_path = "res://tests/fixtures/11i_earned_midgame.json"
	flow.profile_store._memory = source.encode(source.load_profile())
	root.add_child(flow); await frames(5)
	capture("composite_case")
	var museum := flow.museum
	var original_cash := flow.museum_state.cash
	museum.collection_panel.open(museum.cases[0].case_id)
	await frames(3); capture("storage"); museum.collection_panel.close()
	for item in flow.museum_state.collection.all_items():
		if AntiqueVisual.icon(item.definition_id) != null:
			museum.codex_panel.open_at(item.instance_id); await frames(4)
			check(museum.codex_panel.image.texture != null,"Independent real-owned dossier uses original game icon")
			capture("dossier"); museum.codex_panel.close(); break
	for hall in flow.museum_state.display_catalog.hall_ids(flow.museum_state.museum_level):
		museum.switch_hall(hall); await frames(4); capture("hall_"+str(hall))
	check(flow.museum_state.cash == original_cash,"Visual queries never affect cash")
	flow.queue_free(); await frames(4)
	print("[Phase12 museum graphical] %d checks, %d failures" % [checks,failures]); quit(0 if failures == 0 else 1)

