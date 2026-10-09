class_name MuseumNPCVisual
extends RefCounted
## Row/column selected from stable identity; no visitor RNG consumption.
static func draw(canvas: Node2D, identity: int, walking: bool) -> bool:
	if not ArtRenderSettings.active(): return false
	var texture := ArtAssetCatalog.frame("museum_npcs",identity,1 if walking else 0)
	if texture == null: return false
	canvas.draw_texture_rect(texture,Rect2(-24,-52,48,64),false)
	return true
