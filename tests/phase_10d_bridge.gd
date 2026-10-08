extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)
func _initialize() -> void:
 var catalog := MuseumResearchCatalog.new()
 check(catalog.load_file(),"load research")
 check(catalog.ids().size()==1441,"record count")
 check(catalog.article_count()==100,"article count")
 check(not catalog.search("化石",true).is_empty(),"Chinese natural search")
 for keyword in ["矿物","陨石","岩石"]:
  check(not catalog.search(keyword,true).is_empty(),"Chinese natural category "+keyword)
 var copy := catalog.record(catalog.ids()[0])
 copy.original_name="mutated"
 check(catalog.record(catalog.ids()[0]).original_name!="mutated","copy isolation")
 var formal := GlobalMuseumCatalog.new()
 check(formal.load_file() and formal.ids().size()==8,"formal eight")
 print("Phase 10D bridge: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
