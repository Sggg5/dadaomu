class_name EnemyProjectile
extends Projectile
## 复用扫掠、速度快照、寿命和消耗；阵营通过独立掩码和命中方法限定。


func track_player(player: Player) -> void:
	player.died.connect(_consume)


func _apply_hit(target: Object) -> void:
	if target is Player:
		target.take_damage(damage)


func _draw() -> void:
	var points := PackedVector2Array([Vector2(8, 0), Vector2(0, 6), Vector2(-8, 0), Vector2(0, -6)])
	draw_colored_polygon(points, Color("ff6659"))
	points.append(points[0])
	draw_polyline(points, Color("ffe8cc"), 1.5)
