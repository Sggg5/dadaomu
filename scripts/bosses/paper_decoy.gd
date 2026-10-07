class_name PaperDecoy
extends Node2D
## 不可攻击的纸扎假身；弱弹干扰、三秒失效，本体红冠可区分。
var owner_boss: Enemy
var remaining: float = 3
var timer: float = 0.7
func _physics_process(delta: float) -> void:
	if not is_instance_valid(owner_boss) or not owner_boss.can_act(): queue_free(); return
	remaining-=delta
	timer-=delta
	if remaining<=0: queue_free(); return
	if timer<=0 and owner_boss.projectile_parent.get_child_count()<256:
		timer=1.0
		var request := AttackRequest.new()
		request.origin=global_position
		request.direction=(owner_boss.target.global_position-global_position).normalized()
		request.damage=owner_boss.scaled_damage(4)
		request.speed=220
		request.lifetime=1.5
		var bullet := preload("res://scenes/enemies/enemy_projectile.tscn").instantiate() as EnemyProjectile
		owner_boss.projectile_parent.add_child(bullet)
		bullet.setup(request)
		bullet.track_player(owner_boss.target)
func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(0,-24),Vector2(20,0),Vector2(15,25),Vector2(-15,25),Vector2(-20,0)]),Color(0.75,0.72,0.56,0.5))
