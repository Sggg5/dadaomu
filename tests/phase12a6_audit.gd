extends "res://tests/phase12a5_smoke.gd"
## Read-only identification before any replacement assets are implemented.
func run() -> void:
	ArtRenderSettings.initialized=true; ArtRenderSettings.mode=2
	await enter_formal()
	var world:=session.world
	var rows:Array=[]
	for enemy in world.current_room.damage_targets():
		rows.append({"id":str(enemy.definition.id),"script":enemy.get_script().resource_path,"scene":enemy.scene_file_path,"visual_supported":enemy.art_visual.supported(),"position":str(enemy.position),"body_radius":enemy.body_radius(),"hp":enemy.health.max_hp})
	var lab=LAB.new(world);lab.select(1);await frames(3)
	var sample=preload("res://tests/support/phase12a5_binding.gd").install(world)
	var a_rows:Array=[]
	for enemy in world.current_room.damage_targets():
		a_rows.append({"id":str(enemy.definition.id),"script":enemy.get_script().resource_path,"scene":enemy.scene_file_path,"visual_supported":enemy.art_visual.supported(),"position":str(enemy.position),"body_radius":enemy.body_radius(),"hp":enemy.health.max_hp})
	var file:=FileAccess.open("res://docs/phase12a6_enemy_audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"seed":session.run_seed,"room_id":str(world.current_id),"encounter_resource":world.current_room.definition.resource_path,"formal_first":rows,"isolated_a":a_rows},"\t"));file.close()
	print("AUDIT ",JSON.stringify(a_rows));quit()
