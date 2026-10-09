class_name Museum
extends Node2D
## 博物馆场景装配，不生成地宫。统一交互点将请求交给状态/营业/馆藏面板。
signal night_requested(site_id:StringName)
var site_registry:SiteRegistry=SiteRegistry.load_default()
var expedition_map:ExpeditionMapPanel
signal auction_requested
var state: MuseumState
var config: MuseumConfig
var museum_seed: int = 192034
var morning_notice: String = "早晨 · 至少布展1件才能开馆；到情报板按E选择远征"
var player: MuseumPlayer
var business: MuseumBusiness
var collection_panel: MuseumCollectionPanel
var _service_signature:String=""
var guide_nodes:Dictionary[StringName,MuseumGuideNPC]={}
var _service_nodes:Array[Node2D]=[]
var facility_panel:MuseumFacilityPanel
var construction_panel: MuseumConstructionPanel
var construction: MuseumInteractable
var appraisal: MuseumInteractable
var restoration: MuseumInteractable
var appraisal_panel: MuseumAppraisalPanel
var restoration_panel: MuseumRestorationPanel
var dealer: MuseumInteractable
var consignment: MuseumInteractable
var dealer_panel: MuseumDealerPanel
var consignment_panel: AuctionConsignmentPanel
var night_panel: NightActivityPanel
var cases: Array[DisplayCase] = []
var storage: MuseumInteractable
var ticket: MuseumInteractable
var board: MuseumInteractable
var headline: Label
var status: Label
var message: Label
var prompt_label: Label
var _night_after_close: bool = false
var _shown_level: int = -1
var codex_panel: MuseumCodexPanel
var reputation_panel:MuseumReputationPanel
var honor_wall:MuseumHonorWall
var research_desk: MuseumInteractable
var active_hall_id: StringName = &"MAIN"
var hall_panel: MuseumHallPanel
var hall_guide: MuseumInteractable
var office_desk: MuseumOfficeDesk
var office_panel: MuseumOfficePanel
var _display_bodies: Dictionary = {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	assert(state != null and config != null)
	player = MuseumPlayer.new()
	player.name = "MuseumPlayer"
	player.position = Vector2(640,540)
	player.speed = config.player_speed
	add_child(player)
	_make_hud()
	player.prompt_label = prompt_label
	hall_panel = MuseumHallPanel.new()
	hall_panel.state = state
	hall_panel.player = player
	hall_panel.hall_selected.connect(switch_hall)
	add_child(hall_panel)
	hall_guide = _point("展厅通道",Vector2(1120,420),Color("73b59b"),func()->String:return "[E] 选择展厅 / 返回主厅",func()->void:hall_panel.open())
	codex_panel = MuseumCodexPanel.new()
	codex_panel.state = state
	codex_panel.player = player
	add_child(codex_panel)
	research_desk = _point("馆藏研究台",Vector2(900,190),Color("7daac4"),func() -> String: return "[E] 我的馆藏档案 / 全球研究资料",func() -> void: codex_panel.open())
	collection_panel = MuseumCollectionPanel.new()
	collection_panel.archive_requested.connect(func(id:StringName)->void:collection_panel.close();codex_panel.open_at(id))
	collection_panel.state = state
	collection_panel.player = player
	add_child(collection_panel)
	_sync_cases()
	facility_panel=MuseumFacilityPanel.new()
	facility_panel.state=state
	facility_panel.player=player
	add_child(facility_panel)
	construction_panel = MuseumConstructionPanel.new()
	construction_panel.state = state
	construction_panel.player = player
	construction_panel.facility_panel=facility_panel
	add_child(construction_panel)
	construction = _point("馆舍建设",Vector2(400,190),Color("b99b7f"),func() -> String: return "[E] 查看扩建",func() -> void: construction_panel.open())
	storage = _point("库房",Vector2(180,500),Color("8e9a74"),func() -> String: return "[E] 查看库房",func() -> void: collection_panel.open())
	appraisal_panel = MuseumAppraisalPanel.new()
	appraisal_panel.state = state
	appraisal_panel.player = player
	add_child(appraisal_panel)
	appraisal_panel.work_completed.connect(func(notice: String) -> void:
		if not message.text.begins_with("保存失败"): message.text = notice)
	restoration_panel = MuseumRestorationPanel.new()
	restoration_panel.state = state
	restoration_panel.player = player
	add_child(restoration_panel)
	restoration_panel.work_completed.connect(func(notice: String) -> void:
		if not message.text.begins_with("保存失败"): message.text = notice)
	appraisal = _point("鉴定台",Vector2(540,190),Color("94b4b0"),func() -> String: return "[E] 鉴定古董（免费）" if state.can_edit() else "营业中无法进行馆藏作业",func() -> void:
		if not appraisal_panel.open(): message.text = "营业中无法进行馆藏作业")
	restoration = _point("修复台",Vector2(730,190),Color("b39a6c"),func() -> String: return "[E] 修复古董" if state.can_edit() else "营业中无法进行馆藏作业",func() -> void:
		if not restoration_panel.open(): message.text = "营业中无法进行馆藏作业")
	dealer_panel = MuseumDealerPanel.new()
	dealer_panel.state = state
	dealer_panel.player = player
	add_child(dealer_panel)
	consignment_panel = AuctionConsignmentPanel.new()
	consignment_panel.state = state
	consignment_panel.player = player
	add_child(consignment_panel)
	for market_panel in [dealer_panel,consignment_panel]:
		market_panel.transaction_completed.connect(func(notice: String) -> void:
			if not message.text.begins_with("保存失败"): message.text = notice)
	dealer = _point("古董商",Vector2(800,540),Color("b18469"),func() -> String: return "[E] 找古董商" if state.can_edit() else "营业中无法处理古董交易",func() -> void:
		if not dealer_panel.open(): message.text = "营业中无法处理古董交易")
	consignment = _point("拍卖委托台",Vector2(430,540),Color("a49dbe"),func() -> String: return "[E] 委托拍卖 / 取消委托" if state.can_edit() else "营业中无法处理古董交易",func() -> void:
		if not consignment_panel.open(): message.text = "营业中无法处理古董交易")
	night_panel = NightActivityPanel.new()
	night_panel.state = state
	night_panel.player = player
	night_panel.dungeon_chosen.connect(func() -> void: expedition_map.open())
	night_panel.auction_chosen.connect(func() -> void: auction_requested.emit())
	add_child(night_panel)
	expedition_map=ExpeditionMapPanel.new()
	expedition_map.registry=site_registry
	expedition_map.state=state
	expedition_map.player=player
	expedition_map.expedition_selected.connect(func(id:StringName)->void:night_requested.emit(id))
	add_child(expedition_map)
	ticket = _point("售票台",Vector2(1080,500),Color("d5b371"),_ticket_prompt,func() -> void:
		if not business.start():
			message.text = "暂无展品，无法开馆" if not business.can_open() else ("营业尚未结束" if state.phase == MuseumState.Phase.OPEN else "今日已闭馆，请到情报板出发"))
	board = _point("情报板 · 远征调查图",Vector2(1060,170),Color("a588b3"),func() -> String:
		if _night_after_close: return "正在闭馆，游客离场后选择行动"
		if state.auction_lot_instance_id != &"": return "[E] 提前闭馆并选择今晚行动" if state.phase == MuseumState.Phase.OPEN else "[E] 选择今晚行动"
		return "[E] 提前闭馆并查看地图" if state.phase == MuseumState.Phase.OPEN else "[E] 查看远征地图（无需开馆）",_request_night)
	business = MuseumBusiness.new()
	business.name = "Business"
	business.state = state
	business.config = config
	business.museum_seed = museum_seed
	business.visitor_parent = self
	business.cases = cases
	business.visitor_spawned.connect(_visitor_arrived)
	business.completed.connect(func() -> void:
		message.text = "今日营业结束 · 游客 %d人 · 门票收入 %s · 现金 %s\n可整理展品，再去情报板 [E] 今晚下墓" % [state.last_day_visitors,AntiqueDefinition.money(state.last_day_ticket_income),AntiqueDefinition.money(state.cash)]
		if _night_after_close: _present_night())
	add_child(business)
	office_panel=MuseumOfficePanel.new()
	office_panel.state=state
	office_panel.player=player
	office_panel.archives_requested.connect(func()->void:office_panel.close();codex_panel.open();codex_panel.set_mode(0))
	office_panel.business=business
	add_child(office_panel)
	office_desk=MuseumOfficeDesk.new()
	office_desk.position=Vector2(230,190)
	office_desk.title="馆长办公室"
	office_desk.prompt=func()->String:return "[E] 馆务 / 策展 / 营业台账"
	office_desk.action=func()->void:office_panel.open()
	add_child(office_desk)
	player.interactables.append(office_desk)
	reputation_panel=MuseumReputationPanel.new();reputation_panel.state=state;reputation_panel.player=player;add_child(reputation_panel)
	reputation_panel.archive_requested.connect(func(id:StringName)->void:reputation_panel.close();codex_panel.open_at(id))
	office_panel.reputation_requested.connect(func()->void:office_panel.close();reputation_panel.open())
	honor_wall=MuseumHonorWall.new()
	honor_wall.state=state
	honor_wall.position=Vector2(115,350)
	honor_wall.title="馆史荣誉墙"
	honor_wall.prompt=func()->String:return "[E] 声望 / 收藏 / 纪念荣誉"
	honor_wall.action=func()->void:reputation_panel.open(2)
	add_child(honor_wall)
	player.interactables.append(honor_wall)
	state.changed.connect(_refresh)
	message.text = morning_notice
	_refresh()


func _request_night() -> void:
	if state.phase == MuseumState.Phase.OPEN:
		_night_after_close = true
		business.close_now()
		message.text = "提前闭馆 · 已停止进客，游客离场后选择今晚行动" if state.auction_lot_instance_id != &"" else "提前闭馆 · 已停止进客，游客离场后查阅远征地图"
	elif state.phase in [MuseumState.Phase.MORNING,MuseumState.Phase.EVENING]:
		_present_night()


func _present_night() -> void:
	_night_after_close = false
	if state.auction_lot_instance_id != &"": night_panel.open()
	else: expedition_map.open()


func _point(title: String, location: Vector2, color: Color, hint: Callable, action: Callable) -> MuseumInteractable:
	var point := MuseumInteractable.new()
	point.title = title
	point.position = location
	point.tint = color
	point.prompt = hint
	point.action = action
	add_child(point)
	player.interactables.append(point)
	return point


func _visitor_arrived(visitor: MuseumVisitor) -> void:
	_sync_visitor(visitor)
	visitor.hall_changed.connect(_sync_visitor)
	visitor.action = func() -> void: message.text = visitor.comment()
	visitor.leaving.connect(func(actor: MuseumVisitor) -> void: player.interactables.erase(actor))


func _ticket_prompt() -> String:
	if not business.can_open(): return "暂无展品，无法开馆"
	return "展出 %d件 · 吸引力 %d · 票价 ¥5 · %s" % [state.display_assignments.size(),state.total_appeal(),"[E] 开馆" if state.phase == MuseumState.Phase.MORNING else "[E] 查看营业状态"]


func _refresh() -> void:
	if is_instance_valid(honor_wall):honor_wall.queue_redraw()
	_sync_cases()
	_sync_services()
	_sync_guides()
	for exhibit in cases: exhibit.refresh()
	if _shown_level >= 0 and _shown_level != state.museum_level and not message.text.begins_with("保存失败"):
		message.text = "扩建完成：%s · 展柜%d · 游客容量%d · 当前现金%s" % [state.level_definition().display_name,state.display_catalog.unit_ids(state.museum_level).size(),state.level_definition().visitor_capacity,AntiqueDefinition.money(state.cash)]
	_shown_level = state.museum_level
	queue_redraw()


func switch_hall(id: StringName) -> void:
	if id not in state.display_catalog.hall_ids(state.museum_level) or state.phase == MuseumState.Phase.NIGHT: return
	active_hall_id = id
	_sync_services()
	_sync_guides()
	_sync_cases()
	player.position = Vector2(1120,470)
	player.velocity = Vector2.ZERO
	if business != null:
		for visitor in business.active: _sync_visitor(visitor)
	message.text = "已进入"+state.display_catalog.halls[id].display_name
	queue_redraw()

func _sync_visitor(visitor: MuseumVisitor) -> void:
	visitor.visible = visitor.hall_id == active_hall_id
	player.interactables.erase(visitor)
	if visitor.visible: player.interactables.append(visitor)

func _sync_cases() -> void:
	var ids := state.display_catalog.unit_ids(state.museum_level,active_hall_id)
	for exhibit in cases.duplicate():
		if exhibit.case_id not in ids:
			player.interactables.erase(exhibit)
			cases.erase(exhibit)
			exhibit.queue_free()
			_display_bodies[exhibit.case_id].queue_free()
			_display_bodies.erase(exhibit.case_id)
	for id in ids:
		if cases.any(func(view: DisplayCase)->bool:return view.case_id==id): continue
		var exhibit := DisplayCase.new()
		exhibit.name = str(id)
		exhibit.case_id = id
		exhibit.state = state
		exhibit.position = state.display_catalog.units[id].position
		exhibit.prompt = func()->String:return "[E] 查看组合陈列（营业中只读）" if not state.can_edit() else "[E] 管理陈列位置 · [R] 撤下第一位置"
		exhibit.action = func()->void:collection_panel.open(exhibit.case_id)
		exhibit.alternate_action = func()->void:
			if not state.unassign(state.display_catalog.units[exhibit.case_id].slots()[0].id): message.text = "营业中不能调整展品" if not state.can_edit() else "位置已空"
		add_child(exhibit)
		cases.append(exhibit)
		player.interactables.append(exhibit)
		var body := StaticBody2D.new()
		body.position = exhibit.position
		body.collision_layer = 1
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(104,60)
		collision.shape = shape
		body.add_child(collision)
		add_child(body)
		_display_bodies[id]=body
	if business != null: business.cases=cases


func _process(_delta: float) -> void:
	var phase_text := ["早晨 · 自由布展","营业中 · 不可调整展品","傍晚 · 前往情报板","夜晚"]
	headline.text = "第%d天 · %s · %s" % [state.day_number,state.level_definition().display_name+" / "+state.display_catalog.halls[active_hall_id].display_name,phase_text[state.phase]]
	var minutes := 600+floori(420*clampf(business.elapsed/maxf(.01,config.open_duration),0,1))
	if state.phase == MuseumState.Phase.EVENING: minutes = 1020
	var visitors := state.last_day_visitors if state.phase == MuseumState.Phase.EVENING else business.visitors_today
	var income := state.last_day_ticket_income if state.phase == MuseumState.Phase.EVENING else business.income_today
	status.text = "%02d:%02d · 现金 %s · 已陈列 %d件 / %d位置 · 游客容量 %d · 有效吸引力%d\n馆藏 %d件 · 今日游客 %d人 · 门票 %s" % [minutes/60,minutes%60,AntiqueDefinition.money(state.cash),state.display_assignments.size(),display_capacity(),state.level_definition().visitor_capacity,state.total_appeal(),state.collection.all_items().size(),visitors,AntiqueDefinition.money(income)]


func _make_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	headline = _label(hud,Vector2(60,24),26)
	status = _label(hud,Vector2(60,66),18)
	message = _label(hud,Vector2(100,628),18)
	prompt_label = _label(hud,Vector2(100,685),18)
	_label(hud,Vector2(60,118),16).text = "WASD 移动 · E 互动 · 展柜旁 R 撤展 · 面板 Tab/E 关闭 · 白天无攻击"


func _label(parent: Node, location: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = location
	label.size = Vector2(1120,60)
	label.add_theme_font_size_override("font_size",font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"): get_tree().quit()


func _draw() -> void:
	if not MuseumDisplayVisual.floor(self):
		draw_rect(Rect2(70,145,1140,470),Color("20262b") if state.phase != MuseumState.Phase.EVENING else Color("171c27"))
	MuseumDisplayVisual.staff(self)
	draw_rect(Rect2(70,145,1140,470),Color("988d70"),false,4)
	draw_string(ThemeDB.fallback_font,Vector2(100,255),state.display_catalog.halls[active_hall_id].display_name,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("b6cbd0"))
	draw_line(Vector2(100,450),Vector2(1180,450),Color("354349"),1)
	draw_string(ThemeDB.fallback_font,Vector2(1010,470),"通往其它展厅",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("85c4b1"))
	draw_rect(Rect2(585,590,110,25),Color("789491"))
	draw_string(ThemeDB.fallback_font,Vector2(594,582),"博物馆大门",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("d0d6ca"))
	draw_string(ThemeDB.fallback_font,Vector2(105,195),"馆长办公室",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("b2ada3"))


func _draw_wing(area: Rect2, title: String, unlocked: bool) -> void:
	draw_rect(area,Color("29343b") if unlocked else Color("151b20"))
	draw_rect(area,Color("657b80") if unlocked else Color("514b45"),false,2)
	draw_string(ThemeDB.fallback_font,area.position+Vector2(10,10),title+ (" · 已开放" if unlocked else " · 尚未开放"),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("b8b1a3"))
	if not unlocked:
		draw_line(area.position+Vector2(10,40),area.end-Vector2(10,10),Color("403f3b"),2)
		draw_line(area.position+Vector2(area.size.x-10,40),area.position+Vector2(10,area.size.y-10),Color("403f3b"),2)

func display_capacity() -> int:
	var total:=0
	for id in state.display_catalog.unit_ids(state.museum_level):total+=state.display_catalog.units[id].capacity
	return total

func _sync_services()->void:
	var signature:=str(active_hall_id)
	for row:Dictionary in MuseumConstructionService.rules().public:signature+="/%s:%d"%[row.id,state.facilities.level(StringName(row.id))]
	if signature==_service_signature:return
	_service_signature=signature
	for node in _service_nodes:
		if is_instance_valid(node):node.queue_free()
	_service_nodes.clear()
	for row:Dictionary in MuseumConstructionService.rules().public:
		var level:=state.facilities.level(StringName(row.id))
		if level<=0 or row.hall!=str(active_hall_id):continue
		var node:=MuseumServiceFixture.new()
		node.kind=StringName(row.kind)
		node.level=level
		node.position=Vector2(row.position[0],row.position[1])
		add_child(node)
		_service_nodes.append(node)

func _sync_guides()->void:
	for id in guide_nodes.keys():
		if not is_instance_valid(guide_nodes[id]):
			guide_nodes.erase(id);continue
		if not state.staff.members.has(id) or state.staff.members[id].employment_status!=&"ACTIVE":
			guide_nodes[id].queue_free();guide_nodes.erase(id)
	for id in MuseumStaffService.active_ids(state):
		if MuseumStaffService.catalog()[id].job!=&"GUIDE":continue
		if not guide_nodes.has(id):
			var guide:=MuseumGuideNPC.new()
			guide.staff_id=id;guide.state=state;guide.business=business
			add_child(guide);guide_nodes[id]=guide
		guide_nodes[id].visible=state.staff.members[id].assigned_hall==active_hall_id
