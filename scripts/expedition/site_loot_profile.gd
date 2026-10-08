class_name SiteLootProfile
extends Resource
## Independent regional RNG. Playtest admission is not scholarly/database approval.
const VERSION:int=1
@export var id:StringName=&"FORMAL_DEFAULT"
@export var status:StringName=&"RELEASED_EXISTING_ONLY"
@export var approved_pool:AntiquePool=preload("res://data/antiques/formal_pool.tres")
@export var local_artifact_types:Array[StringName]=[]
@export var historical_period_ranges:Array[String]=[]
@export var category_weights:Dictionary={}
@export var cross_region_types:Array[StringName]=[]
@export var rare_artifact_types:Array[StringName]=[]
@export var region_id:StringName
@export var max_manufacture_year:int=1933
@export var group_weights:PackedFloat32Array=PackedFloat32Array([70,20,10])
@export var local_ids:Array[StringName]=[]
@export var circulation_ids:Array[StringName]=[]
@export var heirloom_ids:Array[StringName]=[]
func eligible(item:AntiqueDefinition)->bool:
	if item==null:return false
	# Only two legacy early objects have a stated chronological admission; all unknowns rejected.
	if item.id==&"han_jade_disc":return max_manufacture_year>=220
	if item.id==&"inlaid_bronze_mirror":return max_manufacture_year>=-221
	return item.content_review_status==&"PLAYTEST_PENDING_HISTORICAL_REVIEW" and item.prototype_year_start<=item.prototype_year_end and item.prototype_year_end<=max_manufacture_year and region_id in item.region_ids
func usable()->bool:
	if id==&"FORMAL_DEFAULT":return status==&"RELEASED_EXISTING_ONLY" and approved_pool==preload("res://data/antiques/formal_pool.tres")
	if status!=&"PLAYTEST_PENDING_HISTORICAL_REVIEW" or approved_pool!=preload("res://data/antiques/playtest_catalog_50.tres") or max_manufacture_year>1933 or group_weights.size()!=3:return false
	var seen:Dictionary={}
	for ids in [local_ids,circulation_ids,heirloom_ids]:
		if ids.is_empty():return false
		for item_id in ids:
			if seen.has(item_id) or not eligible(approved_pool.find_by_id(item_id)):return false
			seen[item_id]=true
	for weight in group_weights:
		if not is_finite(weight) or weight<=0:return false
	return true
func group_for(item_id:StringName)->String:
	if item_id in local_ids:return "LOCAL"
	if item_id in circulation_ids:return "CIRCULATION"
	return "HEIRLOOM" if item_id in heirloom_ids else "REJECTED"
func pick(seed_value:int,floor_number:int,room_id:StringName,source:StringName,quality:AntiqueRewardProfile=null,high_value:bool=false)->AntiqueDefinition:
	assert(usable())
	if id==&"FORMAL_DEFAULT":return approved_pool.pick_profiled(seed_value,floor_number,room_id,source,quality) if quality!=null else approved_pool.pick(seed_value,floor_number,room_id,source)
	var groups:Array[Array]=[[],[],[]]
	var total:=0.0
	var ids_groups:Array=[local_ids,circulation_ids,heirloom_ids]
	for index in range(3):
		for item_id in ids_groups[index]:
			var item:=approved_pool.find_by_id(item_id)
			if eligible(item) and (not high_value or item.rarity>=AntiqueDefinition.Rarity.RARE):groups[index].append(item)
		groups[index].sort_custom(func(a:AntiqueDefinition,b:AntiqueDefinition)->bool:return str(a.id)<str(b.id))
		if not groups[index].is_empty():total+=group_weights[index]
	assert(total>0,"No chronological regional reward candidates")
	var rng:=RandomNumberGenerator.new()
	rng.seed=AntiquePool.stable_score(seed_value,floor_number,room_id,StringName("site:%s:%s"%[id,source]),VERSION)
	var roll:=rng.randf()*total
	var selected:Array=[]
	for index in range(3):
		if groups[index].is_empty():continue
		selected=groups[index]
		roll-=group_weights[index]
		if roll<0:break
	# Rarity is selected before individual items; larger type counts do not inflate one rarity.
	var by_rarity:Array[Array]=[[],[],[],[]]
	for item:AntiqueDefinition in selected:by_rarity[item.rarity].append(item)
	var rarity_total:=0.0
	for index in range(4):
		if not by_rarity[index].is_empty():rarity_total+=quality.rarity_weights[index] if quality!=null else 1.0
	if rarity_total<=0:
		for item:AntiqueDefinition in selected:rarity_total+=item.selection_weight
		roll=rng.randf()*rarity_total
		for item:AntiqueDefinition in selected:
			roll-=item.selection_weight
			if roll<0:return item
	else:
		roll=rng.randf()*rarity_total
		for index in range(4):
			if by_rarity[index].is_empty():continue
			roll-=quality.rarity_weights[index] if quality!=null else 1.0
			if roll<0:
				var item_total:=0.0
				for item:AntiqueDefinition in by_rarity[index]:item_total+=item.selection_weight
				var item_roll:=rng.randf()*item_total
				for item:AntiqueDefinition in by_rarity[index]:
					item_roll-=item.selection_weight
					if item_roll<0:return item
	return selected[-1]
