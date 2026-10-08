class_name SiteDefinition
extends Resource
## Archive/game fiction is separate from factual historical-period terminology.
@export var site_id:StringName
@export var region_id:StringName
@export var display_name:String
@export var historical_period:String
@export var culture_tags:Array[StringName]=[]
@export var site_type:String
@export var risk_tier:int=1
@export var tomb_definition:TombDefinition
@export var loot_profile_id:StringName=&"FORMAL_DEFAULT"
@export var unlock_status:StringName=&"INVESTIGATING"
@export var map_marker:Vector2
@export var background:String
@export var enemy_intel:String
@export var artifact_intel:String
func can_expedition()->bool:
	return unlock_status==&"AVAILABLE" and tomb_definition!=null and tomb_definition.validation_error().is_empty()
