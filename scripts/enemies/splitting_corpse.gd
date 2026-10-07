class_name SplittingCorpse
extends ScarabEnemy
## 死亡记录只返回一次；子体由Spawner登记，父体不直接修改清房状态。
var split_done:bool=false
func death_spawns()->Array[EnemySpawnDefinition]:
	if split_done:return []
	split_done=true
	var records:Array[EnemySpawnDefinition]=[]
	for side in [-1,1]:
		var record:=EnemySpawnDefinition.new()
		record.enemy_scene=preload("res://scenes/enemies/split_fragment.tscn")
		record.enemy_definition=preload("res://data/enemies/split_fragment.tres")
		record.position=position+Vector2(side*36,-12)
		records.append(record)
	return records
func _draw_body(color:Color)->void:
	draw_rect(Rect2(-17,-17,34,34),color)
	draw_line(Vector2(0,-17),Vector2(0,17),Color("352e43"),4)
