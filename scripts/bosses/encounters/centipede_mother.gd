extends MechanismBoss
## 简单可视体节，无骨骼链；预警曲线、卵、尾扫，低血停止大量召唤。
class BodySegment extends Node2D:
	var color:Color
	func _draw()->void:draw_circle(Vector2.ZERO,20,color)
var segments:Array[Node2D]=[]
func _ready()->void:
	super._ready()
	for i in range(3):
		var node:=BodySegment.new()
		node.color=definition.body_color.darkened((i+1)*0.1)
		node.position=Vector2(-26*(i+1),0)
		add_child(node)
		segments.append(node)
func _tick_ai(delta:float)->void:
	super._tick_ai(delta)
	var forward:=locked if not locked.is_zero_approx() else Vector2.RIGHT
	for i in range(segments.size()):segments[i].position=-forward*float((i+1)*26)+forward.orthogonal()*sin(cycles+i)*8
func _init()->void:phase_thresholds=[0.5,0.25]
func choose_actions(_distance:float)->Array:
	if phase_index==3:return [action(&"CURVE",0.65,14,{"speed":500,"duration":0.65}),action(&"SWEEP",0.7,16)]
	match cycles%3:
		0:return [action(&"CURVE",0.8,14,{"speed":430,"duration":0.75})]
		1:return [action(&"EGGS",0.8,0,{"count":3})]
	return [action(&"SWEEP",0.8,16,{"radius":185})]
func _on_skill_finished(kind:StringName)->void:
	if kind==&"CURVE" and phase_index>=2:
		for i in range(3):
			var point:=global_position-locked*float(i*60)
			zone(BossTelegraph.Shape.CIRCLE,point,42,0.6,4,2)
func _draw_body(color:Color)->void:
	draw_circle(Vector2.ZERO,23,color)
	draw_circle(Vector2(0,-6),5,Color("ffc06b"))
