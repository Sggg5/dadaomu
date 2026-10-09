extends SceneTree
func _initialize()->void:
	var rows:=MuseumCollectionCodex.rows(MuseumState.new())
	var f:=FileAccess.open("res://logs/11h_catalog_50.json",FileAccess.WRITE);f.store_string(JSON.stringify(rows,"\t"));f.close();quit()
