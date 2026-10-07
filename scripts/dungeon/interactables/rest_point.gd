class_name RestPoint
extends Node2D
## 本层一次性治疗；只通过Health.heal，领取记录跟随RoomState。
var player: Player
var room_state: RoomState
var amount: int
var can_use: Callable
var label: Label

func _ready() -> void:
	label = Label.new()
	label.position = Vector2(-160, 22)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

func available() -> bool:
	return is_instance_valid(player) and not player.health.is_dead and player.controls_enabled and not room_state.is_loot_claimed(&"rest_point") and (not can_use.is_valid() or can_use.call()) and player.global_position.distance_to(global_position) <= 64

func request() -> bool:
	if not available(): return false
	if not player.health.heal(amount):
		label.text = "当前无需处理伤口"
		return false
	room_state.claim_loot(&"rest_point")
	queue_free()
	return true

func _process(_delta: float) -> void:
	label.visible = available()
	if label.visible:
		label.text = "遗留医疗包\n剩余生命：%.0f / %.0f\n可恢复：%d\n[E] 处理伤口" % [player.health.current_hp, player.health.max_hp, amount] if player.health.current_hp < player.health.max_hp else "当前无需处理伤口"

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_echo() and event.is_action_pressed("interact") and available():
		request()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	draw_rect(Rect2(-20, -16, 40, 32), Color("68826a"))
	draw_line(Vector2(-10, 0), Vector2(10, 0), Color("ded9bc"), 5)
	draw_line(Vector2(0, -10), Vector2(0, 10), Color("ded9bc"), 5)

static func safe_position(room: Room) -> Vector2:
	var exit_point := RelicPedestal.safe_position(room)
	for y in range(224, 530, 80):
		for x in range(240, 1080, 80):
			var point := Vector2(x, y)
			if point.distance_to(exit_point) < 170: continue
			if room.obstacles().any(func(rect: Rect2) -> bool: return rect.grow(40).has_point(point)): continue
			return point
	return room.get_entry_position()
