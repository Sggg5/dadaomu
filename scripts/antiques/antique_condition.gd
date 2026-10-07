class_name AntiqueCondition
extends RefCounted
## 只生成结算品相快照，独立RNG不会消耗地图/掉落/战斗随机状态。
static func generate(run_seed: int, definition_id: StringName, cargo_index: int, day: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = AntiquePool.stable_score(run_seed,day,definition_id,StringName("condition_%d" % cargo_index),1)
	return rng.randi_range(55,90)
