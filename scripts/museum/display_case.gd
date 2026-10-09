class_name DisplayCase
extends MuseumInteractable
## Current-hall view of a DisplayUnit. Slot occupants are actual OwnedAntique instances.
var case_id: StringName
var state: MuseumState

func refresh() -> void:
	var unit := state.display_catalog.units[case_id]
	var items := state.unit_items(case_id)
	title = "%s · %s\n%d / %d位置 · 吸引力%d" % [unit.display_name,case_id,items.size(),unit.capacity,MuseumConstructionService.unit_interest(state,case_id)]
	if not items.is_empty(): title += "\n"+MuseumState.POOL.find_by_id(items[0].definition_id).display_name+(" 等%d件" % items.size() if items.size()>1 else "")
	if not items.is_empty():title+="\n首件品相%d"%items[0].condition if items[0].identified else "\n首件未鉴定"
	super.refresh()
	label.position=Vector2(-100,55)
	label.size=Vector2(200,75)
	label.add_theme_font_size_override("font_size",14)

func _draw() -> void:
	if state==null or not state.display_catalog.units.has(case_id): return
	var unit:=state.display_catalog.units[case_id]
	if unit.kind=="DISPLAY_WALL":
		draw_rect(Rect2(-83,-47,166,90),Color("b3a692"))
		draw_rect(Rect2(-77,-41,154,78),Color("343c45"))
	elif unit.kind=="LARGE_PLATFORM":
		draw_colored_polygon(PackedVector2Array([Vector2(-75,-30),Vector2(55,-45),Vector2(80,30),Vector2(-55,45)]),Color("7b7972"))
		draw_rect(Rect2(-52,32,104,17),Color("494a47"))
	elif not MuseumDisplayVisual.showcase(self):
		# Timber plinth, legs, brass frame and a sloped glass top; not a plain square.
		draw_rect(Rect2(-58,27,116,22),Color("57422e"))
		draw_rect(Rect2(-51,47,12,10),Color("392b20"))
		draw_rect(Rect2(39,47,12,10),Color("392b20"))
		draw_colored_polygon(PackedVector2Array([Vector2(-78,-34),Vector2(64,-45),Vector2(78,27),Vector2(-64,38)]),Color("354e57"))
		draw_polyline(PackedVector2Array([Vector2(-78,-34),Vector2(64,-45),Vector2(78,27),Vector2(-64,38),Vector2(-78,-34)]),Color("c4a86b"),3)
		draw_line(Vector2(-64,-26),Vector2(58,-35),Color("89bfc4"),2)
	var light:=MuseumConstructionService.unit_level(state,case_id,&"LIGHT")
	var base:=MuseumConstructionService.unit_level(state,case_id,&"BASE")
	var plaque:=MuseumConstructionService.unit_level(state,case_id,&"LABEL")
	var protection:=MuseumConstructionService.unit_level(state,case_id,&"PROTECT")
	if light>0:
		draw_rect(Rect2(-69,-39,132,4+light),Color("efcf83"))
		for i in range(light*2):draw_circle(Vector2(-57+i*114.0/maxi(1,light*2-1),-33),3+light,Color("fff0b6"))
	if protection>0:
		draw_rect(Rect2(-80,-47,160,85),Color("83adbc"),false,1+protection)
		draw_rect(Rect2(-6,29,12,12),Color("c6a257"))
		draw_circle(Vector2(0,34),2,Color("423725"))
	if plaque>0:
		draw_rect(Rect2(-31,27,62,14+plaque*2),Color("e9ddbd"))
		for i in range(plaque+1):draw_line(Vector2(-25,31+i*3),Vector2(22,31+i*3),Color("776b54"),1)
	var columns:=4 if unit.capacity>=8 else 2 if unit.capacity==4 else 1
	var rows:=ceili(unit.capacity/float(columns))
	for slot in unit.slots():
		var center:=Vector2(-54+108*(slot.index%columns+.5)/columns,-28+53*(floori(slot.index/float(columns))+.5)/rows)
		var cell:=Vector2(minf(26,108.0/columns-3),53.0/rows-3)
		draw_rect(Rect2(center-cell*.5,cell),Color("24343e"))
		var item:=state.collection.find(state.display_assignments.get(slot.id,&""))
		if base>0:draw_rect(Rect2(center-cell*.5+Vector2(0,cell.y-4),Vector2(cell.x,4)),Color("a28359"))
		if item!=null: DisplayArtifactGlyph.draw_icon(self,item.definition_id,center, minf(.85,cell.y/24.0)*(1.0+base*.025))
