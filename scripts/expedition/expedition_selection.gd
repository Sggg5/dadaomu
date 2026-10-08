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
static func capture(site:SiteDefinition,campaign:int,day:int,forced:int=0)->ExpeditionSelection:
	if site==null or not site.can_expedition():return null
	var choice:=ExpeditionSelection.new()
	choice.site_id=site.site_id
	choice.region_id=site.region_id
	choice.tomb_definition=site.tomb_definition
	choice.loot_profile_id=site.loot_profile_id
	choice.campaign_seed=campaign
	choice.day_number=day
	choice.seed_value=forced if forced!=0 else ExpeditionSeedService.derive(campaign,day,site.site_id)
	return choice
