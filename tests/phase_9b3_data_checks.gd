extends RefCounted
const TOMB:TombDefinition=preload("res://data/tombs/default_tomb.tres")
var test:SceneTree
func _init(context:SceneTree)->void:test=context
func run()->void:
	var definitions:Dictionary={}
	var bands:Dictionary={}
	for floor_number in range(1,6):
		var floor_data:=TOMB.floor_at(floor_number)
		test.check(floor_data.combat_cache_count==1,"Ordinary antique budget remains one")
		for template in floor_data.dungeon_config.templates:
			definitions[template.room_id]=true
			bands[template.threat_rating]=true
			for entry in template.spawns:
				for door in [Vector2(640,208),Vector2(1152,368),Vector2(640,528),Vector2(128,368)]:test.check(entry.position.distance_to(door)>=180,"New spawn entry safety")
				test.check(not template.obstacles.any(func(rect:Rect2)->bool:return rect.grow(24).has_point(entry.position)),"New spawn obstacle safety")
				for other in template.spawns:
					if other!=entry:test.check(entry.position.distance_to(other.position)>=48,"New spawn spacing")
	test.check(definitions.size()==30 and bands.size()==5,"Thirty templates cover five threat ratings")
	var stats:Array=[]
	for number in range(1,6):
		var combat_total:=0
		var count_total:=0
		var threats:Dictionary={}
		var families:Dictionary={}
		var elites:=0
		var environments:=0
		for seed_value in range(1000):
			var layout:=TombFloorGenerator.generate(seed_value,number,TOMB)
			var geometry:=RoomGeometryPlan.build(seed_value,number,layout,TOMB.floor_at(number).geometry_pool)
			test.check(layout.signature()==TombFloorGenerator.generate(seed_value,number,TOMB).signature(),"Encounter topology and template determinism")
			var loot:=AntiqueLootService.new()
			loot.configure(seed_value,number,layout,1)
			test.check(loot.selected_rooms.size()==1,"Every floor maintains fixed ordinary loot quantity")
			for room in layout.rooms.values():
				if room.room_type!=RoomDefinition.Type.COMBAT:continue
				combat_total+=1
				threats[room.definition.threat_rating]=threats.get(room.definition.threat_rating,0)+1
				count_total+=room.definition.spawns.size()
				var space:=geometry.assigned[room.room_id]
				environments+=int(not space.environments.is_empty() or &"COFFIN" in space.tags)
				for entry in room.definition.spawns:
					families[str(entry.enemy_definition.family_id)]=true
					elites+=int(entry.enemy_definition.elite)
		stats.append({"floor":number,"combat_rooms":combat_total,"threat_counts":threats,"enemy_families":families.keys(),"mean_initial_enemies":float(count_total)/combat_total,"elite_instances":elites,"environment_rooms":environments})
	var pool:=RelicRewardService.PRODUCTION_POOL
	test.check(pool.relics.size()==41,"Forty-one independent relic definitions")
	var ids:Dictionary={}
	var roles:Array[int]=[0,0,0,0]
	for item in pool.relics:
		test.check(not ids.has(item.id) and item.effect_script!=null and item.power_band>=1 and item.power_band<=4,"Unique usable relic metadata")
		ids[item.id]=true
		roles[item.design_role]+=1
	var signatures:Dictionary={}
	var frequencies:Dictionary={}
	var core_hist:Dictionary={}
	var powers:Array[int]=[]
	var source_roles:Dictionary={"ITEM":[0,0,0,0],"BOSS":[0,0,0,0],"MILESTONE":[0,0,0,0]}
	for seed_value in range(1000):
		var plan:=RelicRewardPlan.build(seed_value,5,pool)
		test.check(plan.signature()==RelicRewardPlan.build(seed_value,5,pool).signature(),"Profile plan deterministic")
		var chosen:Dictionary={}
		var cores:=0
		var power:=0
		for source in plan.assigned:
			var item:=plan.assigned[source]
			test.check(not chosen.has(item.id),"Formal rewards without replacement")
			chosen[item.id]=true
			cores+=int(item.design_role==RelicDefinition.DesignRole.CORE)
			power+=item.power_band
			frequencies[str(item.id)]=frequencies.get(str(item.id),0)+1
			var kind:="ITEM" if str(source).ends_with(":ITEM") else ("BOSS" if str(source).ends_with(":BOSS") else "MILESTONE")
			source_roles[kind][item.design_role]+=1
		test.check(chosen.size()==13 and cores>=2,"Thirteen sources retain minimum two usable core effects")
		signatures[plan.signature()]=true
		core_hist[cores]=core_hist.get(cores,0)+1
		powers.append(power)
	powers.sort()
	test.check(signatures.size()>950 and frequencies.size()==41 and powers[-1]>powers[0],"Broad plan variation and complete pool coverage")
	var report:={"encounters_1000_seeds":stats,"relic_roles":roles,"unique_plans":signatures.size(),"core_histogram":core_hist,"source_role_counts":source_roles,"relic_frequency":frequencies,"power_proxy_min":powers[0],"power_proxy_p10":powers[100],"power_proxy_median":powers[500],"power_proxy_p90":powers[900],"power_proxy_max":powers[-1]}
	var file:=FileAccess.open("res://logs/phase_9b3_statistics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("[9B.3 statistics] ",JSON.stringify(report))
