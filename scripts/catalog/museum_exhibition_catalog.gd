class_name MuseumExhibitionCatalog
extends RefCounted
## Research-only proposals, loaded from the existing database definitions, no benefits.
var errors: Array[String] = []
var _plans: Dictionary = {}
func load_file(research: MuseumResearchCatalog, path: String = "res://data/catalog/museum_exhibitions.json") -> bool:
	_plans.clear()
	errors.clear()
	if not (path.begins_with("res://") or path.begins_with("user://")) or not FileAccess.file_exists(path): return _fail("Missing exhibitions")
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return _fail("Invalid exhibition JSON")
	var data: Variant = parser.data
	if not data is Dictionary or data.get("schema_version") != 1 or data.get("scope") != "PLANNING_ONLY_NOT_OWNED" or not data.get("exhibitions") is Array: return _fail("Invalid exhibition schema/scope")
	for row: Variant in data.exhibitions:
		if not row is Dictionary or not row.get("exhibition_id") is String or _plans.has(row.exhibition_id) or row.get("curation_status") != "DRAFT_PENDING_REVIEW": return _fail("Invalid exhibition identity/status")
		if not row.get("reading_order") is Array or not row.get("featured_object_ids") is Array or row.reading_order.size() != row.featured_object_ids.size(): return _fail("Invalid exhibition order")
		var seen: Array = []
		for id: Variant in row.reading_order:
			if not id is String or research.record(id).is_empty() or id not in row.featured_object_ids or id in seen: return _fail("Invalid exhibition object")
			seen.append(id)
		for id: Variant in row.get("related_article_ids",[]):
			if research.article(str(id)).is_empty(): return _fail("Invalid related article")
		_plans[row.exhibition_id] = row.duplicate(true)
	return true

func _fail(message: String) -> bool:
	errors.append(message)
	_plans.clear()
	return false
func ids() -> Array:
	var result := _plans.keys()
	result.sort()
	return result
func plan(id: String) -> Dictionary: return _plans.get(id,{}).duplicate(true)
