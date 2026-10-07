class_name AntiqueMarketConfig
extends Resource
## 所有市场价格与NPC预算参数只读，避免UI或竞买人各自定价。
@export var dealer_ratio: float = .75
@export var reserve_ratios: Array[float] = [.8,1.0,1.3]
@export var starting_ratio: float = .6
@export var bid_step_ratio: float = .1
@export var commission_ratio: float = .1
@export var bidder_names: Array[String] = ["地方收藏家","沪上商人","洋行买办"]
@export var budget_min: Array[float] = [.85,1.0,.95]
@export var budget_max: Array[float] = [1.2,1.45,1.75]
@export var rarity_bonus: Array[float] = [0.0,.05,.1,.2]
