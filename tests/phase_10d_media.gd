extends SceneTree
var checks:=0
var failures:=0
func check(ok:bool, text:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(text)
func _initialize()->void:
 var catalog:=MuseumResearchCatalog.new()
 check(catalog.load_file(),"catalog load")
 var pictured:=0
 for id:String in catalog.ids():
  var row:=catalog.record(id)
  if row.media_asset_id!=null:
   check(catalog.image_for(id)!=null,"verified image decoded")
   pictured+=1
 check(pictured==2,"exactly two portable photos")
 var path:="user://tests/10d_invalid.json"
 DirAccess.make_dir_recursive_absolute("user://tests")
 var file:=FileAccess.open(path,FileAccess.WRITE)
 file.store_string("{broken");file.close()
 check(not catalog.load_file(path) and catalog.ids().is_empty(),"corrupt JSON rejected atomically")
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog/museum_research_catalog.json"))
 data.media[0].revoked=true
 file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(data));file.close()
 check(catalog.load_file(path),"revoked record loads safe metadata")
 check(catalog.image_for(data.media[0].object_id)==null,"revoked image hidden")
 data.media[0].revoked=false;data.media[0].asset_path="res://assets/catalog/../escape.jpg"
 file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(data));file.close()
 check(catalog.load_file(path) and catalog.image_for(data.media[0].object_id)==null,"traversal media hidden")
 data.media[0].asset_path=data.media[1].asset_path;data.media[0].sha256="bad"
 file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(data));file.close()
 check(catalog.load_file(path) and catalog.image_for(data.media[0].object_id)==null,"hash mismatch hidden")
 DirAccess.remove_absolute(path)
 print("Phase 10D media: %d checks, %d failures" %[checks,failures])
 quit(1 if failures else 0)
