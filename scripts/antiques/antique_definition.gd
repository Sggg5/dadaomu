class_name AntiqueDefinition
extends Resource
## 只读收藏/占格/估值数据；无战斗Hook或永久经济逻辑。
enum Rarity { COMMON, UNCOMMON, RARE, TREASURE }
@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var base_value: int = 1
@export var slots: int = 1
@export var rarity: Rarity = Rarity.COMMON
@export var exhibit_appeal: int = 1


func is_valid() -> bool:
	return id != &"" and not display_name.is_empty() and base_value > 0 and slots >= 1 and rarity in Rarity.values()


static func money(value: int) -> String:
	var digits := str(value)
	var result := ""
	for index in range(digits.length()):
		if index > 0 and (digits.length()-index)%3 == 0: result += ","
		result += digits[index]
	return "¥"+result

## Playtest prototype metadata. Not a museum accession/provenance claim or expert approval.
@export var culture_period:String=""
@export var region_ids:Array[StringName]=[]
@export var category:StringName=&""
@export var prototype_year_start:int=0
@export var prototype_year_end:int=0
@export var loot_group:StringName=&"LEGACY"
@export_range(1,100) var selection_weight:int=1
@export var content_review_status:StringName=&"LEGACY_GAME_PROTOTYPE"
@export_multiline var historical_reference_note:String=""
@export var reference_urls:Array[String]=[]
