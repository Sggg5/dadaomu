class_name ElitePaperSpirit
extends PaperSpirit
func _on_died()->void:
	if dying:return
	if encounter_room!=null:encounter_room.hazards.ring(position,5)
	super._on_died()
