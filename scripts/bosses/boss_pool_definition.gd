class_name BossPoolDefinition
extends Resource
## 只读遭遇候选，不参与地图/奖励RNG。
@export var id:StringName
@export var bosses:Array[BossDefinition]=[]
func validation_error()->String:
	if id==&"" or bosses.is_empty():return "Boss pool needs ID and entries"
	var ids:Dictionary={}
	for boss in bosses:
		if boss==null or boss.id==&"" or boss.boss_scene==null or not is_finite(boss.max_hp) or boss.max_hp<=0:return "Invalid Boss definition"
		if ids.has(boss.id):return "Duplicate Boss ID"
		ids[boss.id]=true
	return ""
