extends MechanismBoss
## 诱导撞墙/躲重砸产生2.5s破甲窗口；后期碎片扇射绑定风险。
var broken:float=0
var armor_direction:Vector2=Vector2.RIGHT
func _init()->void:phase_thresholds=[0.65,0.3]
func take_damage(amount:float)->bool:
	var frontal:=is_instance_valid(target) and armor_direction.dot((target.global_position-global_position).normalized())>0.55
	return super.take_damage(amount*0.45 if broken<=0 and frontal else amount)
func _tick_ai(delta:float)->void:
	broken=maxf(0,broken-delta)
	if state==&"RECOVERY" and broken<=0:armor_direction=aim_direction
	super._tick_ai(delta)
func choose_actions(_distance:float)->Array:
	var charge:=action(&"CHARGE",0.65,18,{"speed":450,"duration":0.65,"gap":0.1})
	var slam:=action(&"CIRCLE",0.8,18,{"count":1,"centered":true,"radius":205,"gap":0.1})
	if cycles%2==0:return [charge,slam] if phase_index>=2 or pressure_due() else [charge]
	return [slam,action(&"CIRCLE",0.65,18,{"count":1,"centered":true,"radius":205,"gap":0.1}),charge] if phase_index>=2 or cycles%4==3 else [slam]
func _on_skill_finished(kind:StringName)->void:
	if (kind==&"CHARGE" and wall_hit) or (kind==&"CIRCLE" and (global_position.distance_to(target.global_position)>205 or not has_line_to_target())):
		broken=2.5
		if phase_index==3 and kind==&"CHARGE":
			skills_executed+=1
			skill_history.append(&"FRAGMENTS")
			EnemyVolley.fire(self,-locked,5,0.3,10,260)
func _draw_body(color:Color)->void:
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE*body_radius()/37.0)
	draw_rect(Rect2(-26,-26,52,52),color)
	if broken>0:draw_line(Vector2(-20,-20),Vector2(20,20),Color("ffc06b"),5)
	else:draw_arc(Vector2.ZERO,34,armor_direction.angle()-0.9,armor_direction.angle()+0.9,20,Color("8cd5cd"),5)
	draw_set_transform(Vector2.ZERO)
