class_name MuseumPlayer
extends CharacterBody2D
## 白天仅移动、朝向和统一交互；没有Weapon/Health/RelicRuntime。
var speed: float = 300.0
var controls_enabled: bool = true
var facing: Vector2 = Vector2.DOWN
var interactables: Array[MuseumInteractable] = []
var focused: MuseumInteractable
var prompt_label: Label


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14
	shape.shape = circle
	add_child(shape)


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left","move_right","move_up","move_down") if controls_enabled else Vector2.ZERO
	velocity = velocity.move_toward(direction * speed, (1800.0 if direction != Vector2.ZERO else 2200.0) * delta)
	if direction != Vector2.ZERO: facing = direction
	move_and_slide()
	position = position.clamp(Vector2(95,150), Vector2(1185,605))
	focused = null
	var nearest: float = 64.01
	if controls_enabled:
		for target in interactables:
			if not is_instance_valid(target) or target.is_queued_for_deletion(): continue
			var distance := global_position.distance_to(target.global_position)
			if distance < nearest:
				nearest = distance
				focused = target
	if is_instance_valid(prompt_label):
		prompt_label.text = focused.prompt.call() if focused != null and focused.prompt.is_valid() else "靠近物件或游客按 E 互动"
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled or focused == null or event.is_echo(): return
	if event.is_action_pressed("interact"):
		focused.interact()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart"):
		focused.alternate()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 16, Color("63c8c1"))
	draw_arc(Vector2.ZERO,16,0,TAU,24,Color.WHITE,2)
	draw_line(facing * 8, facing * 23, Color("eee3b2"), 4)
