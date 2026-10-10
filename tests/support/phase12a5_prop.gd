extends Node2D
## Native-size artwork: no nonuniform scale, no arbitrary resize of small coffins.
var footprint: Rect2
var asset_id: String
var texture: Texture2D
var source_size: Vector2
var last_open: bool=false
var door: Door
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	texture=ArtAssetCatalog.texture(asset_id)
	z_as_relative=false
	z_index=int(footprint.end.y) if door==null else -60
	if door!=null:
		position=door.position; rotation=door.rotation
func _process(_delta: float) -> void:
	if door!=null and door.is_open!=last_open:
		last_open=door.is_open; queue_redraw()
func _draw() -> void:
	if texture==null: return
	if door!=null:
		if not door.is_open: draw_texture(texture,Vector2(-56,-14))
		else: draw_line(Vector2(-46,0),Vector2(46,0),Color(.3,.76,.58,.38),2)
		return
	# Footprint matches the collider; relief rises north, southern base stays anchored.
	var size:=Vector2(texture.get_width(),texture.get_height())
	var point:=Vector2(footprint.get_center().x-size.x*.5,footprint.end.y-size.y)
	draw_texture(texture,point)
