extends RefCounted
## Explicit isolated QA collection only. Never used by production GameFlow or user save.
static func state_with_displays(count:int=50)->MuseumState:
	var state:=MuseumState.new()
	state.campaign_seed=52
	state.museum_level=2
	state.cash=2500
	var main_ids:Array[StringName]=[]
	for id in [&"ly_attendant",&"ly_wuzhu",&"ly_granary",&"gz_sancai_camel",&"gz_floral_mirror",&"gz_jade_belt"]:
		main_ids.append(state.collection.add(id,1,95,true).instance_id)
	state.fill_unit(&"CASE_2",main_ids.slice(0,3))
	state.fill_unit(&"CASE_3",main_ids.slice(3,6))
	for id in [&"ly_wuzhu",&"gz_kaiyuan",&"ly_wuzhu"]:
		var item:=state.collection.add(id,1,90,true)
		state.fill_unit(&"COIN_E1",[item.instance_id])
	for index in range(maxi(0,count-state.collection.all_items().size())):
		var pool:AntiquePool=load("res://data/antiques/playtest_catalog_50.tres")
		state.collection.add(pool.antiques[index%50].id,1,65+index%36,index%5!=0)
	ExhibitionService.start(state,&"MAIN",&"HAN_WEI")
	ExhibitionService.start(state,&"EAST",&"COINS")
	return state
