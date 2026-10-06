class_name Dummy
extends StaticBody2D
## 固定靶没有 AI 或攻击行为，仅用于验证命中与生命生命周期。

signal killed

@export_range(1.0, 1000.0) var max_hp: float = 60.0
@onready var health: Health = $Health

var flash_remaining: float = 0.0


func _ready() -> void:
	health.initialize(max_hp)
	health.died.connect(_on_died)


func take_damage(amount: float) -> bool:
	if not health.take_damage(amount):
		return false
	flash_remaining = 0.12
	queue_redraw()
	return true


func _process(delta: float) -> void:
	flash_remaining = maxf(0.0, flash_remaining - delta)
	queue_redraw()


func _on_died() -> void:
	killed.emit()
	queue_free()


func _draw() -> void:
	var color := Color("e58164") if flash_remaining > 0.0 else Color("b18a68")
	draw_rect(Rect2(-20.0, -20.0, 40.0, 40.0), color)
	draw_line(Vector2(-12, -12), Vector2(12, 12), Color("352d2a"), 3.0)
	draw_line(Vector2(-12, 12), Vector2(12, -12), Color("352d2a"), 3.0)
	if is_instance_valid(health):
		draw_rect(Rect2(-22.0, -32.0, 44.0, 5.0), Color("343945"))
		draw_rect(Rect2(-22.0, -32.0, 44.0 * health.current_hp / health.max_hp, 5.0), Color("d9b76f"))
