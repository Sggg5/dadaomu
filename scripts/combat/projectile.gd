class_name Projectile
extends CharacterBody2D
## 使用运动扫掠检测，避免高速弹丸只靠重叠检测穿过薄墙。
## 基础弹丸第一次碰撞即消耗；命中与表现分开，未来扩展在弹丸/武器策略中实现。

var damage: float = 0.0
var remaining_lifetime: float = 0.0
var consumed: bool = false


func setup(request: AttackRequest) -> void:
	global_position = request.origin
	velocity = request.direction * request.speed
	rotation = request.direction.angle()
	damage = request.damage
	remaining_lifetime = request.lifetime


func _physics_process(delta: float) -> void:
	if consumed:
		return
	remaining_lifetime -= delta
	if remaining_lifetime <= 0.0:
		_consume()
		return
	var collision := move_and_collide(velocity * delta)
	if collision:
		consumed = true
		var target := collision.get_collider()
		# 受击对象提供 take_damage(float)；墙没有该接口，仍会消耗弹丸。
		if is_instance_valid(target) and target.has_method("take_damage"):
			target.call("take_damage", damage)
		queue_free()


func _consume() -> void:
	consumed = true
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color("ffd479"))
	draw_line(Vector2(-9.0, 0.0), Vector2.ZERO, Color("c89346"), 3.0)
