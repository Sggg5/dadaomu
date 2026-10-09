class_name MuseumFacilityDefinition
extends RefCounted
## Config-derived stable identity; levels never mutate this definition.
var id:StringName
var hall_id:StringName
var unit_id:StringName=&""
var kind:StringName
var display_name:String
var unlock_level:=0
var max_level:=3
var costs:Array=[]
var maintenance:Array=[]
var interest_per_level:=0.0
var visual_status:String="PROCEDURAL_GODOT_2D"
