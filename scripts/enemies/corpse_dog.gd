class_name CorpseDog
extends Enemy
## 锁方向直冲；碰墙立即停，碰人/近距最多一次，保留明显恢复。
enum State { CHASE, WINDUP, DASH, RECOVERY }
var state: State = State.CHASE
var timer: float = 0
var dash_direction: Vector2
var attacks: int = 0
func _tick_ai(delta: float) -> void:
	timer -= delta
	match state:
		State.CHASE:
			move_actor(aim_direction,delta)
			if position.distance_to(target.position)<210 and has_line_to_target():
				state=State.WINDUP
				timer=definition.windup_time
				telegraphing=true
		State.WINDUP:
			velocity=Vector2.ZERO
			if timer<=0:
				dash_direction=aim_direction
				state=State.DASH
				timer=0.35
				telegraphing=false
		State.DASH:
			var collision := move_and_collide(dash_direction*420*delta)
			if collision:
				if collision.get_collider()==target: target.take_damage(scaled_damage(definition.contact_damage))
				_recover()
			elif position.distance_to(target.position)<32 and has_line_to_target():
				target.take_damage(scaled_damage(definition.contact_damage))
				_recover()
			elif timer<=0: _recover()
		State.RECOVERY:
			velocity=Vector2.ZERO
			if timer<=0: state=State.CHASE
func _recover() -> void:
	attacks+=1
	state=State.RECOVERY
	timer=definition.attack_cooldown
func _draw_body(color: Color) -> void:
	draw_rect(Rect2(-18,-10,36,20),color)
	draw_line(Vector2.ZERO,aim_direction*22,Color("eee0b5"),4)
