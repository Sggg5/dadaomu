class_name RelicPool
extends Resource
## 正式池与工程资源完全分开；内容引用只读。
@export var relics: Array[RelicDefinition] = []
@export var reward_version: int = 1


func is_valid() -> bool:
	var ids: Dictionary[StringName, bool] = {}
	for relic in relics:
		if relic == null or relic.id == &"" or str(relic.id).begins_with("test_") or ids.has(relic.id):
			return false
		ids[relic.id] = true
	return relics.size() >= 8
