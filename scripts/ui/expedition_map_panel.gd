class_name ExpeditionMapPanel
extends CanvasLayer
## UI proposes an ID only; GameFlow validates and snapshots confirmation before save/transition.
signal expedition_selected(site_id:StringName)
var registry:SiteRegistry
var state:MuseumState
var player:MuseumPlayer
var panel:Panel
var title:Label
var detail:RichTextLabel
var sites_list:ItemList
var confirm_button:Button
var nodes:Array[RegionMapNode]=[]
var selected_region:StringName=&""
var selected_site:StringName=&""
var _site_ids:Array[StringName]=[]
var _submitted:bool=false
func _ready()->void:
	layer=36
	panel=Panel.new()
	panel.position=Vector2(45,52)
	panel.size=Vector2(1190,624)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("292b25")
	style.border_color=Color("b8a576")
	style.set_border_width_all(3)
	panel.add_theme_stylebox_override("panel",style)
	add_child(panel)
	title=Label.new()
	title.position=Vector2(24,16)
	title.text="中国远征调查图 · 民国二十二年 / 1933"
	title.add_theme_font_size_override("font_size",25)
	panel.add_child(title)
	var map:=TextureRect.new()
	map.position=Vector2(20,70)
	map.size=Vector2(650,440)
	map.texture=preload("res://assets/maps/china_survey_1933.svg")
	map.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_child(map)
	for region in registry.regions:
		var node:=RegionMapNode.new()
		node.definition=region
		node.position=Vector2(20,70)+region.map_marker-Vector2(42,22)
		node.size=Vector2(84,70)
		node.selected.connect(select_region)
		panel.add_child(node)
		nodes.append(node)
	var note:=Label.new()
	note.position=Vector2(24,522)
	note.text="手绘方位示意 · 非精确疆界 / 导航地图\n朱点：调查地区　|　点击地区后查阅墓穴档案\n地点均为游戏虚构；馆藏研究资料并非墓中实物。"
	note.add_theme_font_size_override("font_size",16)
	panel.add_child(note)
	sites_list=ItemList.new()
	sites_list.position=Vector2(690,70)
	sites_list.size=Vector2(475,135)
	sites_list.item_selected.connect(func(index:int)->void:select_site(_site_ids[index]))
	panel.add_child(sites_list)
	detail=RichTextLabel.new()
	detail.position=Vector2(692,220)
	detail.size=Vector2(465,298)
	detail.add_theme_font_size_override("normal_font_size",18)
	panel.add_child(detail)
	confirm_button=Button.new()
	confirm_button.position=Vector2(690,535)
	confirm_button.size=Vector2(475,45)
	confirm_button.text="确认远征"
	confirm_button.pressed.connect(confirm)
	panel.add_child(confirm_button)
	var back:=Button.new()
	back.position=Vector2(690,585)
	back.size=Vector2(220,30)
	back.text="返回地区图"
	back.pressed.connect(show_regions)
	panel.add_child(back)
	var close_button:=Button.new()
	close_button.position=Vector2(935,585)
	close_button.size=Vector2(230,30)
	close_button.text="关闭 [Tab / Esc]"
	close_button.pressed.connect(close)
	panel.add_child(close_button)
	panel.hide()
func open()->bool:
	if not state.can_edit():return false
	_submitted=false
	show_regions()
	panel.show()
	player.controls_enabled=false
	player.velocity=Vector2.ZERO
	return true
func show_regions()->void:
	selected_region=&""
	selected_site=&""
	_site_ids.clear()
	sites_list.clear()
	detail.text="请选择地图上的地区标记。\n\n晋北：五层路线已开放\n洛阳 / 关中：情报调查中\n\n关闭地图不会开始夜晚，也不会消耗当天远征。"
	confirm_button.disabled=true
	for node in nodes:node.highlighted=false;node.queue_redraw()
func select_region(id:StringName)->void:
	if _submitted or registry.region(id)==null:return
	selected_region=id
	selected_site=&""
	_site_ids.clear()
	sites_list.clear()
	for site in registry.sites_in(id):
		_site_ids.append(site.site_id)
		sites_list.add_item(site.display_name+(" · 可远征" if registry.can_depart(site.site_id) else " · 情报调查中"))
	for node in nodes:node.highlighted=node.definition.region_id==id;node.queue_redraw()
	detail.text=registry.region(id).display_name+"调查档案\n请选择具体地点，确认前不会出发。"
	confirm_button.disabled=true
func select_site(id:StringName)->void:
	var site:=registry.site(id)
	if _submitted or site==null or site.region_id!=selected_region:return
	selected_site=id
	var status:="可远征 · 完整五层" if registry.can_depart(site.site_id) else "情报调查中 · 尚未制作 / 无法远征"
	detail.text="%s · %s\n时期：%s\n危险：%s / 5　|　%s\n\n%s\n\n敌人与机关：%s\n\n可能器物：%s\n\n探索状态：%s"%[site.display_name,registry.region(site.region_id).display_name,site.historical_period,site.risk_tier,site.site_type,site.background,site.enemy_intel,site.artifact_intel,status]
	confirm_button.disabled=not registry.can_depart(site.site_id)
func confirm()->bool:
	var site:=registry.site(selected_site)
	if not panel.visible or _submitted or not state.can_edit() or site==null or not registry.can_depart(site.site_id):return false
	_submitted=true
	confirm_button.disabled=true
	expedition_selected.emit(site.site_id)
	return true
func reject(reason:String)->void:
	_submitted=false
	confirm_button.disabled=false
	detail.text=reason+"\n\n仍在博物馆；可以关闭地图后重试。"
func close()->void:
	if _submitted:return
	panel.hide()
	player.controls_enabled=state.phase!=MuseumState.Phase.NIGHT
func _input(event:InputEvent)->void:
	if panel.visible and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_TAB,KEY_ESCAPE]:
		close()
		get_viewport().set_input_as_handled()
