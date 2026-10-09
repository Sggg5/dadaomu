class_name MuseumReputationService
extends RefCounted
## Pure current strength: distinct definitions, qualified plans, unique dated reports.
## Cash and building level never buy reputation; no economic multiplier is returned.
static func evaluate(state:MuseumState)->MuseumRatingEvaluation:
	var result:=MuseumRatingEvaluation.new()
	var identified:Dictionary={};var researched:Dictionary={};var displayed:Dictionary={};var protected:Dictionary={};var topics:Dictionary={}
	var quality:=0.0;var display_count:=0
	for item in state.collection.all_items():
		if not item.identified:continue
		identified[item.definition_id]=true
		if state.collection.archives[item.instance_id].level>=2:researched[item.definition_id]=true
		if state.case_for(item.instance_id)!=&"":
			displayed[item.definition_id]=true;quality+=item.condition;display_count+=1
			var env:=MuseumCollectionCare.environment(state,item.instance_id)
			if env.protect_level>0 and not MuseumCollectionCare.due(state,item.instance_id):protected[item.definition_id]=true
	for hall in state.exhibition_plans:
		if ExhibitionService.active(state,hall).qualified:topics[state.exhibition_plans[hall]]=true
	var totals:=MuseumDailyReport.totals(state)
	result.metrics={"identified":identified.size(),"researched":researched.size(),"topics":topics.size(),"business_days":totals.days,"visitors":totals.visitors,"displayed":displayed.size(),"quality":floori(quality/display_count) if display_count>0 else 0,"protected":protected.size()}
	var rules:=MuseumReputationDefinition.rules();var score:=0.0
	for key in rules.weights:score+=minf(float(result.metrics[key]),float(rules.caps[key]))*float(rules.weights[key])
	result.score=floori(score)
	for index in range(rules.ratings.size()):
		var row:Dictionary=rules.ratings[index];var pass_conditions:=true
		for key in row.conditions:
			if result.metrics[key]<row.conditions[key]:pass_conditions=false
		if pass_conditions:result.rank=index;result.title=row.name
	if result.rank+1<rules.ratings.size():result.next_conditions=rules.ratings[result.rank+1].conditions.duplicate(true)
	return result
