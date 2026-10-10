extends "res://tests/phase12a5_playtest.gd"
func run() -> void:
	await super.run()
	if "--capture-preview" in OS.get_cmdline_user_args():
		await frames(3) # Flush native canvas transforms while the fixture remains paused.
		var bodies:Array=session.world.current_room.get_children().filter(func(n:Node)->bool:return n.name.begins_with("EnemyArt_"))
		check(paused and bodies.size()==5,"Paused A selector retains all five actual enemy visuals")
		check(bodies.all(func(n:Node)->bool:return n.visible and n.sprite.texture!=null),"Every paused preview body is immediately complete")
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://docs/screenshots/phase_12a6/isolated_paused_selector.png")
		print("[Phase12A6 paused preview] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
func show_layout(index:int) -> void:
	await super.show_layout(index)
	if index==1:
		preload("res://tests/support/phase12a6_binding.gd").install(session.world)
		notice.text="12A.6 DRAFT · A主棺 · 2尸犬 + 3尸蟞 · 空格开始"
	DisplayServer.window_set_title("大盗墓时代 · 12A.6 敌人战斗样板 · Seed522269330 · 隔离内存档")
