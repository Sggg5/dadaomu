extends PaperGeneral
var rotation_time:float=0
var rotation_tick:float=0
var skills_executed:int=0
var phases_seen:Dictionary={1:true}
var skill_history:Array[StringName]=[]
func _tick_ai(delta:float)->void:
	var previous:=volleys
	var was_winding:=winding
	var previous_decoys:=decoys.size()
	super._tick_ai(delta)
	if winding and not was_winding:
		var marker:=BossTelegraph.new()
		marker.actor=weakref(self)
		marker.player=target
		marker.shape=BossTelegraph.Shape.SECTOR
		marker.direction=aim_direction
		marker.radius=190
		marker.warning=0.65
		marker.damage=0
		encounter_room.add_child(marker)
		marker.global_position=global_position
	var ratio:=health.current_hp/health.max_hp
	if rage:phases_seen[2]=true
	if ratio<=0.28:phases_seen[3]=true
	if volleys>previous:
		skills_executed+=1
		skill_history.append(&"FAN")
		if rage:skills_executed+=1;skill_history.append(&"CROSS")
		if decoys.size()>previous_decoys:skills_executed+=1;skill_history.append(&"DECOYS")
		if ratio<=0.28 and not decoys.is_empty():
			rotation_time=0.8
			skills_executed+=1
			skill_history.append(&"ROTATE")
	if rotation_time>0:
		rotation_time-=delta
		rotation_tick-=delta
		if rotation_tick<=0:
			rotation_tick=0.2
			EnemyVolley.fire(self,Vector2.RIGHT.rotated(phase*4),2,PI,7,190)
