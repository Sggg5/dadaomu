class_name RunResult
extends RefCounted
## 结算只读数值/名称快照，不持Session、节点或RelicEffect。
var run_seed: int
var floors_cleared: int
var current_hp: float
var max_hp: float
var relic_names: Array[String] = []
var combat_clears: int
var bosses_defeated: int
var antique_names: Array[String] = []
var antique_value: int
