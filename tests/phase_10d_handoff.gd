extends "res://tests/phase_7b_smoke.gd"
## Isolated manual handoff: real GameFlow, no fixture gifts, no user profile writes.
func run() -> void:
 var flow:=preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
 flow.profile_store=MuseumProfileStore.in_memory()
 flow.campaign_seed_override=192034
 root.title="大盗墓时代 · Phase 10D 图鉴试玩（隔离存档）"
 root.add_child(flow)
 current_scene=flow
 await frames(3)
 var walker=preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
 await walker.walk_to(Vector2(930,450))
 await walker.walk_to(Vector2(930,230))
 await frames(2)
 RenderingServer.force_draw()
 DirAccess.make_dir_recursive_absolute("res://logs/phase10d")
 root.get_texture().get_image().save_png("res://logs/phase10d/manual_ready.png")
 print("Phase 10D manual handoff ready: actual GameFlow, research desk, isolated memory profile")
