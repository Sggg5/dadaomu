extends RefCounted
const TOMB:TombDefinition=preload("res://data/tombs/default_tomb.tres")
const POOL:RoomGeometryPool=preload("res://data/geometries/ordinary_pool.tres")
const ARENAS:BossArenaPool=preload("res://data/geometries/arenas/boss_pool.tres")
var test:SceneTree
func _init(context:SceneTree)->void:test=context
func run()->void:
	var counts:Dictionary={}
	var arena_counts:Dictionary={}
	var encounter_geometries:Dictionary={}
	var cached_spawns:Dictionary={}
	for entry:Variant in POOL.geometries+ARENAS.geometries:
		var geometry:=entry as RoomGeometryDefinition
		test.check(RoomGeometryValidation.validation_error(geometry).is_empty(),"All entry corridors/main regions connected: "+str(geometry.id))
	var total:=0
	var central:=0
	for seed_value in range(1000):
		var boss_plan:=BossRunPlan.build(seed_value,TOMB)
		var relic_before:=RelicRewardPlan.build(seed_value,5,RelicRewardService.PRODUCTION_POOL).signature()
		for floor_number in range(1,6):
			var layout:=TombFloorGenerator.generate(seed_value,floor_number,TOMB)
			var signature:=layout.signature()
			var risk_before:=TombExplorationPlan.build(layout,seed_value,floor_number)
			var antique_before:=RoomController.ANTIQUE_POOL.pick(seed_value,floor_number,layout.antique_id,&"antique_room").id
			var profile:=TOMB.floor_at(floor_number).antique_reward_profile
			var profiled_before:=RoomController.ANTIQUE_POOL.pick_profiled(seed_value,floor_number,layout.antique_id,&"antique_room",profile).id
			var loot_before:=AntiqueLootService.new()
			loot_before.configure(seed_value,floor_number,layout,1)
			var plan:=RoomGeometryPlan.build(seed_value,floor_number,layout,POOL)
			var risk_after:=TombExplorationPlan.build(layout,seed_value,floor_number)
			test.check(risk_before.layout.signature()==risk_after.layout.signature() and risk_before.events==risk_after.events and risk_before.secret_id==risk_after.secret_id and risk_before.fork==risk_after.fork,"Geometry cannot disturb risk-event independent random stream")
			test.check(plan.signature()==RoomGeometryPlan.build(seed_value,floor_number,layout,POOL).signature(),"Independent geometry determinism")
			test.check(layout.signature()==signature,"Geometry leaves topology/template signature unchanged")
			for id in plan.assigned:
				var geometry:=plan.assigned[id]
				var room:=layout.rooms[id]
				for neighbor in room.neighbors.values():
					if plan.assigned.has(neighbor):test.check(plan.assigned[neighbor].id!=geometry.id,"Adjacent rooms never repeat geometry ID")
				if room.room_type!=RoomDefinition.Type.COMBAT:continue
				counts[geometry.id]=counts.get(geometry.id,0)+1
				total+=1
				central+=int(&"CENTRAL_BIG" in geometry.tags)
				if not encounter_geometries.has(room.definition.room_id):encounter_geometries[room.definition.room_id]={}
				encounter_geometries[room.definition.room_id][geometry.id]=true
				var key:=str(room.definition.room_id)+":"+str(geometry.id)
				if not cached_spawns.has(key):cached_spawns[key]=EnemySpawnPlacement.build(room.definition,geometry)
				var placement:EnemySpawnPlacement=cached_spawns[key]
				test.check(placement.error.is_empty() and placement.positions.size()==room.definition.spawns.size(),"Whole initial wave fits legal geometry")
			var definition:=boss_plan.boss_for_floor(floor_number)
			var arena:=BossArenaPlan.pick(seed_value,floor_number,layout.boss_id,ARENAS,definition)
			if not arena_counts.has(definition.id):arena_counts[definition.id]={}
			arena_counts[definition.id][arena.id]=arena_counts[definition.id].get(arena.id,0)+1
			test.check(arena.tags.any(func(tag:StringName)->bool:return tag in definition.compatible_arena_tags),"Boss arena compatibility")
			test.check(arena.obstacles.all(func(rect:Rect2)->bool:return not rect.intersects(Rect2(500,270,280,200))),"Boss center remains open, no central pillar")
			var loot_after:=AntiqueLootService.new()
			loot_after.configure(seed_value,floor_number,layout,1)
			test.check(RoomController.ANTIQUE_POOL.pick(seed_value,floor_number,layout.antique_id,&"antique_room").id==antique_before and RoomController.ANTIQUE_POOL.pick_profiled(seed_value,floor_number,layout.antique_id,&"antique_room",profile).id==profiled_before and loot_before.selected_rooms==loot_after.selected_rooms,"Arena/geometry cannot consume legacy/profiled antique or cache RNG")
			test.check(BossRunPlan.build(seed_value,TOMB).signature()==boss_plan.signature(),"Arena cannot consume Boss choice RNG")
			test.check(RelicRewardPlan.build(seed_value,5,RelicRewardService.PRODUCTION_POOL).signature()==relic_before,"Geometry cannot consume Relic RNG")
	test.check(counts.size()==POOL.geometries.size() and counts.size()>=12,"Every ordinary geometry appears in1000Seeds")
	test.check(float(central)/total<=0.1,"Central coffin overall occurrence<=10percent")
	for definition_id in arena_counts:
		var data:BossDefinition
		for floor_number in range(1,6):
			for definition in TOMB.floor_at(floor_number).boss_pool.bosses:
				if definition.id==definition_id:data=definition
		test.check(arena_counts[definition_id].size()==ARENAS.compatible(data).size(),"Every compatible Boss arena has coverage: "+str(definition_id))
	for id in encounter_geometries:test.check(encounter_geometries[id].size()>1,"Same Encounter combines with distinct spaces across Runs")
	# Validate exact placements once per unique combination, including spacing/entries and padded bodies.
	for key in cached_spawns:
		var placement:EnemySpawnPlacement=cached_spawns[key]
		var geometry:RoomGeometryDefinition
		for candidate:Variant in POOL.geometries:
			if str(candidate.id)==str(key).split(":")[1]:geometry=candidate as RoomGeometryDefinition
		for index in range(placement.positions.size()):
			var point:=placement.positions[index]
			test.check(geometry.obstacles.all(func(rect:Rect2)->bool:return not rect.grow(24).has_point(point)),"Runtime planned spawn padded body never inside obstacle")
			for entry in [Vector2(640,208),Vector2(1152,368),Vector2(640,528),Vector2(128,368)]:test.check(point.distance_to(entry)>=180,"Runtime spawn entry180px")
			for previous in placement.positions.slice(0,index):test.check(point.distance_to(previous)>=48,"Runtime spawn spacing48px")
	var impossible:=RoomGeometryDefinition.new()
	impossible.obstacles=[Room.ROOM_RECT]
	var definition:=TOMB.floor_at(1).dungeon_config.templates[0]
	test.check(not EnemySpawnPlacement.build(definition,impossible).error.is_empty(),"No legal point is explicit failure, never wall spawn")
	for entry:Variant in POOL.geometries:
		var geometry:=entry as RoomGeometryDefinition
		var placement:=EnemySpawnPlacement.build(definition,geometry,Vector2(640,368),180)
		test.check(placement.error.is_empty() and placement.positions.all(func(point:Vector2)->bool:return point.distance_to(Vector2(640,368))>=180),"Risk ambush retains180px Player clearance after geometry replanning")
	var file:=FileAccess.open("res://logs/geometry_statistics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"seeds":1000,"ordinary_rooms":total,"central_rooms":central,"central_ratio":float(central)/total,"geometry_counts":counts,"boss_arena_counts":arena_counts,"encounter_geometry_counts":encounter_geometries,"validated_wave_pairs":cached_spawns.size()},"  "))
	print("[Geometry stats] total=",total," central=",central," geometries=",counts," arenas=",arena_counts)
