class_name Projectile
extends CharacterBody2D
signal hit(context: ProjectileHitContext)
## 使用运动扫掠检测，避免高速弹丸只靠重叠检测穿过薄墙。
## 基础弹丸首次碰撞消耗；通用穿透参数与已命中集合，不知道任何遗物 ID。

var bounce_remaining: int = 0
var orbit_owner: WeakRef
var orbit_remaining: float = 0
var orbit_angle: float = 0
var homing_target: WeakRef
var homing_turn_rate: float = 0
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
	bounce_remaining = request.bounce_count
	orbit_owner = request.orbit_owner
	orbit_remaining = request.orbit_time
	orbit_angle = request.direction.angle()
	homing_target = request.homing_target
	homing_turn_rate = request.homing_turn_rate
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
	if homing_target != null:
		var actor := homing_target.get_ref() as Node2D
		if is_instance_valid(actor):
			var desired := (actor.global_position-global_position).normalized()*velocity.length()
			velocity = velocity.lerp(desired,minf(1,homing_turn_rate*delta)).normalized()*velocity.length()
	var displacement:=velocity*delta
	if orbit_remaining>0 and orbit_owner!=null:
		var owner:=orbit_owner.get_ref() as Node2D
		if is_instance_valid(owner):
			orbit_remaining-=delta
			orbit_angle+=delta*7
			displacement=owner.global_position+Vector2.RIGHT.rotated(orbit_angle)*32-global_position
			if orbit_remaining<=0:velocity=Vector2.RIGHT.rotated(orbit_angle+PI/2)*velocity.length()
	var collision := move_and_collide(displacement)
	if collision:
		var target := collision.get_collider()
		if not is_instance_valid(target) or not target.has_method("take_damage"):
			if bounce_remaining>0:
				bounce_remaining-=1
				velocity=velocity.bounce(collision.get_normal())
				return
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
			context.hit_count = _hit_ids.size()
			context.tags = tags.duplicate()
			context.direction = velocity.normalized()
			context.target = target
			context.position = global_position
			context.damage = damage
			context.origin = origin
			hit.emit(context)


func _consume() -> void:
	consumed = true
	queue_free()


func _draw() -> void:
	if tags.has(&"soul"):
		draw_circle(Vector2.ZERO,6,Color("99dedd"))
		draw_arc(Vector2.ZERO,9,0,TAU,16,Color("60a1ba"),2)
		return
	if tags.has(&"heavy"):
		draw_colored_polygon(PackedVector2Array([Vector2(-8,-10),Vector2(13,0),Vector2(-8,10)]), Color("b7e3ed"))
		return
	draw_circle(Vector2.ZERO, 5.0, Color("ffd479"))
	draw_line(Vector2(-9.0, 0.0), Vector2.ZERO, Color("c89346"), 3.0)
