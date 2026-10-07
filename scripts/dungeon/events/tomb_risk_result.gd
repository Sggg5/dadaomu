class_name TombRiskResult
extends RefCounted
## 一次墓内结算的纯数据；没有Node、Museum或存档引用。
enum Outcome { ANTIQUE, AMBUSH, TRAP, EMPTY }
var event_id: StringName
var resolved: bool = false
var outcome: Outcome
var damage_taken: float = 0
var antique_ids: Array[StringName] = []
var wave_completed: bool = false
