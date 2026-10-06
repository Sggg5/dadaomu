class_name CombatPulse
extends Node2D
## 一次瞬时攻击后的短暂几何反馈，不参与伤害结算。
var end: Vector2
var radius: float = 0.0
var remaining: float = 0.3
var tint: Color = Color("ffad55")


func _process(delta: float) -> void:
	remaining -= delta
	modulate.a = minf(1.0, remaining * 4.0)
	if remaining <= 0.0:
		queue_free()


func _draw() -> void:
	if radius > 0.0:
		draw_circle(Vector2.ZERO, radius, Color(tint, 0.16))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 40, tint, 3.0)
	else:
		draw_line(Vector2.ZERO, end, Color("090d13"), 6.0)
		draw_line(Vector2.ZERO, end, Color("70879b"), 2.0)
