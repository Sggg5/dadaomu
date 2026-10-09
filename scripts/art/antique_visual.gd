class_name AntiqueVisual
extends RefCounted
## Eight independent fictional-game images; no reassignment to regional items.
const ORIGINAL_IDS := [&"republic_silver_coin",&"blue_white_jar",&"gilt_buddha",&"han_jade_disc",&"inlaid_bronze_mirror",&"tang_sancai_horse",&"gold_thread_jade",&"guardian_fragment"]
static func icon(id: StringName) -> Texture2D:
	return ArtAssetCatalog.texture(str(id)) if ArtRenderSettings.active() and id in ORIGINAL_IDS else null
static func draw(canvas: Node2D,id: StringName,at: Vector2,size: Vector2) -> bool:
	var texture := icon(id)
	if texture == null: return false
	canvas.draw_texture_rect(texture,Rect2(at-size*.5,size),false)
	return true
