class_name Burn
extends Node2D
## 仅当前燃烧需求：每敌人一个可刷新实例，三次 DOT；卸载/死亡立即停用。
var runtime: RelicRuntime
var target: Node2D
var ticks_left: int = 3
var max_ticks: int = 3
var ticks_done: int = 0
var damage: float = 3.0
var interval: float = 0.35
var remaining: float = 0.35
var cancelled: bool = false


func refresh() -> void:
	ticks_left = max_ticks
	remaining = interval


func cancel() -> void:
	cancelled = true
	set_physics_process(false)
	queue_free()


func _physics_process(delta: float) -> void:
	if cancelled:
		return
	if not is_instance_valid(runtime) or not runtime.is_active() or not is_instance_valid(target) or (target.get_node("Health") as Health).is_dead:
		cancel()
		return
	remaining -= delta
	if remaining <= 0.0:
		remaining += interval
		ticks_left -= 1
		ticks_done += 1
		target.take_damage(damage)
		queue_redraw()
		if ticks_left <= 0:
			cancel()


func _draw() -> void:
	draw_arc(Vector2.ZERO, 20, -PI, 0, 16, Color("f68a36"), 3.0)
	draw_circle(Vector2(0, -20), 4.0 + ticks_left, Color("ffe185"))
