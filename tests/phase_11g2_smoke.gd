extends "res://tests/phase_5b_smoke.gd"
func run()->void:
	var state:=MuseumState.new();var item:=state.collection.add(&"ly_attendant",1,80,false)
	check(not MuseumResearchService.register(state,item.instance_id),"Unidentified cannot register")
	state.identify(item.instance_id)
	check(MuseumResearchService.register(state,item.instance_id) and not MuseumResearchService.register(state,item.instance_id),"Manual base registration once")
	var cash:=state.cash;var value:int=AntiqueMarketService.market_value(item,MuseumState.POOL.find_by_id(item.definition_id))
	check(MuseumResearchService.complete(state,item.instance_id,2,"QA") and not MuseumResearchService.complete(state,item.instance_id,2,"QA"),"Type research once per actual instance")
	check(not MuseumResearchService.eligible(state,item.instance_id,3),"One item cannot impersonate topic")
	for id in [&"ly_granary",&"ly_wuzhu"]:
		var other:=state.collection.add(id,1,80,true);MuseumResearchService.register(state,other.instance_id);MuseumResearchService.complete(state,other.instance_id,2,"QA")
	var other:=state.collection.add(&"ly_attendant",1,80,true);MuseumResearchService.register(state,other.instance_id);MuseumResearchService.complete(state,other.instance_id,2,"QA")
	check(MuseumResearchService.eligible(state,item.instance_id,3),"Three researched Han objects with distinct definitions support topic")
	check(MuseumResearchService.complete(state,item.instance_id,3,"QA"),"Topic unlocks actual owned associations")
	check(state.cash==cash and AntiqueMarketService.market_value(item,MuseumState.POOL.find_by_id(item.definition_id))==value,"Research never pays or raises price")
	check("游戏原型" in MuseumResearchService.notes(state,item.instance_id),"Content clearly labeled game proposal")
	state.collection.remove(item.instance_id)
	check(not MuseumResearchService.eligible(state,item.instance_id,3),"Unowned archive cannot receive research")
	print("[11G2] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)


