class_name SiteRegistry
extends RefCounted
## Local planning index. Research objects and candidates are never loot or OwnedAntique.
var regions:Array[RegionDefinition]=[]
var sites:Array[SiteDefinition]=[]
var loot_profiles:Array[SiteLootProfile]=[]
static func load_default()->SiteRegistry:
	var registry:=SiteRegistry.new()
	var payload:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/expedition/sites.json"))
	for row:Dictionary in payload.loot_interfaces:
		var profile:=SiteLootProfile.new()
		profile.id=StringName(row.id)
		profile.status=StringName(row.status)
		profile.local_artifact_types.assign(row.regional_types)
		profile.historical_period_ranges.assign(row.period_ranges)
		profile.category_weights=row.category_weights.duplicate()
		profile.cross_region_types.assign(row.circulation_types)
		profile.rare_artifact_types.assign(row.rare_types)
		if profile.id!=&"FORMAL_DEFAULT":profile.approved_pool=null
		registry.loot_profiles.append(profile)
	for row:Dictionary in payload.regions:
		var region:=RegionDefinition.new()
		region.region_id=StringName(row.id)
		region.display_name=row.name
		region.description=row.description
		region.map_marker=Vector2(row.marker[0],row.marker[1])
		registry.regions.append(region)
	for row:Dictionary in payload.sites:
		var site:=SiteDefinition.new()
		site.site_id=StringName(row.id)
		site.region_id=StringName(row.region)
		site.display_name=row.name
		site.historical_period=row.period
		site.culture_tags.assign(row.tags)
		site.site_type=row.type
		site.risk_tier=row.risk
		site.unlock_status=StringName(row.status)
		site.map_marker=Vector2(row.marker[0],row.marker[1])
		site.loot_profile_id=StringName(row.loot_profile_id)
		site.background=row.background
		site.enemy_intel=row.enemies
		site.artifact_intel=row.artifacts
		if row.has("tomb"):site.tomb_definition=load(row.tomb)
		registry.sites.append(site)
	return registry
func region(id:StringName)->RegionDefinition:
	for entry in regions:
		if entry.region_id==id:return entry
	return null
func site(id:StringName)->SiteDefinition:
	for entry in sites:
		if entry.site_id==id:return entry
	return null
func sites_in(id:StringName)->Array[SiteDefinition]:
	var result:Array[SiteDefinition]=[]
	for entry in sites:
		if entry.region_id==id:result.append(entry)
	return result
func loot_profile(id:StringName)->SiteLootProfile:
	for profile in loot_profiles:
		if profile.id==id:return profile
	return null
func can_depart(id:StringName)->bool:
	var definition:=site(id)
	if definition==null or not definition.can_expedition():return false
	var profile:=loot_profile(definition.loot_profile_id)
	return profile!=null and profile.usable()
