class_name EliteBroodMother
extends BroodMother
var final_spawned:bool=false
func death_spawns()->Array[EnemySpawnDefinition]:
	if final_spawned:return []
	final_spawned=true
	var records:Array[EnemySpawnDefinition]=[]
	for side in [-1,1]:
		var record:=EnemySpawnDefinition.new()
		record.enemy_scene=preload("res://scenes/enemies/scarab_enemy.tscn")
		record.enemy_definition=preload("res://data/enemies/scarab.tres")
		record.position=position+Vector2(side*36,0)
		records.append(record)
	return records
