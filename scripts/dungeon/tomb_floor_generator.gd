class_name TombFloorGenerator
extends RefCounted
## 多层Seed装配与单层生成分离；F1保持Run Seed，F2保留旧有限差异策略。
static func generate(run_seed: int, number: int, tomb: TombDefinition) -> DungeonLayout:
	if tomb == null or not tomb.validation_error().is_empty(): return null
	var data := tomb.floor_at(number)
	if data == null: return null
	var config := data.dungeon_config.duplicate() as DungeonConfig
	config.terminal_is_boss = data.terminal_mode == TombFloorDefinition.TerminalMode.BOSS
	if number == 1: return DungeonGenerator.generate(run_seed, config)
	if number == 2:
		var first_config := tomb.floor_at(1).dungeon_config
		var first := DungeonGenerator.generate(run_seed, first_config)
		for attempt in range(16):
			var seed_value := (run_seed ^ (2 * 104729)) + attempt * 7919
			var result := DungeonGenerator.generate(seed_value, config)
			if result != null and result.spatial_signature() != first.spatial_signature(): return result
		return null
	var seed_value := AntiquePool.stable_score(run_seed, number, tomb.id, &"FLOOR", 1)
	return DungeonGenerator.generate(seed_value, config)
