class_name ExplodingCorpse
extends Enemy
var winding:bool=false
var timer:float=0
var blast_queued:bool=false
func _tick_ai(delta:float)->void:
	if winding:
		timer-=delta
		if timer<=0:health.take_damage(health.max_hp)
	else:
		move_actor(aim_direction,delta)
		if position.distance_to(target.position)<115 and has_line_to_target():
			winding=true
			telegraphing=true
			timer=0.8
			_queue_blast(0.8)
func _queue_blast(delay:float)->void:
	if blast_queued or encounter_room==null:return
	blast_queued=true
	encounter_room.hazards.blast(position,delay,76,definition.contact_damage)
func _on_died()->void:
	if dying:return
	_queue_blast(0.6)
	super._on_died()
func _draw_body(color:Color)->void:
	draw_circle(Vector2.ZERO,18 if winding else 14,Color("d47764") if winding else color)
	draw_circle(Vector2.ZERO,7,Color("624238"))
