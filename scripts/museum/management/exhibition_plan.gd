class_name ExhibitionPlan
extends RefCounted
## Stable hall/topic identities only. Owned instances stay in display assignments.
var hall_id: StringName
var topic_id: StringName
func _init(hall:StringName=&"",topic:StringName=&"")->void:
	hall_id=hall
	topic_id=topic
