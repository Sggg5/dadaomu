class_name EliteCorpseDog
extends CorpseDog
## 冲刺结束后两侧短波；不改变普通尸犬AI或基础伤害。
func _recover()->void:
	super._recover()
	EnemyVolley.fire(self,dash_direction.rotated(PI/2),1,0,7,250,0.6)
	EnemyVolley.fire(self,dash_direction.rotated(-PI/2),1,0,7,250,0.6)
