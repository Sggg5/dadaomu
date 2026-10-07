class_name AntiqueRewardProfile
extends Resource
## 只读稀有度权重，普通来源共享当前楼层曲线；不接触市场价格。
@export var rarity_weights := PackedFloat32Array([55, 30, 12, 3])

func validation_error() -> String:
	if rarity_weights.size() != 4: return "Exactly four rarity weights required"
	var total := 0.0
	for weight in rarity_weights:
		if not is_finite(weight) or weight < 0: return "Weights must be finite and nonnegative"
		total += weight
	return "" if total > 0 else "At least one positive weight required"
