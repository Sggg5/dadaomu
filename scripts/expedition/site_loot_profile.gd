class_name SiteLootProfile
extends Resource
## Future regional selection interface. Only explicitly RELEASED pools may be activated.
@export var id:StringName=&"FORMAL_DEFAULT"
@export var status:StringName=&"RELEASED_EXISTING_ONLY"
@export var approved_pool:AntiquePool=preload("res://data/antiques/formal_pool.tres")
@export var local_artifact_types:Array[StringName]=[]
@export var historical_period_ranges:Array[String]=[]
@export var category_weights:Dictionary={}
@export var cross_region_types:Array[StringName]=[]
@export var rare_artifact_types:Array[StringName]=[]
func usable()->bool:
	# 11A deliberately exposes no new released regional pool; do not publish candidates.
	return id==&"FORMAL_DEFAULT" and status==&"RELEASED_EXISTING_ONLY" and approved_pool==preload("res://data/antiques/formal_pool.tres")
