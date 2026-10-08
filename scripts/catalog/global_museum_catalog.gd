class_name GlobalMuseumCatalog
extends RefCounted
## 只消费审核后本地JSON；不连接SQLite/互联网，不修改古董池或OwnedAntique。
var errors:Array[String]=[]
var world_year:int=1933
var _definitions:Dictionary[String,Dictionary]={}

func load_file(path:String="res://data/catalog/global_catalog.json")->bool:
	errors.clear()
	_definitions.clear()
	if not path.begins_with("res://") and not path.begins_with("user://"):
		errors.append("Catalog must be local")
		return false
	if not FileAccess.file_exists(path):
		errors.append("Catalog missing")
		return false
	var parser:=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK:
		errors.append("Invalid catalog JSON")
		return false
	var data:Variant=parser.data
	if not data is Dictionary or data.get("schema_version")!=1 or not data.get("game_definitions") is Array:
		errors.append("Unsupported catalog schema")
		return false
	world_year=int(data.get("world_year",1933))
	for row:Variant in data.game_definitions:
		if not row is Dictionary or not row.get("game_id") is String:
			errors.append("Invalid definition identity")
			continue
		var id:String=row.game_id
		if id.is_empty() or _definitions.has(id):
			errors.append("Duplicate/empty game ID")
			continue
		if not row.get("display_name") is String or row.display_name.is_empty() or row.get("rarity") not in ["COMMON","UNCOMMON","RARE","TREASURE"]:
			errors.append("Invalid game name or rarity")
			continue
		if not _integer(row.get("base_value"),1,1000000000) or not _integer(row.get("inventory_slots"),1,8) or not _integer(row.get("exhibit_appeal"),0,1000000000):
			errors.append("Invalid economic fields")
			continue
		if not row.get("images") is Array or not row.get("reference_object_ids") is Array or not row.get("description") is String:
			errors.append("Invalid catalog fields")
			continue
		for media:Variant in row.get("images",[]):
			if not media is Dictionary or not str(media.get("asset_path","")).begins_with("res://") or media.get("license_id") not in ["CC0","CC_BY"]:
				errors.append("Nonlocal or unapproved media")
			elif media.license_id=="CC_BY" and (not media.get("attribution") is String or media.attribution.strip_edges().is_empty()):
				errors.append("Missing media attribution")
		if row.get("game_asset_id")!=null and not str(row.game_asset_id).begins_with("res://"):
			errors.append("Nonlocal game asset")
		_definitions[id]=row.duplicate(true)
	if not errors.is_empty():_definitions.clear()
	return errors.is_empty()

func _integer(value:Variant,minimum:int,maximum:int)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and value>=minimum and value<=maximum

func definition(id:String)->Dictionary:return _definitions.get(id,{}).duplicate(true)
func ids()->Array[String]:
	var result:Array[String]=[]
	result.assign(_definitions.keys())
	result.sort()
	return result
