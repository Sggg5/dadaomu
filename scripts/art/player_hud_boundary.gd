extends RefCounted
## Presentation only. Formal GameFlow must not expose laboratory buttons.
## Legacy standalone combat test scenes retain their explicit development UI.
static func apply(controller: Node) -> void:
	if not is_instance_valid(controller) or controller.has_meta("player_hud_boundary"): return
	var session:=controller.get_parent()
	if session==null or session.get_parent()==null or session.get_parent().name!=&"GameFlow": return
	if controller.get_tree().has_meta("phase12_debug_controls"): return
	controller.set_meta("player_hud_boundary",true)
	var hud=controller.get("hud")
	for path in ["Root/DamageButton","Root/NewSeedButton"]:
		var button=hud.get_node_or_null(path)
		if button!=null: button.hide()
	var panel=controller.get_node_or_null("RelicDebugPanel")
	if panel!=null:
		panel.formal_panel.hide()
		panel.set_process_unhandled_input(false)
		var trim:=func() -> void:
			if is_instance_valid(panel): panel.label.text=panel.label.text.get_slice("|",0).strip_edges()
		panel.runtime.inventory.changed.connect(trim)
		trim.call()
