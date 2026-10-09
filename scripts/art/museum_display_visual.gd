class_name MuseumDisplayVisual
extends RefCounted
## Facilities keep their original overlays/slots. This only supplies the base.
static func floor(canvas: Node2D) -> bool:
	var texture := ArtAssetCatalog.texture("parquet")
	if not ArtRenderSettings.active() or texture == null: return false
	canvas.draw_texture_rect(texture,Rect2(70,145,1140,470),true)
	var wall := ArtAssetCatalog.texture("wall")
	if wall != null: canvas.draw_texture_rect(wall,Rect2(70,145,1140,32),true,Color(1,.88,.7))
	return true
static func showcase(canvas: Node2D) -> bool:
	var texture := ArtAssetCatalog.texture("showcase")
	if not ArtRenderSettings.active() or texture == null: return false
	canvas.draw_texture_rect(texture,Rect2(-80,-48,160,108),false)
	return true
