class_name MuseumReputationPanel
extends CanvasLayer
## Bounded read-only ledger. All writes come from gameplay services, never open/refresh.
signal archive_requested(id:StringName)
var state:MuseumState
var player:MuseumPlayer
var panel:PanelContainer
var tabs:TabContainer
var overview:RichTextLabel
var goals:ItemList
var goal_detail:RichTextLabel
var catalog_list:ItemList
var catalog_detail:RichTextLabel
var region:OptionButton
var category:OptionButton
var period:OptionButton
var rarity:OptionButton
var status:OptionButton
var search:LineEdit
var rows:Array[Dictionary]=[]
var page:=0
var heading:Label
var dossier:Button
var selected_id:StringName=&""
var _previous:=false
func text()->RichTextLabel:
	var label:=RichTextLabel.new();label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.size_flags_vertical=Control.SIZE_EXPAND_FILL;label.add_theme_font_size_override("normal_font_size",19);label.add_theme_color_override("default_color",Color("34291d"));return label
func button(parent:Node,title:String,action:Callable)->Button:
	var b:=Button.new();b.text=title;b.pressed.connect(action);parent.add_child(b);return b
func _ready()->void:
	layer=47;panel=PanelContainer.new();panel.position=Vector2(75,65);panel.size=Vector2(1130,600);add_child(panel)
	var paper:=StyleBoxFlat.new();paper.bg_color=Color("e8dcc0");paper.border_color=Color("715233");paper.set_border_width_all(5);paper.set_content_margin_all(18);panel.add_theme_stylebox_override("panel",paper)
	var box:=VBoxContainer.new();panel.add_child(box)
	var title:=Label.new();title.text="馆史荣誉 / 收藏台账 · 游戏经营称号，非现实认证";title.add_theme_font_size_override("font_size",25);title.add_theme_color_override("font_color",Color("392b1f"));box.add_child(title)
	tabs=TabContainer.new();tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(tabs)
	overview=text();overview.name="评级与声望";tabs.add_child(overview)
	var collection:=VBoxContainer.new();collection.name="50种收藏图鉴";tabs.add_child(collection)
	var filters:=HBoxContainer.new();collection.add_child(filters)
	region=OptionButton.new();region.add_item("全部实际来源");region.add_item("晋北");region.add_item("洛阳");region.add_item("关中");filters.add_child(region)
	category=OptionButton.new();category.add_item("全部器物类别");filters.add_child(category)
	period=OptionButton.new();period.add_item("全部时期");filters.add_child(period)
	var categories:Dictionary={};var periods:Dictionary={}
	for row in MuseumCollectionCodex.rows(state):categories[row.category]=true;periods[row.period]=true
	var cs:=categories.keys();cs.sort();var ps:=periods.keys();ps.sort()
	for key in cs:category.add_item(str(key))
	for key in ps:period.add_item(str(key))
	rarity=OptionButton.new();for label in ["全部稀有度","普通","非凡","稀有","珍宝"]:rarity.add_item(label)
	filters.add_child(rarity)
	status=OptionButton.new();for label in ["全部状态","未发现","已发现","已鉴定","已研究","当前拥有"]:status.add_item(label)
	filters.add_child(status)
	for option in [region,category,period,rarity,status]:option.item_selected.connect(func(_index:int)->void:page=0;refresh_catalog())
	search=LineEdit.new();search.placeholder_text="搜索50种游戏器物名称 / ID（不是全球索引）";search.text_changed.connect(func(_s:String)->void:page=0;refresh_catalog());collection.add_child(search)
	var split:=HBoxContainer.new();split.size_flags_vertical=Control.SIZE_EXPAND_FILL;collection.add_child(split)
	catalog_list=ItemList.new();catalog_list.custom_minimum_size=Vector2(460,290);catalog_list.size_flags_vertical=Control.SIZE_EXPAND_FILL;split.add_child(catalog_list)
	catalog_detail=text();split.add_child(catalog_detail);catalog_list.item_selected.connect(select_catalog)
	var nav:=HBoxContainer.new();collection.add_child(nav);button(nav,"上一页",func()->void:page=maxi(0,page-1);refresh_catalog());heading=Label.new();heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_theme_color_override("font_color",Color("392b1f"));nav.add_child(heading);button(nav,"下一页",func()->void:page=mini(page+1,maxi(0,ceili(rows.size()/20.0)-1));refresh_catalog())
	dossier=button(nav,"查看当前实例档案",func()->void:if selected_id!=&"":archive_requested.emit(selected_id))
	var honors:=HBoxContainer.new();honors.name="目标与纪念荣誉";tabs.add_child(honors)
	goals=ItemList.new();goals.custom_minimum_size=Vector2(460,380);honors.add_child(goals);goal_detail=text();honors.add_child(goal_detail);goals.item_selected.connect(select_goal)
	button(box,"合上台账 [Tab / Esc]",close);panel.hide()
