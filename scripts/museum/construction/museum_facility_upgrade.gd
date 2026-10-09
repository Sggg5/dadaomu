class_name MuseumFacilityUpgrade
extends RefCounted
## Quote binds expected level, destination and price; a consumed/stale request cannot pay twice.
var facility_id:StringName
var expected_level:int
var target_level:int
var price:int
var consumed:=false
