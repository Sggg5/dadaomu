class_name MuseumVisitor
extends MuseumInteractable
## 一名游客的独立RNG/路线/一次票款。闭馆强制EXIT，不再观看新展柜。
enum Activity { ENTER, CHOOSE_EXHIBIT, WALK_TO_EXHIBIT, VIEW, EXIT, SERVICE }
signal hall_changed(visitor: MuseumVisitor)
var state: MuseumState
var hall_id: StringName = &"MAIN"
var chosen_unit_id: StringName = &""
var viewed_instance_ids: Array[StringName] = []
var _pending_hall: StringName = &""
signal view_completed(visitor_index:int,result:Dictionary)
var _view_result:Dictionary={}
var _seen_categories:Dictionary={}
var last_feedback:String=""
signal service_completed(visitor_index:int,facility_id:StringName)
var _service_id:StringName=&""
var _service_timer:=0.0
var _service_after:Activity=Activity.CHOOSE_EXHIBIT
var used_services:Dictionary={}
var max_view_count:=2
signal staff_guide_completed(visitor_index:int,staff_id:StringName)
var workday:MuseumStaffWorkday
var _staff_guide_id:StringName=&""
var _guided_once:=false
signal paid(visitor_index: int)
signal leaving(visitor: MuseumVisitor)
var visitor_index: int
var config: MuseumConfig
var cases: Array[DisplayCase] = []
var activity: Activity = Activity.ENTER
var chosen_case: DisplayCase
var ticket_paid: bool = false
var closing: bool = false
var view_count: int = 0
var view_remaining: float = 0.0
var rng := RandomNumberGenerator.new()
var route: Array[Vector2] = []
var seen_cases: Array[StringName] = []
var exit_position := Vector2(640,625)


func _ready() -> void:
	interaction_priority = 0
	tint = Color("da947f")
	title = ""
	prompt = func() -> String: return "[E] 与游客交谈"
	route = [Vector2(1040,560),Vector2(1080,540)]
	super._ready()
	label.position = Vector2(-35,16)
	label.size = Vector2(70,28)
	label.add_theme_font_size_override("font_size",14)


func configure(seed_value: int, day: int, index: int) -> void:
	visitor_index = index
	rng.seed = AntiquePool.stable_score(seed_value,day,StringName(str(index)),&"museum_visitor",1)


func _choose_unit() -> StringName:
	if state==null and not cases.is_empty():state=cases[0].state
	if state==null:return &""
	var hall_weights: Dictionary[StringName,int]={}
	for id in state.display_catalog.unit_ids(state.museum_level):
		if id in seen_cases:continue
		var appeal:=roundi(MuseumConstructionService.unit_interest(state,id)*(1.0+ExhibitionService.active(state,state.display_catalog.units[id].hall_id).heat))
		if appeal>0:
			var hall:=state.display_catalog.units[id].hall_id
			hall_weights[hall]=hall_weights.get(hall,0)+appeal
	if hall_weights.is_empty():return &""
	var total:=0
	for weight:int in hall_weights.values():total+=weight
	var roll:=rng.randi_range(1,total)
	var selected: StringName=&""
	var hall_ids:=hall_weights.keys()
	hall_ids.sort_custom(func(a:StringName,b:StringName)->bool:return str(a)<str(b))
	for hall:StringName in hall_ids:
		roll-=hall_weights[hall]
		if roll<=0:selected=hall;break
	roll=rng.randi_range(1,hall_weights[selected])
	for id in state.display_catalog.unit_ids(state.museum_level,selected):
		if id in seen_cases:continue
		roll-=roundi(MuseumConstructionService.unit_interest(state,id)*(1.0+ExhibitionService.active(state,selected).heat))
		if roll<=0:return id
	return &""

func choose_exhibit() -> DisplayCase:
	# Compatibility accessor for visible node fixtures; actual route targets stable data IDs.
	chosen_unit_id=_choose_unit()
	return _visible_case(chosen_unit_id)

func _visible_case(id:StringName)->DisplayCase:
	var views:Array=cases
	if get_parent()!=null and get_parent().get("cases")!=null:views=get_parent().cases
	for view:DisplayCase in views:
		if is_instance_valid(view) and not view.is_queued_for_deletion() and view.case_id==id:return view
	return null

func _set_hall(id:StringName)->void:
	hall_id=id
	chosen_case=_visible_case(chosen_unit_id)
	hall_changed.emit(self)

func _route_to_unit()->void:
	var unit:=state.display_catalog.units[chosen_unit_id]
	# All configured units are above the 450px shared aisle; final vertical approach
	# stops 72px below the unit, outside its footprint. Off-screen halls use their OWN map.
	route=[Vector2(position.x,450),Vector2(unit.position.x,450),unit.position+Vector2(0,72)]
	activity=Activity.WALK_TO_EXHIBIT

func pay_ticket() -> bool:
	if ticket_paid or closing: return false
	ticket_paid = true
	paid.emit(visitor_index)
	return true


func close_museum() -> void:
	if closing: return
	closing = true
	if workday!=null:workday.cancel_guide(visitor_index)
	_staff_guide_id=&""
	title = ""
	refresh()
	activity = Activity.EXIT
	_pending_hall=&""
	if hall_id!=&"MAIN":
		_pending_hall=&"MAIN"
		route=[Vector2(position.x,450),Vector2(1180,450),Vector2(1180,560)]
	else:route=[Vector2(position.x,450),Vector2(640,570),exit_position]


func comment() -> String:
	if not last_feedback.is_empty():return "“"+last_feedback+"”"
	if state==null or chosen_unit_id==&"":return "“今天来看看馆里的收藏。”"
	var items:=state.unit_items(chosen_unit_id)
	if items.is_empty():return "“馆里很安静。”"
	return "“%s等%d件一起看挺有意思。”" % [MuseumState.POOL.find_by_id(items[0].definition_id).display_name,items.size()]


