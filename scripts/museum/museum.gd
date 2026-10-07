class_name Museum
extends Node2D
## 博物馆场景装配，不生成地宫。统一交互点将请求交给状态/营业/馆藏面板。
signal night_requested
var state: MuseumState
var config: MuseumConfig
var museum_seed: int = 192034
var morning_notice: String = "早晨 · 可开馆，也可到情报板直接下墓"
var player: MuseumPlayer
var business: MuseumBusiness
var collection_panel: MuseumCollectionPanel
var cases: Array[DisplayCase] = []
var storage: MuseumInteractable
var ticket: MuseumInteractable
var board: MuseumInteractable
var headline: Label
var status: Label
var message: Label
var prompt_label: Label
var _night_after_close: bool = false


func _ready() -> void:
	assert(state != null and config != null)
	player = MuseumPlayer.new()
	player.name = "MuseumPlayer"
	player.position = Vector2(640,540)
	player.speed = config.player_speed
	add_child(player)
	_make_hud()
	player.prompt_label = prompt_label
	collection_panel = MuseumCollectionPanel.new()
	collection_panel.state = state
	collection_panel.player = player
	add_child(collection_panel)
	for index in range(3):
		var exhibit := DisplayCase.new()
		exhibit.name = "DisplayCase%d" % (index+1)
		exhibit.case_id = MuseumState.CASE_IDS[index]
		exhibit.state = state
		exhibit.position = Vector2(440+index*200,300)
		exhibit.prompt = func() -> String:
			return "营业中不能调整展品 · [E] 查看" if not state.can_edit() else "[E] 查看/布置展品    [R] 撤展"
		exhibit.action = func() -> void: collection_panel.open(exhibit.case_id if state.can_edit() else &"")
		exhibit.alternate_action = func() -> void:
			if not state.unassign(exhibit.case_id): message.text = "营业中不能调整展品" if not state.can_edit() else "展柜已空"
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
	storage = _point("库房",Vector2(180,500),Color("8e9a74"),func() -> String: return "[E] 查看库房",func() -> void: collection_panel.open())
	ticket = _point("售票台",Vector2(1080,500),Color("d5b371"),_ticket_prompt,func() -> void:
		if not business.start():
			message.text = "暂无展品，无法开馆" if not business.can_open() else ("营业尚未结束" if state.phase == MuseumState.Phase.OPEN else "今日已闭馆，请到情报板出发"))
	board = _point("情报板 · 晋北军阀墓",Vector2(1060,185),Color("a588b3"),func() -> String:
		return "正在闭馆，游客离场后出发" if _night_after_close else ("[E] 提前闭馆并下墓" if state.phase == MuseumState.Phase.OPEN else "[E] 今晚下墓（无需开馆）"),_request_night)
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
		if _night_after_close: night_requested.emit())
	add_child(business)
	state.changed.connect(_refresh)
	message.text = morning_notice
	_refresh()


func _request_night() -> void:
	if state.phase == MuseumState.Phase.OPEN:
		_night_after_close = true
		business.close_now()
		message.text = "提前闭馆 · 已停止进客，游客离场后立即下墓"
	elif state.phase in [MuseumState.Phase.MORNING,MuseumState.Phase.EVENING]:
		night_requested.emit()


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
	player.interactables.append(visitor)
	visitor.action = func() -> void: message.text = visitor.comment()
	visitor.leaving.connect(func(actor: MuseumVisitor) -> void: player.interactables.erase(actor))


func _ticket_prompt() -> String:
	if not business.can_open(): return "暂无展品，无法开馆"
	return "展出 %d件 · 吸引力 %d · 票价 ¥5 · %s" % [state.display_assignments.size(),state.total_appeal(),"[E] 开馆" if state.phase == MuseumState.Phase.MORNING else "[E] 查看营业状态"]


func _refresh() -> void:
	for exhibit in cases: exhibit.refresh()
	queue_redraw()


func _process(_delta: float) -> void:
	var phase_text := ["早晨 · 自由布展","营业中 · 不可调整展品","傍晚 · 前往情报板","夜晚"]
	headline.text = "大盗墓时代 · 第%d天 · %s" % [state.day_number,phase_text[state.phase]]
	var minutes := 600+floori(420*clampf(business.elapsed/maxf(.01,config.open_duration),0,1))
	status.text = "%02d:%02d · 现金 %s · 馆藏 %d件 · 吸引力 %d\n今日游客 %d / 目标%d · 门票 %s · 在馆 %d / %d" % [minutes/60,minutes%60,AntiqueDefinition.money(state.cash),state.collection.all_items().size(),state.total_appeal(),business.visitors_today,business.target,AntiqueDefinition.money(business.income_today),business.active.size(),config.max_active_visitors]


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
	draw_rect(Rect2(70,145,1140,470),Color("20262b") if state.phase != MuseumState.Phase.EVENING else Color("171c27"))
	draw_rect(Rect2(70,145,1140,470),Color("988d70"),false,4)
	draw_rect(Rect2(585,590,110,25),Color("789491"))
	draw_string(ThemeDB.fallback_font,Vector2(594,582),"博物馆大门",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("d0d6ca"))
	draw_string(ThemeDB.fallback_font,Vector2(105,195),"馆长办公室",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("b2ada3"))
