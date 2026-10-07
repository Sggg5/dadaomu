class_name MuseumVisitor
extends MuseumInteractable
## 一名游客的独立RNG/路线/一次票款。闭馆强制EXIT，不再观看新展柜。
enum Activity { ENTER, CHOOSE_EXHIBIT, WALK_TO_EXHIBIT, VIEW, EXIT }
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


func choose_exhibit() -> DisplayCase:
	var candidates: Array[DisplayCase] = []
	var total: int = 0
	for exhibit in cases:
		var definition := exhibit.state.definition_for(exhibit.case_id)
		if definition != null and exhibit.state.appeal_for(exhibit.state.display_assignments.get(exhibit.case_id,&"")) > 0 and exhibit.case_id not in seen_cases:
			candidates.append(exhibit)
			total += exhibit.state.appeal_for(exhibit.state.display_assignments[exhibit.case_id])
	if candidates.is_empty(): return null
	var roll := rng.randi_range(1,total)
	for exhibit in candidates:
		roll -= exhibit.state.appeal_for(exhibit.state.display_assignments[exhibit.case_id])
		if roll <= 0: return exhibit
	return candidates.back()


func pay_ticket() -> bool:
	if ticket_paid or closing: return false
	ticket_paid = true
	paid.emit(visitor_index)
	return true


func close_museum() -> void:
	if closing: return
	closing = true
	title = ""
	refresh()
	activity = Activity.EXIT
	route = [Vector2(position.x,450),Vector2(640,570),exit_position]


func comment() -> String:
	if chosen_case == null: return "“今天来看看馆里的收藏。”"
	var definition := chosen_case.state.definition_for(chosen_case.case_id)
	return "“这件%s挺有意思。”" % definition.display_name if definition != null else "“馆里很安静。”"


func _physics_process(delta: float) -> void:
	if not route.is_empty():
		position = position.move_toward(route[0],config.visitor_speed*delta)
		if position.distance_to(route[0]) < 1: route.pop_front()
		return
	match activity:
		Activity.ENTER:
			pay_ticket()
			activity = Activity.CHOOSE_EXHIBIT
		Activity.CHOOSE_EXHIBIT:
			chosen_case = choose_exhibit()
			if chosen_case == null: close_museum()
			else:
				seen_cases.append(chosen_case.case_id)
				route = [Vector2(position.x,450),Vector2(chosen_case.position.x,450),chosen_case.position+Vector2(0,72)]
				activity = Activity.WALK_TO_EXHIBIT
		Activity.WALK_TO_EXHIBIT:
			activity = Activity.VIEW
			view_count += 1
			view_remaining = config.view_duration
			title = "观看中"
			refresh()
		Activity.VIEW:
			view_remaining -= delta
			if view_remaining <= 0:
				if view_count < 2 and rng.randf() < .5: activity = Activity.CHOOSE_EXHIBIT
				else: close_museum()
		Activity.EXIT:
			leaving.emit(self)
			queue_free()


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(0,-13),Vector2(13,0),Vector2(0,13),Vector2(-13,0)]),tint)
