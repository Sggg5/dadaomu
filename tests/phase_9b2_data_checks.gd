extends RefCounted
const TOMB: TombDefinition = preload("res://data/tombs/default_tomb.tres")
var test: SceneTree
func _init(context: SceneTree) -> void: test=context
func run() -> void:
	var map_sums := [0.0,0.0,0.0,0.0,0.0]
	var sums := [0.0,0.0,0.0,0.0,0.0]
	var template_ids := {}
	for number in range(1,6):
		var data := TOMB.floor_at(number)
		var count := 0.0
		for template in data.dungeon_config.templates:
			template_ids[template.room_id]=true
			count+=template.spawns.size()
			var room := preload("res://scenes/rooms/room.tscn").instantiate() as Room
			room.definition = template
			test.check(not template.obstacles.any(func(rect: Rect2)->bool:return rect.grow(20).has_point(room.get_entry_position())),"Every new template permits safe START placement")
			room.free()
			for entry in template.spawns:
				var position := entry.position
				for entrance in [Vector2(640,208),Vector2(1152,368),Vector2(640,528),Vector2(128,368)]: test.check(position.distance_to(entrance)>=180,"Density spawn retains entrance safety")
				test.check(not template.obstacles.any(func(rect: Rect2)->bool:return rect.grow(24).has_point(position)),"Spawn avoids obstacle including large bodies")
				for other in template.spawns:
					if other!=entry: test.check(position.distance_to(other.position)>=48,"Spawn pair spacing")
		sums[number-1]=count/data.dungeon_config.templates.size()
		print("[9B.2 density] Floor%d mean=%.3f" % [number,sums[number-1]])
		if number>1: test.check(sums[number-1]>sums[number-2],"Average ordinary density rises by floor")
		for seed_value in range(100):
			var layout := TombFloorGenerator.generate(seed_value,number,TOMB)
			map_sums[number-1]+=layout.rooms.size()
			test.check(layout.rooms.size()>=data.dungeon_config.min_rooms and layout.rooms.size()<=data.dungeon_config.max_rooms and layout.boss_id==layout.terminal_id and data.boss_definition!=null,"Expanded five floors each have real Boss")
			test.check(layout.relic_id not in [layout.start_id,layout.antique_id,layout.boss_id,&""] and layout.rooms[layout.relic_id].room_type==RoomDefinition.Type.RELIC,"One distinct safe relic-room node")
			var loot := AntiqueLootService.new()
			loot.configure(seed_value,number,layout,data.combat_cache_count)
			test.check(loot.selected_rooms.size()==1,"Battle density never increases antique quantity")
	for index in range(5):
		print("[9B.2 map average] F%d base_rooms=%.3f" % [index+1,map_sums[index]/100])
		if index>0 and index<4:test.check(map_sums[index]>map_sums[index-1],"Map scale expands F1 through F4")
	test.check(map_sums[4]<map_sums[3],"F5 contracts relative to F4 without becoming a small map")
	test.check(template_ids.size()>=15 and RelicRewardService.PRODUCTION_POOL.relics.size()>=20,"Fifteen battle templates and twenty formal relics")
	for seed_value in range(100):
		var plan := RelicRewardPlan.build(seed_value,5,RelicRewardService.PRODUCTION_POOL)
		var repeated := RelicRewardPlan.build(seed_value,5,RelicRewardService.PRODUCTION_POOL)
		var ids := {}
		for source in plan.assigned:
			ids[plan.assigned[source].id]=true
			test.check(plan.assigned[source]==repeated.assigned[source],"Source reward independent of pickup order")
		test.check(ids.size()==13 and plan.assigned.size()==13,"Thirteen sources without replacement")
	for number in range(1,6):
		var layout := TombFloorGenerator.generate(33,number,TOMB)
		print("[9B.2 map] Run33 F%d seed=%d rooms=%d boss=%s relic=%s" % [number,layout.seed_value,layout.rooms.size(),TOMB.floor_at(number).boss_definition.display_name,layout.relic_id])
