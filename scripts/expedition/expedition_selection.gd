class_name ExpeditionSelection
extends RefCounted
## Confirmation snapshot: no UI nodes, no global RNG. Tomb resources remain read-only.
var site_id:StringName
var region_id:StringName
var tomb_definition:TombDefinition
var loot_profile_id:StringName
var seed_value:int
var campaign_seed:int
var day_number:int
var _initial_profession_id: StringName = &"NONE"
var initial_profession_id: StringName:
	get: return _initial_profession_id
static func capture(site:SiteDefinition,campaign:int,day:int,forced:int=0,profession:StringName=&"NONE")->ExpeditionSelection:
	if site==null or not site.can_expedition():return null
	if not ProfessionRunState.valid_id(profession):return null
	var choice:=ExpeditionSelection.new()
	choice.site_id=site.site_id
	choice.region_id=site.region_id
	choice.tomb_definition=site.tomb_definition
	choice.loot_profile_id=site.loot_profile_id
	choice.campaign_seed=campaign
	choice.day_number=day
	choice.seed_value=forced if forced!=0 else ExpeditionSeedService.derive(campaign,day,site.site_id)
	choice._initial_profession_id = profession
	return choice
func copy_for_departure() -> ExpeditionSelection:
	# Do not recapture UI: confirmed class/Seed must survive the save boundary.
	var copy := ExpeditionSelection.new()
	copy.site_id = site_id; copy.region_id = region_id
	copy.tomb_definition = tomb_definition; copy.loot_profile_id = loot_profile_id
	copy.seed_value = seed_value; copy.campaign_seed = campaign_seed; copy.day_number = day_number
	copy._initial_profession_id = _initial_profession_id
	return copy
