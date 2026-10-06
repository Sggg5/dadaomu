class_name Projectile
extends CharacterBody2D
signal hit(context: ProjectileHitContext)
## 使用运动扫掠检测，避免高速弹丸只靠重叠检测穿过薄墙。
## 基础弹丸首次碰撞消耗；通用穿透参数与已命中集合，不知道任何遗物 ID。

var damage: float = 0.0
var remaining_lifetime: float = 0.0
var consumed: bool = false
var origin: Vector2
var pierce_remaining: int = 0
var tags: Array[StringName] = []
var _hit_ids: Dictionary[int, bool] = {}


func setup(request: AttackRequest) -> void:
	global_position = request.origin
	velocity = request.direction * request.speed
	rotation = request.direction.angle()
	damage = request.damage
	remaining_lifetime = request.lifetime
	origin = request.origin
	pierce_remaining = request.pierce_count
	scale = Vector2.ONE * request.projectile_scale
	tags = request.tags.duplicate()


func _physics_process(delta: float) -> void:
	if consumed:
		return
	remaining_lifetime -= delta
	if remaining_lifetime <= 0.0:
		_consume()
		return
	var collision := move_and_collide(velocity * delta)
	if collision:
		var target := collision.get_collider()
		if not is_instance_valid(target) or not target.has_method("take_damage"):
			_consume()
			return
		var target_id := target.get_instance_id()
		if _hit_ids.has(target_id):
			return
		_hit_ids[target_id] = true
		_apply_hit(target)
		if pierce_remaining > 0:
			pierce_remaining -= 1
			if target is CollisionObject2D:
				add_collision_exception_with(target)
		else:
			_consume()


func _apply_hit(target: Object) -> void:
	if is_instance_valid(target) and target.has_method("take_damage"):
		if target.call("take_damage", damage):
			var context := ProjectileHitContext.new()
			context.target = target
			context.position = global_position
			context.damage = damage
			context.origin = origin
			hit.emit(context)


func _consume() -> void:
	consumed = true
	queue_free()


func _draw() -> void:
	if tags.has(&"heavy"):
		draw_colored_polygon(PackedVector2Array([Vector2(-8,-10),Vector2(13,0),Vector2(-8,10)]), Color("b7e3ed"))
		return
	draw_circle(Vector2.ZERO, 5.0, Color("ffd479"))
	draw_line(Vector2(-9.0, 0.0), Vector2.ZERO, Color("c89346"), 3.0)
