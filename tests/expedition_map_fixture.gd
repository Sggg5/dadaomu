extends RefCounted
## Explicit historical test configuration/confirmation, never a production default bypass.
static func confirm(flow:GameFlow)->bool:
	if not is_instance_valid(flow.museum):return false
	flow.site_registry.site(&"DEFAULT_TOMB").tomb_definition=flow.tomb
	var map:=flow.museum.expedition_map
	if not map.panel.visible and not map.open():return false
	map.select_region(&"JINBEI")
	map.select_site(&"DEFAULT_TOMB")
	return map.confirm()
