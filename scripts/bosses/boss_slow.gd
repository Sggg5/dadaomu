class_name BossSlow
extends Node
var player:Player
var time:float=0.6
func _ready()->void:player.encounter_movement_modifiers[get_instance_id()]=0.75
func _physics_process(delta:float)->void:
	time-=delta
	if time<=0 or not is_instance_valid(player) or player.health.is_dead:queue_free()
func _exit_tree()->void:
	if is_instance_valid(player):player.encounter_movement_modifiers.erase(get_instance_id())
