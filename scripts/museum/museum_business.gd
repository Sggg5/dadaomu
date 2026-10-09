class_name MuseumBusiness
extends Node
## 独立营业模拟：Museum负责交互与呈现；票款按visitor_index去重，关闭后不补客。
signal completed
signal visitor_spawned(visitor: MuseumVisitor)
var state: MuseumState
var config: MuseumConfig
var museum_seed: int
var visitor_parent: Node2D
var cases: Array[DisplayCase] = []
var active: Array[MuseumVisitor] = []
var target: int = 0
var spawned: int = 0
var visitors_today: int = 0
var income_today: int = 0
var elapsed: float = 0.0
var running: bool = false
var closing: bool = false
var _paid: Dictionary[int,bool] = {}
var _spawn_timer: float = 0.0


func can_open() -> bool:
	return state != null and not state.display_assignments.is_empty()


func visitor_target(appeal: int, displayed_count: int) -> int:
	if displayed_count == 0: return 0
	var capacity := state.level_definition().visitor_capacity if state != null else MuseumState.LEVELS.at(0).visitor_capacity
	var halls:=state.displayed_halls().size() if state!=null else 1
	var scale:float=state.display_catalog.visitor_appeal_scale if state!=null else .35
	var hall_bonus:int=state.display_catalog.additional_hall_visitors if state!=null else 2
	return clampi(config.base_visitors+floori(appeal*scale)+maxi(0,halls-1)*hall_bonus,1,capacity)


func start() -> bool:
	if running or state.phase != MuseumState.Phase.MORNING or not can_open(): return false
	target = visitor_target(state.total_appeal()+ExhibitionService.bonus_appeal(state),state.display_assignments.size())
	running = true
	closing = false
	state.phase = MuseumState.Phase.OPEN
	state.changed.emit()
	return true


func _physics_process(delta: float) -> void:
	if not running: return
	elapsed += delta
	if elapsed >= config.open_duration and not closing:
		close_now()
	if not closing:
		_spawn_timer -= delta
		if spawned < target and active.size() < config.max_active_visitors and _spawn_timer <= 0:
			spawn_visitor()
			_spawn_timer = .35
	elif active.is_empty():
		running = false
		state.last_day_visitors = visitors_today
		state.last_day_ticket_income = income_today
		state.phase = MuseumState.Phase.EVENING
		state.changed.emit()
		completed.emit()


func close_now() -> void:
	# 可提前闭馆：停止新客，现客走完离场路线，完成信号仍只发一次。
	if not running or closing: return
	closing = true
	for visitor in active: visitor.close_museum()


func spawn_visitor() -> void:
	if not running or closing or active.size() >= config.max_active_visitors or spawned >= target: return
	var visitor := MuseumVisitor.new()
	visitor.state = state
	visitor.config = config
	visitor.cases = cases
	visitor.configure(museum_seed,state.day_number,spawned)
	visitor.position = Vector2(640,600)
	visitor.paid.connect(_on_paid)
	visitor.leaving.connect(_on_leaving)
	spawned += 1
	active.append(visitor)
	visitor_parent.add_child(visitor)
	visitor_spawned.emit(visitor)


func _on_paid(index: int) -> void:
	if not running or closing or index < 0 or index >= spawned or _paid.has(index): return
	_paid[index] = true
	visitors_today += 1
	income_today += config.ticket_price
	state.cash += config.ticket_price
	state.changed.emit()


func _on_leaving(visitor: MuseumVisitor) -> void: active.erase(visitor)
