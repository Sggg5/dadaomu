extends Node2D
## Sibling visual: never inherits Enemy's gameplay death-scale or changes its AI.
var actor: Enemy
var sprite: Sprite2D
var atlas: Texture2D
var original_tint: Color
var clock: float=0
var state_clock: float=0
var pose: String="idle"
var direction: int=0
var cell: int=-1
var seen_states: Dictionary={}
var seen_directions: Dictionary={}
var previous_hp: float=0
var hit_time: float=0
var warning: Node2D
var frame_cache: Array[AtlasTexture]=[]
func _ready() -> void:
	original_tint=actor.modulate;previous_hp=actor.health.current_hp
	atlas=ArtAssetCatalog.texture("a6_"+str(actor.definition.id))
	sprite=Sprite2D.new();sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position=Vector2(0,-12);add_child(sprite)
	for index in range(64):
		var frame:=AtlasTexture.new();frame.atlas=atlas
		frame.region=Rect2((index%8)*64,int(index/8)*64,64,64);frame_cache.append(frame)
	warning=Node2D.new();warning.name="EnemyWarning_"+str(actor.get_instance_id());warning.z_index=950;get_parent().add_child(warning)
	warning.draw.connect(draw_warning)
	actor.health.changed.connect(on_health)
	# The isolated playtest starts paused: bind a complete native pose immediately.
	_process(0)
func on_health(current: float,_maximum: float) -> void:
	if current<previous_hp:hit_time=.12
	previous_hp=current
func facing(vector:Vector2) -> int:
	if absf(vector.x)>absf(vector.y):return 1 if vector.x<0 else 2
	return 3 if vector.y<0 else 0
func _process(delta:float) -> void:
	if not is_instance_valid(actor):queue_free();return
	visible=ArtRenderSettings.active() and atlas!=null
	actor.modulate=Color(original_tint,0) if visible else original_tint
	warning.visible=visible and actor.telegraphing and not actor.dying
	if not visible:return
	global_position=actor.global_position;warning.global_position=global_position
	z_index=clampi(int(global_position.y+12),0,1000)
	clock+=delta;hit_time=maxf(0,hit_time-delta)
	var next_pose: String="walk" if actor.velocity.length()>5 else "idle"
	if actor.dying:next_pose="death"
	elif hit_time>0:next_pose="hurt"
	elif actor.telegraphing:next_pose="windup"
	elif actor is CorpseDog and actor.state==CorpseDog.State.DASH:next_pose="attack"
	elif actor is ScarabEnemy and actor.state==ScarabEnemy.State.RECOVERY:next_pose="attack"
	if pose!=next_pose:pose=next_pose;state_clock=0
	state_clock+=delta;seen_states[pose]=true
	if not actor.dying:
		var vector:Vector2=actor.velocity if actor.velocity.length()>5 else actor.aim_direction
		if actor is CorpseDog and actor.state==CorpseDog.State.DASH:vector=actor.dash_direction
		direction=facing(vector)
	seen_directions[direction]=true
	var offset:int=0
	match pose:
		"idle":offset=int(clock*3)%2
		"walk":offset=2+int(clock*10)%4
		"windup":offset=6+mini(1,int(state_clock/maxf(.01,actor.definition.windup_time)*2))
		"attack":offset=8+mini(1,int(state_clock*14))
		"hurt":offset=10+mini(1,int(state_clock*20))
		"death":offset=12+mini(3,int((actor.definition.death_duration-actor._death_remaining)/maxf(.01,actor.definition.death_duration)*4))
	var next_cell:int=direction*16+offset
	if cell!=next_cell:cell=next_cell;sprite.texture=frame_cache[cell]
	sprite.modulate=Color("ffb3a0") if hit_time>0 else Color.WHITE
	queue_redraw();warning.queue_redraw()
func _draw() -> void:
	if not visible or not is_instance_valid(actor):return
	draw_set_transform(Vector2(0,9),0,Vector2(1,.28))
	draw_circle(Vector2.ZERO,16,Color(0.025,.02,.015,.28));draw_set_transform(Vector2.ZERO)
	if not actor.dying and (actor.health.current_hp<actor.health.max_hp or actor.telegraphing):
		draw_rect(Rect2(-14,-39,28,3),Color("202826"))
		draw_rect(Rect2(-14,-39,28*actor.health.current_hp/actor.health.max_hp,2),Color("baa779"))
func draw_warning() -> void:
	if not is_instance_valid(actor) or not warning.visible:return
	warning.draw_arc(Vector2.ZERO,23,0,TAU,24,Color("ff784f"),2)
	if actor is CorpseDog:
		warning.draw_line(Vector2.ZERO,actor.aim_direction*22,Color("eee0b5"),4)
func _exit_tree() -> void:
	if is_instance_valid(actor):actor.modulate=original_tint
	if is_instance_valid(warning):warning.queue_free()
