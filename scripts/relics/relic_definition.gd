class_name RelicDefinition
extends Resource
## 内容只读，状态属于每次安装的新 RelicEffect。
enum Rarity { COMMON, UNCOMMON, RARE }
@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var rarity: Rarity = Rarity.COMMON
@export var effect_script: Script
@export var parameters: Dictionary = {}
