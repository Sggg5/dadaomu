class_name PlayerVisual
extends Node2D
## Visual only: locomotion owns the body; mouse aim owns weapon presentation.
## Never writes collider, attack origin, movement or stats.
var actor: Node2D
var sprite: Sprite2D
var clock: float = 0.0
var attack_remaining: float = 0.0
var last_cell := Vector2i(-1,-1)
var body_row: int = 0
var was_moving: bool = false
var use_old_art: bool = false # Isolated comparison only, never persisted.
var size_variant: int = 20 # Native rasters; no fractional sprite scaling.
var last_atlas: Texture2D
func _ready() -> void:
	show_behind_parent = true
	sprite = Sprite2D.new()
	sprite.show_behind_parent = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	if actor is Player:
		actor.weapon.attack_requested.connect(func(_request: AttackRequest) -> void: attack_remaining = .12)
func direction_row(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y): return 1 if direction.x < 0 else 2
	return 3 if direction.y < 0 else 0
func _process(delta: float) -> void:
	attack_remaining = maxf(0,attack_remaining-delta)
	visible = ArtRenderSettings.active() and ArtAssetCatalog.texture("actors") != null
	actor.z_index = clampi(int(actor.global_position.y+12),0,1000) if visible else 0
	if not visible:
		actor.queue_redraw()
		return
	var moving: bool = actor.velocity.length() > 8
	if moving:
		# Hysteresis near diagonals avoids horizontal/vertical pose flicker.
		var next_row := direction_row(actor.velocity)
		var vertical := body_row == 0 or body_row == 3
		var next_vertical := next_row == 0 or next_row == 3
		if vertical == next_vertical or absf(absf(actor.velocity.x)-absf(actor.velocity.y)) > 12:
			body_row = next_row
		if not was_moving: clock = 0
		clock += delta
	else: clock = 0
	was_moving = moving
	var dead: bool = actor is Player and actor.health.is_dead
	var hurt: bool = actor is Player and actor.invulnerability_remaining > 0
	var column := (1 + int(clock * 8) % 2) if moving else 0
	if dead: column = 3
	var atlas := ArtAssetCatalog.texture("player_body_%d" % size_variant)
	if use_old_art or atlas == null:
		sprite.position = Vector2(0,-20)
		if last_atlas != ArtAssetCatalog.texture("actors") or last_cell != Vector2i(column,body_row):
			sprite.texture = ArtAssetCatalog.frame("actors",5 if dead else column,body_row)
		last_atlas = ArtAssetCatalog.texture("actors")
	else:
		if last_atlas != atlas or last_cell != Vector2i(column,body_row):
			var frame_texture := AtlasTexture.new()
			frame_texture.atlas = atlas
			frame_texture.region = Rect2(column*64,body_row*80,64,80)
			sprite.texture = frame_texture
		last_atlas = atlas
		# Native foot line76 maps to world foot line+12 in every pose.
		sprite.position = Vector2(0,-24)
	last_cell = Vector2i(column,body_row)
	# Hurt tint never replaces a stride with an unrelated pose.
	sprite.modulate = Color("ff8277") if hurt else Color.WHITE
	queue_redraw()
	actor.queue_redraw()
func _draw() -> void:
	# Thin grounding ellipse at the visual foot line; no physics or new child.
	if visible and not use_old_art:
		draw_set_transform(Vector2(0,13),0,Vector2(1,.23))
		draw_circle(Vector2.ZERO,15,Color(.02,.035,.04,.28))
		draw_set_transform(Vector2.ZERO)
	if not visible or not actor is Player or actor.health.is_dead or use_old_art: return
	if last_atlas == null or last_atlas == ArtAssetCatalog.texture("actors"): return
	# Independent weapon illustration; gameplay muzzle remains actor origin.
	var aim: Vector2 = actor.aim_direction
	var recoil := 2.0 * attack_remaining / .12
	var hand := aim * (10-recoil) + Vector2(0,-20)
	var end := hand + aim*16
	draw_line(hand,end,Color("443c30"),6)
	draw_line(hand-Vector2(0,1),end-Vector2(0,1),Color("b9b29a"),2)
	draw_circle(hand,3,Color("ba9970"))
	if attack_remaining > .09: draw_line(end,end+aim*4,Color("ffe0a0"),3)
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F6:
		ArtRenderSettings.mode = (ArtRenderSettings.mode+1)%3
		get_viewport().set_input_as_handled()
