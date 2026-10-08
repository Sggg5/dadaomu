extends "res://tests/phase_5b_smoke.gd"
func run()->void:
	var catalog:AntiquePool=preload("res://data/antiques/playtest_catalog_50.tres")
	var legacy:AntiquePool=preload("res://data/antiques/formal_pool.tres")
	var profiles:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/antiques/regional_display_profiles.json"))
	check(catalog.antiques.size()==50 and catalog.is_valid(),"Fifty unique runtime definitions valid")
	var counts:Dictionary={&"LUOYANG":0,&"GUANZHONG":0,&"SHARED":0}
	var display:=MuseumDisplayCatalog.new()
	for index in range(50):
		var item:=catalog.antiques[index]
		if index<8:
			check(item==legacy.antiques[index],"Original eight identity and immutable values preserved")
			continue
		check(item.slots>=1 and item.slots<=8 and item.selection_weight>0,"New prototype has legal bag size and nonzero weight")
		check(item.prototype_year_start<=item.prototype_year_end and item.prototype_year_end<=907,"New prototype chronology explicit and pre1933")
		check(item.content_review_status==&"PLAYTEST_PENDING_HISTORICAL_REVIEW" and not item.reference_urls.is_empty(),"Prototype remains draft with traceable reference")
		check(display.accepts(display.units[&"CASE_2"],profiles[str(item.id)]),"Explicit game footprint fits legal combination case")
		counts[&"SHARED" if item.region_ids.size()==2 else item.region_ids[0]]+=1
	check(counts[&"LUOYANG"]==18 and counts[&"GUANZHONG"]==18 and counts[&"SHARED"]==6,"Exact 18/18/6 prototype split")
	print("[11B catalog] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
