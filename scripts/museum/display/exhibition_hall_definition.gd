class_name ExhibitionHallDefinition
extends RefCounted
## Stable data identity; a hall is not a scene instance or an owned collection.
var id: StringName
var display_name: String
var unlock_level: int
var unit_ids: Array[StringName] = []
