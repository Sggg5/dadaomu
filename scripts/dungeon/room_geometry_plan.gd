class_name RoomGeometryPlan
extends RefCounted
## 后装配空间，不修改DungeonLayout/模板/任何其它RNG。稳定邻居去重与中央障碍配额。
const GEOMETRY_VERSION:int=2
var assigned:Dictionary[StringName,RoomGeometryDefinition]={}
static func pick(run_seed:int,floor_number:int,room_id:StringName,pool_id:StringName,candidates:Array[RoomGeometryDefinition])->RoomGeometryDefinition:
	assert(not candidates.is_empty(),"No legal geometry candidates")
	var ordered:Array[RoomGeometryDefinition]=candidates.duplicate()
	ordered.sort_custom(func(a:RoomGeometryDefinition,b:RoomGeometryDefinition)->bool:return str(a.id)<str(b.id))
	var rng:=RandomNumberGenerator.new()
	rng.seed=AntiquePool.stable_score(run_seed,floor_number,room_id,StringName("GEOMETRY:%s"%pool_id),GEOMETRY_VERSION)
	var total:=0
	for geometry in ordered:total+=geometry.selection_weight
	var roll:=rng.randi_range(0,total-1)
	for geometry in ordered:
		roll-=geometry.selection_weight
		if roll<0:return geometry
	return ordered[-1]
static func build(run_seed:int,floor_number:int,layout:DungeonLayout,pool:RoomGeometryPool)->RoomGeometryPlan:
	assert(pool.validation_error().is_empty())
	var result:=RoomGeometryPlan.new()
	var ids:=layout.ordered_ids()
	ids.sort_custom(func(a:StringName,b:StringName)->bool:return layout.rooms[a].distance_from_start<layout.rooms[b].distance_from_start if layout.rooms[a].distance_from_start!=layout.rooms[b].distance_from_start else str(a)<str(b))
	var count:=0
	for id in ids:
		if layout.rooms[id].room_type==RoomDefinition.Type.COMBAT:count+=1
	# 小层也允许偶发中央布局；有限配额防止同层大量堆柱，整体占比由1000Seed专项守住。
	var central_budget:=int(ceil(count/10.0))
	for id in ids:
		var room:=layout.rooms[id]
		if room.room_type!=RoomDefinition.Type.COMBAT:
			if room.room_type!=RoomDefinition.Type.BOSS:
				var safe:=RoomGeometryDefinition.new()
				safe.id=StringName("SAFE_%s"%id)
				safe.tags=[&"SAFE"]
				result.assigned[id]=safe
			continue
		var candidates:Array[RoomGeometryDefinition]=[]
		for geometry in pool.geometries:
			if &"CENTRAL_BIG" in geometry.tags and central_budget<=0:continue
			var repeated:=false
			for neighbor in room.neighbors.values():
				if result.assigned.has(neighbor) and result.assigned[neighbor].id==geometry.id:repeated=true
			if not repeated:candidates.append(geometry)
		var selected:=pick(run_seed,floor_number,id,pool.id,candidates)
		result.assigned[id]=selected
		if &"CENTRAL_BIG" in selected.tags:central_budget-=1
	return result
func signature()->String:
	var rows:Array=[]
	var ids:Array=assigned.keys()
	ids.sort_custom(func(a:Variant,b:Variant)->bool:return str(a)<str(b))
	for id in ids:rows.append([str(id),str(assigned[id].id)])
	return JSON.stringify([GEOMETRY_VERSION,rows])
