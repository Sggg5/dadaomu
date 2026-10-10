class_name EnemyVisual
extends Node2D
var actor: Enemy
var sprite: Sprite2D
var clock: float = 0.0
var last_column: int = -1
func supported() -> bool:
	return actor != null and actor.definition != null and actor.definition.id in [&"scarab", &"bandit_shooter"] and ArtAssetCatalog.texture("actors") != null
func _ready() -> void:
	show_behind_parent = true
	sprite = Sprite2D.new()
	sprite.show_behind_parent = true
	sprite.position = Vector2(0,-20)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
func _process(delta: float) -> void:
	clock += delta
	visible = ArtRenderSettings.active() and supported()
	actor.z_index = clampi(int(actor.global_position.y+12),0,1000) if visible else 0
	if not visible:
		actor.queue_redraw()
		return
	var column := 0 if actor.velocity.length() < 5 else 1 + int(clock * 8) % 2
	if actor.dying: column = 5
	elif actor._flash_remaining > 0: column = 4
	elif actor.telegraphing: column = 3
	if last_column != column:
		sprite.texture = ArtAssetCatalog.frame("actors",column,4 if actor.definition.id == &"scarab" else 5)
		last_column = column
	sprite.modulate = Color("ff8277") if actor._flash_remaining > 0 else Color.WHITE
	# Lift dark scarab midtones only in textured modes; HP/AI/hit radius unchanged.
	if actor.definition.id == &"scarab" and actor._flash_remaining <= 0:
		sprite.modulate = Color(1.22,1.16,1.06)
	actor.queue_redraw()
