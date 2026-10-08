extends "res://tests/phase_7b_smoke.gd"
## Explicit isolated showcase fixture. The production GameFlow still gifts nothing.
func run()->void:
 var flow:=preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
 flow.profile_store=MuseumProfileStore.in_memory()
 flow.campaign_seed_override=192034
 root.title="大盗墓时代 · 10D.6 组合展柜试玩（隔离夹具）"
 root.add_child(flow)
 current_scene=flow
 await frames(3)
 var state:=flow.museum_state
 state.museum_level=2
 var ids:Array[StringName]=[]
 for def in MuseumState.POOL.antiques:ids.append(state.collection.add(def.id,1,100,true).instance_id)
 state.fill_unit(&"CASE_2",ids)
 flow.museum.message.text="隔离陈列夹具：8件原型藏品 / 三个展厅 · 不会赠送给正式新游戏或覆盖原存档"
 var driver=preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
 await driver.walk_to(Vector2(680,380))
 await driver.walk_to(Vector2(680,348))
 await frames(2)
 RenderingServer.force_draw()
 DirAccess.make_dir_recursive_absolute("res://logs/phase10d6")
 root.get_texture().get_image().save_png("res://logs/phase10d6/manual_ready.png")
 print("10D6 handoff ready: eight original artifacts, level2 isolated memory profile, research/halls/services available")
