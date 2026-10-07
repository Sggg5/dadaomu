class_name BronzeKing
extends Enemy
## 正面减伤→重砸→锁方向短冲→恢复；撞墙后绝不继续距离伤害。
enum State { GUARD, SLAM_WINDUP, RECOVERY, DASH_WINDUP, DASH }
var state: State = State.GUARD
var timer: float = 1.2
var direction: Vector2
var next_dash: bool = false
var guard_locked: bool = false
var slams: int = 0
var charges: int = 0
func take_damage(amount: float) -> bool:
	var frontal := is_instance_valid(target) and direction.dot((target.position-position).normalized())>0.55
	return super.take_damage(amount*0.45 if state==State.GUARD and frontal else amount)
func _tick_ai(delta: float) -> void:
	timer-=delta
	match state:
		State.GUARD:
			if not guard_locked:
				direction=aim_direction
				guard_locked=true
			move_actor(aim_direction,delta)
			if timer<=0:
				state=State.SLAM_WINDUP
				telegraphing=true
				timer=0.8
		State.SLAM_WINDUP:
			velocity=Vector2.ZERO
			if timer<=0:
				slams+=1
				if position.distance_to(target.position)<155 and has_line_to_target(): target.take_damage(scaled_damage(20))
				var pulse := CombatPulse.new()
				pulse.radius=155
				pulse.position=projectile_parent.to_local(global_position)
				projectile_parent.add_child(pulse)
				_recover(true)
		State.RECOVERY:
			if timer<=0:
				guard_locked=false
				state=State.DASH_WINDUP if next_dash else State.GUARD
				timer=0.55 if next_dash else 1.2
				telegraphing=next_dash
		State.DASH_WINDUP:
			if timer<=0:
				direction=aim_direction
				state=State.DASH
				timer=0.35
				telegraphing=false
		State.DASH:
			var hit := move_and_collide(direction*450*delta)
			if hit:
				if hit.get_collider()==target: target.take_damage(scaled_damage(18))
				_recover(false)
			elif position.distance_to(target.position)<42 and has_line_to_target():
				target.take_damage(scaled_damage(18))
				_recover(false)
			elif timer<=0: _recover(false)
func _recover(dash_next: bool) -> void:
	if not dash_next: charges+=1
	next_dash=dash_next
	state=State.RECOVERY
	timer=0.8
	telegraphing=false
	velocity=Vector2.ZERO
func _draw_body(color: Color) -> void:
	draw_rect(Rect2(-26,-26,52,52),color)
	if state==State.GUARD: draw_arc(Vector2.ZERO,32,direction.angle()-0.9,direction.angle()+0.9,16,Color("8cd5cd"),5)
	if state==State.SLAM_WINDUP: draw_arc(Vector2.ZERO,155,0,TAU,48,Color("ff8654"),2)
