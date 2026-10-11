extends Node2D
## Read-only real attacks/hits. One bounded effect buffer, no emitters or physics.
var room: Room
var effects: Array[Dictionary]=[]
var bullets: Dictionary={}
var tracked: Dictionary={}
var player_hp:float=0
func _ready() -> void:
	z_index=900
	room.combat_target.weapon.attack_requested.connect(on_fire)
	player_hp=room.combat_target.health.current_hp
	room.combat_target.health.changed.connect(on_player_health)
func on_player_health(current:float,_maximum:float) -> void:
	if current<player_hp:add_effect("hit",room.combat_target.global_position,Vector2.UP,.10)
	player_hp=current
func on_fire(request:AttackRequest) -> void:
	add_effect("fire",request.origin,request.direction,.075)
func add_effect(kind:String,point:Vector2,direction:Vector2,life:float) -> void:
	if effects.size()>=48:effects.pop_front()
	effects.append({"kind":kind,"point":to_local(point),"direction":direction,"left":life,"life":life})
func watch_health(actor:Enemy) -> void:
	var id:=actor.get_instance_id()
	if tracked.has(id):return
	tracked[id]=actor.health.current_hp
	actor.health.changed.connect(func(current:float,_maximum:float)->void:
		if is_instance_valid(actor) and current<tracked[id]:
			add_effect("death" if current<=0 else "hit",actor.global_position,Vector2.UP,.18 if current<=0 else .10)
		tracked[id]=current)
func _process(delta:float) -> void:
	visible=ArtRenderSettings.active()
	for effect in effects:effect.left-=delta
	effects=effects.filter(func(e:Dictionary)->bool:return e.left>0)
	for actor in room.damage_targets():
		if actor is Enemy:watch_health(actor)
	for bullet in room.projectiles.get_children():
		if bullet is Projectile and bullet.tags.is_empty():
			var id:=bullet.get_instance_id()
			if not bullets.has(id):bullets[id]=[weakref(bullet),bullet.modulate]
			bullet.modulate=Color(bullets[id][1],0) if visible else bullets[id][1]
	for id in bullets.keys():
		if not is_instance_valid(bullets[id][0].get_ref()):bullets.erase(id)
	queue_redraw()
func _draw() -> void:
	if not visible:return
	for pair in bullets.values():
		var bullet=pair[0].get_ref()
		if not is_instance_valid(bullet):continue
		var point:=to_local(bullet.global_position);var direction:Vector2=bullet.velocity.normalized()
		draw_line(point-direction*6,point,Color("bc9866"),2)
		draw_line(point-direction*2,point+direction*2,Color("ffe9ae"),3)
	for effect in effects:
		var p:Vector2=effect.point;var ratio:float=effect.left/effect.life
		if effect.kind=="fire":
			draw_line(p+effect.direction*10,p+effect.direction*18,Color(1,.86,.54,ratio),3)
		else:
			var color:=Color(.77,.67,.48,ratio)
			for v in [Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1)]:
				draw_line(p+v*4,p+v*(8+(1-ratio)*5),color,2)
func _exit_tree() -> void:
	for pair in bullets.values():
		var bullet=pair[0].get_ref()
		if is_instance_valid(bullet):bullet.modulate=pair[1]
