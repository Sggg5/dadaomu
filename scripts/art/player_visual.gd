class_name PlayerVisual
extends Node2D
## Reads actor state only. The sprite has no collider, movement or weapon logic.
var actor: Node2D
var sprite: Sprite2D
var clock: float = 0.0
var attack_remaining: float = 0.0
var last_cell := Vector2i(-1,-1)
func _ready() -> void:
	show_behind_parent = true
	sprite = Sprite2D.new()
	sprite.show_behind_parent = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(0,-20)
	add_child(sprite)
	if actor is Player:
		actor.weapon.attack_requested.connect(func(_request: AttackRequest) -> void: attack_remaining = .12)
func _process(delta: float) -> void:
	clock += delta
	attack_remaining = maxf(0,attack_remaining-delta)
	visible = ArtRenderSettings.active() and ArtAssetCatalog.texture("actors") != null
	actor.z_index = clampi(int(actor.global_position.y+12),0,1000) if visible else 0
	if not visible:
		actor.queue_redraw()
		return
	var direction: Vector2 = actor.aim_direction if actor is Player else actor.facing
	var row := 3 if direction.y < 0 else 0
	if absf(direction.x) > absf(direction.y): row = 1 if direction.x < 0 else 2
	var column := 0 if actor.velocity.length() < 5 else 1 + int(clock * 8) % 2
	var hurt := false
	if actor is Player:
		if actor.health.is_dead: column = 5
		elif actor.invulnerability_remaining > 0: column = 4; hurt = true
		elif attack_remaining > 0: column = 3
	var cell := Vector2i(column,row)
	if cell != last_cell:
		sprite.texture = ArtAssetCatalog.frame("actors",column,row)
		last_cell = cell
	sprite.modulate = Color("ff8277") if hurt else Color.WHITE
	actor.queue_redraw()
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F6:
		ArtRenderSettings.mode = (ArtRenderSettings.mode+1)%3
		get_viewport().set_input_as_handled()
