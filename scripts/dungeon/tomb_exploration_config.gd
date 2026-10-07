class_name TombExplorationConfig
extends Resource
## 只控制可选内容的出现频率，不影响主图生成或普通掉落。
@export_range(0.0, 1.0) var fork_chance: float = 0.45
@export_range(0.0, 1.0) var secret_chance: float = 0.35
@export_range(0.0, 1.0) var standalone_altar_chance: float = 0.25
@export_range(0.0, 1.0) var coffin_chance: float = 0.65
