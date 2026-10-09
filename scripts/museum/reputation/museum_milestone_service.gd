class_name MuseumMilestoneService
extends RefCounted
static func metrics(state:MuseumState)->Dictionary:
	var evaluation:=MuseumReputationService.evaluate(state)
	var m:=evaluation.metrics.duplicate();var catalog:=MuseumCollectionCodex.counts(state)
	m["owned"]=catalog.owned;m["discovered"]=catalog.discovered;m["identified_history"]=catalog.identified;m["research_history"]=catalog.researched;m["rank"]=evaluation.rank
	m["topic_research"]=0;m["research_instances"]=0;m["hall_unique"]=0;m["region_topic"]=0
	for record in state.collection.archives.values():
		if record.level>=2:m.research_instances+=1
		if record.level>=3:m.topic_research+=1
	for hall in state.display_catalog.halls:
		var ids:Dictionary={}
		for unit in state.display_catalog.unit_ids(state.museum_level,hall):
			for item in state.unit_items(unit):
				if item.identified:ids[item.definition_id]=true
		m.hall_unique=maxi(m.hall_unique,ids.size())
	for region in SiteRegistry.load_default().regions:
		var rows:=MuseumCollectionCodex.rows(state,str(region.region_id));var types:Dictionary={}
		for row in rows:types[row.category]=true
		var region_rules:Dictionary=MuseumMilestoneDefinition.rules().region_topic_rules
		if rows.size()>=int(region_rules.min_definitions) and types.size()>=int(region_rules.min_categories):m.region_topic=1
	return m
static func observe(state:MuseumState,event:String)->void:
	if state.progress_suspended:return
	MuseumCollectionCodex.capture(state)
	var m:=metrics(state)
	for goal in MuseumMilestoneDefinition.goals():
		if not state.achievements.has(goal.id) and int(m.get(goal.metric,0))>=int(goal.target):
			state.achievements[goal.id]=MuseumAchievementRecord.create(goal,state.day_number,int(m[goal.metric]),event)
