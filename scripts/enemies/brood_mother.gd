class_name BroodMother
extends Enemy
## 静止弱攻击与定期召唤；实际房间/每母体上限由Spawner统一保护。
signal summon_requested(count: int)
var timer: float = 2.0
var winding: bool = false
var summons_requested: int = 0
func _tick_ai(delta: float) -> void:
	velocity=Vector2.ZERO
	timer-=delta
	if timer>0: return
	if not winding:
		winding=true
		telegraphing=true
		timer=definition.windup_time
	else:
		winding=false
		telegraphing=false
		summons_requested+=1
		summon_requested.emit(1)
		EnemyVolley.fire(self,aim_direction,1,0,5,200,1.4)
		timer=definition.attack_cooldown
func _draw_body(color: Color) -> void:
	draw_circle(Vector2.ZERO,20,color)
	for x in [-12,0,12]: draw_circle(Vector2(x,0),5,Color("565637"))
