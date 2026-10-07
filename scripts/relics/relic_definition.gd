class_name RelicDefinition
extends Resource
## 内容只读，状态属于每次安装的新 RelicEffect。
enum Rarity { COMMON, UNCOMMON, RARE }
enum DesignRole { CORE, SYNERGY, UTILITY, TRADEOFF }
@export var design_role: DesignRole = DesignRole.SYNERGY
@export_range(1,4) var power_band: int = 2
@export var archetype_tags: Array[StringName] = []
@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var rarity: Rarity = Rarity.COMMON
@export var effect_script: Script
@export var parameters: Dictionary = {}
