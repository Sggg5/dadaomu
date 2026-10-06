class_name TombSpike
extends Node2D
## Boss局部拥有的一次性预警；停止/死亡取消，绝不持续每帧伤害。
var owner_boss: Enemy
var player: Player
var warning: float = 0.75
var visual: float = 0.25
var radius: float = 55
var damage: float
var remaining: float
var erupted: bool = false


func _ready() -> void: remaining = warning


func _physics_process(delta: float) -> void:
	if not is_instance_valid(owner_boss) or not owner_boss.can_act():
		queue_free()
		return
	remaining -= delta
	if remaining <= 0:
		if erupted:
			queue_free()
		else:
			erupted = true
			remaining = visual
			var ray := PhysicsRayQueryParameters2D.create(global_position,player.global_position,1)
			if global_position.distance_to(player.global_position) <= radius and get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): player.take_damage(damage)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO,radius,Color(1,.2,.1,.15))
	draw_arc(Vector2.ZERO,radius,0,TAU,32,Color("ff9860"),3)
	if erupted:
		draw_colored_polygon(PackedVector2Array([Vector2(-20,18),Vector2(0,-45),Vector2(20,18)]),Color("ffe1ac"))
	else:
		draw_arc(Vector2.ZERO,radius*clampf(1-remaining/warning,0,1),0,TAU,32,Color("ffe1ac"),2)
