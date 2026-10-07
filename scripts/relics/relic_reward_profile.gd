class_name RelicRewardProfile
extends Resource
## Source设计权重，只作用Run开始的奖励规划，不接触战斗动态强度。
@export var role_weights := PackedFloat32Array([40,35,15,10])
func validation_error() -> String:
	if role_weights.size()!=4:return "Four design-role weights required"
	var total:=0.0
	for weight in role_weights:
		if not is_finite(weight) or weight<0:return "Invalid role weight"
		total+=weight
	return "" if total>0 else "Positive weight required"
