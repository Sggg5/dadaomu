class_name MuseumResearchCatalog
extends RefCounted
## Immutable-by-copy local research index; never inserts OwnedAntique or game definitions.
var errors: Array[String] = []
var _records: Dictionary = {}
var _articles: Dictionary = {}
var _media: Dictionary = {}

func load_file(path: String = "res://data/catalog/museum_research_catalog.json") -> bool:
	errors.clear()
	_records.clear()
	_articles.clear()
	_media.clear()
	if not (path.begins_with("res://") or path.begins_with("user://")) or not FileAccess.file_exists(path):
		return _fail("Research catalog missing or nonlocal")
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return _fail("Invalid research JSON")
	var data: Variant = parser.data
	if not data is Dictionary or data.get("schema_version") != 1 or data.get("scope") != "RESEARCH_REFERENCE_NOT_1933_DISCOVERY": return _fail("Invalid research scope/schema")
	for field in ["records", "articles", "media"]:
		if not data.get(field) is Array: return _fail("Invalid research arrays")
	for row: Variant in data.records:
		if not row is Dictionary or not row.get("object_id") is String or not row.object_id.begins_with("object:") or _records.has(row.object_id): return _fail("Invalid/duplicate object identity")
		if not row.get("original_name") is String or not row.get("source_urls") is Array or row.get("object_kind") not in ["CULTURAL_HERITAGE", "NATURAL_HISTORY"]: return _fail("Invalid research fields")
		for field in ["category", "verification_status"]:
			if not row.get(field) is String: return _fail("Missing research field")
		for field in ["recommended_zh_name", "historical_period", "date_label", "geological_period", "description", "museum_name", "accession_number", "article_id", "media_asset_id"]:
			if not row.has(field): return _fail("Missing nullable research field")
			if row.get(field) != null and not row[field] is String: return _fail("Invalid nullable research field")
		for field in ["culture", "source_licenses"]:
			if not row.get(field) is Array: return _fail("Invalid research list")
		var natural: Variant = row.get("natural_history")
		if natural != null:
			if not natural is Dictionary or not natural.get("fields") is Dictionary or not natural.get("issues") is Array or not natural.get("academic_review") is String: return _fail("Invalid natural history fields")
			for values: Variant in natural.fields.values():
				if not values is Array: return _fail("Invalid natural evidence")
				for evidence: Variant in values:
					if not evidence is Dictionary: return _fail("Invalid natural evidence entry")
		_records[row.object_id] = row.duplicate(true)
	for row: Variant in data.articles:
		if not row is Dictionary or not row.get("article_id") is String or _articles.has(row.article_id) or not _records.has(row.get("object_id")) or not row.get("body") is String or row.get("review_status") != "DRAFT_PENDING_REVIEW": return _fail("Invalid article identity/status")
		if not row.get("zh_name") is String or not row.get("editor_version") is float and not row.get("editor_version") is int: return _fail("Invalid editorial fields")
		_articles[row.article_id] = row.duplicate(true)
	for row: Variant in data.media:
		if not row is Dictionary or not row.get("media_id") is String or _media.has(row.media_id): return _fail("Invalid media identity")
		_media[row.media_id] = row.duplicate(true)
	for row: Dictionary in _records.values():
		if row.get("article_id") != null and (not _articles.has(row.article_id) or _articles[row.article_id].object_id != row.object_id): return _fail("Invalid article reference")
	return true

func _fail(message: String) -> bool:
	errors.append(message)
	_records.clear()
	_articles.clear()
	_media.clear()
	return false

func record(id: String) -> Dictionary: return _records.get(id, {}).duplicate(true)
func article(id: String) -> Dictionary: return _articles.get(id, {}).duplicate(true)
func article_count() -> int: return _articles.size()
func media_for(object_id: String) -> Dictionary:
	var row := record(object_id)
	return _media.get(str(row.get("media_asset_id", "")), {}).duplicate(true)

func image_for(object_id: String) -> Texture2D:
	# Validate bytes before decoding; revocation and absent assets degrade to placeholder.
	var media := media_for(object_id)
	if media.is_empty() or media.get("object_id") != object_id or media.get("revoked",true) or media.get("verification_status") != "SOURCE_VERIFIED" or media.get("license_id") not in ["CC0","CC_BY"]: return null
	if media.license_id == "CC_BY" and str(media.get("attribution", "")).strip_edges().is_empty(): return null
	var path := str(media.get("asset_path", ""))
	if not path.begins_with("res://assets/catalog/") or ".." in path or not path.ends_with(".jpg") or not FileAccess.file_exists(path): return null
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size() < 16 or bytes.size() > 5000000 or bytes[0] != 255 or bytes[1] != 216: return null
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	if hash.finish().hex_encode() != media.get("sha256"): return null
	var decoded := Image.new()
	if decoded.load_jpg_from_buffer(bytes) != OK or decoded.get_width() > 1024 or decoded.get_height() > 1024: return null
	return ImageTexture.create_from_image(decoded)
func ids() -> Array:
	var result := _records.keys()
	result.sort()
	return result

func search(keyword: String = "", natural_only: bool = false) -> Array:
	var result: Array = []
	for id: String in ids():
		var row: Dictionary = _records[id]
		if natural_only and row.object_kind != "NATURAL_HISTORY": continue
		var haystack: String = str(row.get("recommended_zh_name", "")) + " " + row.original_name + " " + str(row.get("category", ""))
		if row.object_kind == "NATURAL_HISTORY":
			haystack += " 自然历史 " + str(row.get("natural_history", ""))
			var aliases := {"FOSSIL_SPECIMEN":"化石", "MINERAL_SPECIMEN":"矿物", "METEORITE_SPECIMEN":"陨石", "METEORITE":"陨石", "ROCK_SPECIMEN":"岩石"}
			haystack += str(aliases.get(row.category,""))
		if keyword.is_empty() or haystack.to_lower().contains(keyword.to_lower()): result.append(id)
	return result