func open(section:int=0)->void:
	if panel.visible:return
	_previous=player.controls_enabled;player.controls_enabled=false;panel.show();tabs.current_tab=clampi(section,0,2);refresh()
func close()->void:
	if not panel.visible:return
	panel.hide();player.controls_enabled=_previous
func _input(event:InputEvent)->void:
	if panel.visible and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_TAB,KEY_ESCAPE]:close();get_viewport().set_input_as_handled()
func refresh()->void:
	var evaluation:=MuseumReputationService.evaluate(state)
	overview.text="当前经营评级：%s（%d / 4）\n声望评分：%d\n这是游戏经营称号，独立于馆舍等级%d；不提供收入或战斗加成。\n\n当前实力（卖出/撤展/保护检查过期会变化）\n"%[evaluation.title,evaluation.rank+1,evaluation.score,state.museum_level+1]
	var names:Dictionary={"identified":"已鉴定不同器物","researched":"已研究不同器物","topics":"合格不同专题","displayed":"陈列不同器物","quality":"平均展示品相","protected":"保护合格不同器物","business_days":"有据营业日","visitors":"实际付费观众"}
	for key in evaluation.metrics:overview.text+="%s：%s\n"%[names[key],evaluation.metrics[key]]
	overview.text+="\n下一级条件（全部满足）：\n" if not evaluation.next_conditions.is_empty() else "\n已达到最高经营评级。\n"
	for key in evaluation.next_conditions:overview.text+="%s %d / %d · %s\n"%[names[key],evaluation.metrics[key],evaluation.next_conditions[key],"已满足" if evaluation.metrics[key]>=evaluation.next_conditions[key] else "尚未满足"]
	overview.text+="\n历史纪念荣誉：%d项；历史不因出售而撤销，当前实力不因此保底。"%state.achievements.size()
	refresh_catalog();goals.clear();var m:=MuseumMilestoneService.metrics(state)
	for goal in MuseumMilestoneDefinition.goals():goals.add_item(("铜牌 · " if state.achievements.has(goal.id) else ("进行中 · " if m.get(goal.metric,0)>0 else "尚未解锁 · "))+goal.name)
	if goals.item_count>0:goals.select(0);select_goal(0)
func refresh_catalog()->void:
	var regions:=["","JINBEI","LUOYANG","GUANZHONG"]
	rows=MuseumCollectionCodex.rows(state,regions[region.selected],category.get_item_text(category.selected) if category.selected>0 else "",period.get_item_text(period.selected) if period.selected>0 else "",rarity.selected-1,search.text)
	if status.selected>0:
		var flags:=["","unknown","discovered","identified","researched","owned"]
		rows=rows.filter(func(row:Dictionary)->bool:return not row.discovered if status.selected==1 else bool(row[flags[status.selected]]))
	page=mini(page,maxi(0,ceili(rows.size()/20.0)-1));catalog_list.clear()
	for row in rows.slice(page*20,(page+1)*20):catalog_list.add_item("%s · %s"%[row.name,row.status])
	var counts:=MuseumCollectionCodex.counts(state);heading.text="发现%d/50 · 持有%d/50 · 研究%d/50 | 第%d页"%[counts.discovered,counts.owned,counts.researched,page+1]
	selected_id=&"";dossier.disabled=true;catalog_detail.text="选择器物查看发现证据；地区筛选只显示实际来源。"
	if catalog_list.item_count>0:catalog_list.select(0);select_catalog(0)
func select_catalog(index:int)->void:
	var row:Dictionary=rows[page*20+index]
	catalog_detail.text="%s\n定义：%s\n%s / %s\n状态：%s\n当前拥有：%d件\n实际发现地区：%s\n\n历史发现与研究保留，当前陈列依实际实例。未发现记录不是玩家拥有的物品。\n全部50种为可掉落游戏原型，不是现实博物馆的同一件藏品。"%[row.name,row.id,row.category,row.period,row.status,row.owned,", ".join(row.regions) if not row.regions.is_empty() else "来源未记录 / 尚未发现"]
	selected_id=row.instances[0] if not row.instances.is_empty() else &"";dossier.disabled=selected_id==&""
func select_goal(index:int)->void:
	var goal:Dictionary=MuseumMilestoneDefinition.goals()[index];var m:=MuseumMilestoneService.metrics(state);var award:Dictionary=state.achievements.get(goal.id,{})
	goal_detail.text="%s\n稳定目标ID：%s\n实际进度：%d / %d\n奖励：%s\n%s\n\n奖励仅为馆史纪念，不发放现金、藏品或倍率。\n%s"%[goal.name,goal.id,m.get(goal.metric,0),goal.target,goal.reward,"完成日期：Day%d · 事件%s"%[award.day_number,award.event] if not award.is_empty() else "尚未完成（旧档当前证据不伪造历史日期）","地区小专题要求实际来源同地区至少5种、2类器物。" if goal.id=="REGION_TOPIC" else "完成事件唯一记账，反复查询不会颁发奖励。"]
