class_name Door
extends Node2D
## 门负责阻挡与过门请求，不查地图、不创建下一个房间。
## 持续检查开门后的区域，避免玩家已站在门边时漏掉 body_entered。

signal traversal_requested(side: Direction)

enum Direction { NORTH, EAST, SOUTH, WEST }
const WIDTH: float = 112.0

@export var side: Direction = Direction.NORTH
@onready var blocker: CollisionShape2D = $Blocker/Shape
@onready var trigger: Area2D = $Trigger

var is_open: bool = false
var _requested: bool = false


static func opposite(value: int) -> int:
	return (value + 2) % 4


func set_open(value: bool) -> void:
	is_open = value
	# 最后一个敌人可能在物理回调中死亡，形状更新必须延迟。
	blocker.set_deferred("disabled", value)
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if not is_open or _requested:
		return
	var outward := Vector2.UP.rotated(global_rotation)
	for body in trigger.get_overlapping_bodies():
		if body is Player and not body.health.is_dead and body.controls_enabled:
			if (body.global_position - global_position).dot(outward) >= -8.0:
				_requested = true
				traversal_requested.emit(side)
				return


func _draw() -> void:
	var color := Color("66cfa0") if is_open else Color("d98859")
	if not is_open:
		draw_rect(Rect2(-56, -8, 112, 16), Color("6e4539"))
		for x in range(-48, 49, 16):
			draw_line(Vector2(x, -8), Vector2(x, 8), color, 3.0)
	else:
		draw_line(Vector2(-48, 0), Vector2(48, 0), Color(color, 0.25), 2.0)
		draw_line(Vector2(-10, -2), Vector2(0, -12), color, 3.0)
		draw_line(Vector2(0, -12), Vector2(10, -2), color, 3.0)
	draw_line(Vector2(-56, -10), Vector2(-56, 10), color, 5.0)
	draw_line(Vector2(56, -10), Vector2(56, 10), color, 5.0)
