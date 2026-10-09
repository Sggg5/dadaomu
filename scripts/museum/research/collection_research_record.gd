class_name CollectionResearchRecord
extends RefCounted
## One actual accession, never a research-index ownership claim. Bounded append-only history.
const MAX_HISTORY:=64
var instance_id:StringName
var definition_id:StringName
var acquired_day:int
var source:Dictionary={}
var level:=0
var events:Array[Dictionary]=[]
var next_event:=1
var last_condition:=100
var last_identified:=false
func record(day:int,kind:String,actor:String,details:Dictionary={})->void:
	events.append({"event_id":next_event,"day_number":day,"kind":kind,"actor":actor,"details":details.duplicate(true)})
	next_event+=1
	if events.size()>MAX_HISTORY:events.pop_front()
func snapshot(item:OwnedAntique)->void:
	last_condition=item.condition;last_identified=item.identified
func values()->Dictionary:
	return {"instance_id":str(instance_id),"definition_id":str(definition_id),"acquired_day":acquired_day,"source":source.duplicate(true),"level":level,"events":events.duplicate(true),"next_event":next_event,"last_condition":last_condition,"last_identified":last_identified}
