extends "res://tests/phase_5b_smoke.gd"
func run()->void:
	var state:=MuseumState.new()
	check(MuseumCollectionCodex.counts(state).total==50,"Playable codex denominator is exactly 50, never global index")
	var item:=state.collection.add(&"ly_wuzhu",1,100,true,{"region_id":"LUOYANG","site_id":"BEIMANG_HAN_WEI","run_seed":33,"expedition_day":1})
	state.collection.archives[item.instance_id].level=2;MuseumCollectionCodex.capture(state)
	var row:=MuseumCollectionCodex.rows(state,"LUOYANG")[0]
	check(row.discovered and row.identified and row.researched and row.owned==1,"Collection states combine instead of overwriting")
	state.collection.remove(item.instance_id);MuseumCollectionCodex.capture(state)
	row=MuseumCollectionCodex.rows(state,"LUOYANG")[0]
	check(row.owned==0 and row.discovered and row.researched,"Sale preserves historical discovery/research while owned becomes zero")
	state.collection.add(&"gz_kaiyuan",1,100,true);MuseumCollectionCodex.capture(state)
	check(MuseumCollectionCodex.rows(state,"GUANZHONG").is_empty(),"Name/definition never invents an expedition region")
	var legacy:=MuseumState.new();legacy.collection.add(&"ly_attendant",1,100,true);MuseumCollectionCodex.capture(legacy,true)
	check(legacy.collection_history.ly_attendant.identified_day==0,"Legacy verified state has unknown historical completion date")
	print("[11H2] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
