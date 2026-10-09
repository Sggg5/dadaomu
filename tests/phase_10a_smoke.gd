extends SceneTree
var checks:int=0
var failures:int=0
func _initialize()->void:call_deferred("run")
func check(value:bool,label:String)->void:
	checks+=1
	if not value:failures+=1;push_error("[FAIL] "+label)
func run()->void:
	var catalog:=GlobalMuseumCatalog.new()
	check(catalog.load_file(),"Approved local catalogue loads without internet/database")
	var pool:=preload("res://data/antiques/formal_pool.tres")
	check(catalog.ids().size()==8 and pool.antiques.size()==8,"Old eight game definitions remain independent of real museum collection")
	for definition:AntiqueDefinition in pool.antiques:
		var entry:=catalog.definition(str(definition.id))
		check(not entry.is_empty(),"Legacy ID retained")
		check(entry.display_name==definition.display_name and entry.description==definition.description,"Legacy names/descriptions retained")
		check(entry.base_value==definition.base_value and entry.inventory_slots==definition.slots and entry.exhibit_appeal==definition.exhibit_appeal,"Legacy economy unchanged")
		check(entry.rarity==["COMMON","UNCOMMON","RARE","TREASURE"][definition.rarity],"Legacy rarity unchanged")
		entry.base_value=1
		check(catalog.definition(str(definition.id)).base_value==definition.base_value,"Reader returns independent snapshots")
	check(MuseumProfileStore.VERSION==9,"Authorized management migration uses VERSION9; catalog still has no persistence role")
	var owned:=OwnedAntique.new()
	owned.instance_id=&"test_identity"
	check(owned.instance_id==&"test_identity","OwnedAntique identity remains intact")
	check(not catalog.load_file("https://example.com/catalog.json"),"Runtime rejects network catalog")
	var original:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog/global_catalog.json"))
	original.game_definitions.append(original.game_definitions[0].duplicate(true))
	var file:=FileAccess.open("user://phase_10a_duplicate_test.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(original))
	file.close()
	check(not catalog.load_file("user://phase_10a_duplicate_test.json") and catalog.ids().is_empty(),"Duplicate game IDs reject whole catalogue")
	DirAccess.remove_absolute("user://phase_10a_duplicate_test.json")
	for license in ["UNKNOWN","CC_BY_NC","CC_BY"]:
		original=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog/global_catalog.json"))
		original.game_definitions[0].images=[{"asset_path":"res://icon.svg","license_id":license}]
		file=FileAccess.open("user://phase_10a_media_test.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(original))
		file.close()
		check(not catalog.load_file("user://phase_10a_media_test.json"),"Unknown/NC/unattributed media rejected")
	DirAccess.remove_absolute("user://phase_10a_media_test.json")
	print("[Phase 10A] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
