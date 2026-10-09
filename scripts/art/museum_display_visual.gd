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

static func furniture(canvas: Node2D, title: String) -> bool:
	if not ArtRenderSettings.active(): return false
	var ids := {"馆长办公室":"office","馆舍建设":"construction","鉴定台":"appraisal","修复台":"restoration","馆藏研究台":"research","情报板":"board","售票台":"ticket","古董商":"dealer"}
	var key := ""
	for name in ids:
		if title.begins_with(name): key = ids[name]; break
	if key.is_empty(): return false
	var texture := ArtAssetCatalog.texture(key)
	if texture == null: return false
	canvas.draw_texture_rect(texture,Rect2(-60,-56,120,90),false)
	return true

static func staff(museum: Museum) -> void:
	if not ArtRenderSettings.active(): return
	var offset := {&"APPRAISER":0,&"CONSERVATOR":0}
	for id in MuseumStaffService.active_ids(museum.state):
		var member: MuseumStaffMember = museum.state.staff.members[id]
		var job: StringName = MuseumStaffService.catalog()[id].job
		if job not in offset or member.assigned_hall != museum.active_hall_id: continue
		var at := Vector2(510 if job == &"APPRAISER" else 700,235)+Vector2(offset[job]*32,0)
		museum.draw_set_transform(at)
		MuseumNPCVisual.draw(museum,3 if job == &"APPRAISER" else 4,false)
		museum.draw_set_transform(Vector2.ZERO)
		offset[job] += 1