func _physics_process(delta: float) -> void:
	label.position=Vector2(-105,16) if _staff_guide_id!=&"" else Vector2(-35,16)
	if not route.is_empty():
		position = position.move_toward(route[0],config.visitor_speed*delta)
		if position.distance_to(route[0]) < 1: route.pop_front()
		return
	if _pending_hall!=&"":
		_set_hall(_pending_hall)
		_pending_hall=&""
		position=Vector2(1180,560)
		if closing:route=[Vector2(1180,450),Vector2(640,570),exit_position]
		else:_route_to_unit()
		return
	match activity:
		Activity.ENTER:
			pay_ticket()
			if not _begin_service(&"RECEPTION",.3,Activity.CHOOSE_EXHIBIT):activity = Activity.CHOOSE_EXHIBIT
		Activity.CHOOSE_EXHIBIT:
			chosen_unit_id=_choose_unit()
			chosen_case=_visible_case(chosen_unit_id)
			if chosen_unit_id==&"":close_museum()
			else:
				seen_cases.append(chosen_unit_id)
				var unit:=state.display_catalog.units[chosen_unit_id]
				if unit.hall_id!=hall_id:
					_pending_hall=unit.hall_id
					route=[Vector2(position.x,450),Vector2(1180,450),Vector2(1180,560)]
				else:_route_to_unit()
		Activity.WALK_TO_EXHIBIT:
			activity = Activity.VIEW
			view_count += 1
			for item in state.unit_items(chosen_unit_id):
				if item.instance_id not in viewed_instance_ids:viewed_instance_ids.append(item.instance_id)
			_view_result=VisitorViewResult.snapshot(state,chosen_unit_id,_seen_categories)
			view_remaining = config.view_duration
			title = "观看中"
			refresh()
		Activity.VIEW:
			view_remaining -= delta
			if view_remaining <= 0:
				if not _view_result.is_empty():
					last_feedback=_view_result.feedback
					for category in _view_result.categories:_seen_categories[category]=true
					view_completed.emit(visitor_index,_view_result.duplicate(true))
					_view_result.clear()
				if _begin_staff_guide():pass
				elif _begin_service(&"GUIDE",.6,Activity.CHOOSE_EXHIBIT):pass
				elif _begin_service(&"REST",.8,Activity.CHOOSE_EXHIBIT):pass
				elif view_count < max_view_count and (max_view_count==3 or rng.randf() < .5): activity = Activity.CHOOSE_EXHIBIT
				else: close_museum()
		Activity.SERVICE:
			_service_timer-=delta
			if _service_timer<=0:
				used_services[_service_id]=true
				if _service_id==&"MAIN_GUIDE":max_view_count=3;_guided_once=true
				if _staff_guide_id!=&"":
					if workday.complete_guide(visitor_index,_staff_guide_id):
						max_view_count=3
						_guided_once=true
						staff_guide_completed.emit(visitor_index,_staff_guide_id)
						_service_id=&"STAFF_GUIDE_DONE"
					_staff_guide_id=&""
				last_feedback="%s"%{&"STAFF_GUIDE_DONE":"导览员带我继续看展。",&"MAIN_GUIDE":"导览牌让参观路线更清楚。",&"EAST_REST":"看展之间可以坐下歇歇。",&"MAIN_RECEPTION":"接待台讲清了参观规则。"}.get(_service_id,"")
				service_completed.emit(visitor_index,_service_id)
				_service_id=&""
				activity=_service_after
		Activity.EXIT:
			leaving.emit(self)
			queue_free()


func _draw() -> void:
	if MuseumNPCVisual.draw(self,visitor_index%2,activity in [Activity.ENTER,Activity.WALK_TO_EXHIBIT,Activity.EXIT]): return
	draw_colored_polygon(PackedVector2Array([Vector2(0,-13),Vector2(13,0),Vector2(0,13),Vector2(-13,0)]),tint)

func _begin_service(kind:StringName,duration:float,after:Activity)->bool:
	if kind==&"GUIDE" and _guided_once:return false
	if kind!=&"RECEPTION" and view_count>=max_view_count:return false
	var id:=MuseumConstructionService.public_id(kind)
	var level:=state.facilities.level(id)
	if level<=0 or used_services.has(id) or closing:return false
	var definition:=MuseumConstructionService.find(state,id)
	if definition.hall_id!=hall_id:return false
	_service_id=id
	_service_timer=duration+level*.1
	_service_after=after
	var target:=MuseumConstructionService.public_position(kind)
	route=[Vector2(position.x,450),Vector2(target.x,450),target]
	activity=Activity.SERVICE
	title={&"GUIDE":"阅读导览",&"REST":"休息中",&"RECEPTION":"接待中"}[kind]
	refresh()
	return true

func _begin_staff_guide()->bool:
	if workday==null or _guided_once or used_services.has(&"MAIN_GUIDE") or view_count>=max_view_count or closing:return false
	var id:=workday.reserve_guide(visitor_index,hall_id)
	if id==&"":return false
	_staff_guide_id=id
	_service_id=&"STAFF_GUIDE"
	_service_timer=MuseumStaffService.catalog()[id].seconds_per_task
	_service_after=Activity.CHOOSE_EXHIBIT
	var target:=workday.guide_position(id)+Vector2(-30,0)
	route=[Vector2(position.x,450),Vector2(target.x,450),target]
	activity=Activity.SERVICE
	title="听取导览"
	refresh()
	return true
func _exit_tree()->void:
	if workday!=null:workday.cancel_guide(visitor_index)
