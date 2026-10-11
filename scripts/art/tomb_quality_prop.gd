extends Node2D
## Uniform fitting over an exact masonry footprint, never a fake blocking object.
var footprint: Rect2
var asset_id: String
var texture: Texture2D
var door: Door
var last_open: bool = false
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture = ArtAssetCatalog.texture(asset_id)
	z_as_relative = false
	z_index = int(footprint.end.y) if door == null else -60
	if door != null:
		position = door.position
		rotation = door.rotation
func fitted_rect() -> Rect2:
	var native := Vector2(texture.get_width(), texture.get_height())
	var factor := minf(1, minf(footprint.size.x / native.x, (footprint.size.y + 24) / native.y))
	var size := native * factor
	return Rect2(Vector2(footprint.get_center().x - size.x * .5, footprint.end.y - size.y), size)
func _process(_delta: float) -> void:
	if door != null and door.is_open != last_open:
		last_open = door.is_open
		queue_redraw()
func _draw() -> void:
	if texture == null: return
	if door != null:
		if not door.is_open: draw_texture(texture, Vector2(-56, -14))
		else: draw_line(Vector2(-46, 0), Vector2(46, 0), Color(.3, .76, .58, .38), 2)
		return
	# The visible plinth spans exactly the existing solid footprint.
	draw_rect(footprint, Color("343a38"))
	draw_rect(footprint.grow(-2), Color("60695f"), false, 1)
	draw_texture_rect(texture, fitted_rect(), false)
