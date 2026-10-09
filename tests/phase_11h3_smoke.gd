extends "res://tests/phase_5b_smoke.gd"
func run()->void:
	var state:=MuseumState.new();var item:=state.collection.add(&"ly_wuzhu",1,100,false)
	check(state.achievements.has("FIRST_ACCESSION"),"Actual acquisition awards first accession once")
	var first:Dictionary=state.achievements.FIRST_ACCESSION.duplicate(true)
	state.day_number=2;state.identify(item.instance_id)
	check(state.achievements.FIRST_ACCESSION==first and state.achievements.has("FIRST_IDENTIFIED"),"Identification does not repeat accession honor/date")
	var before:=state.achievements.duplicate(true);MuseumReputationService.evaluate(state);MuseumCollectionCodex.rows(state)
	check(before==state.achievements,"UI/read-only queries cannot award achievements")
	state.collection.remove(item.instance_id)
	check(state.achievements.has("FIRST_IDENTIFIED") and MuseumCollectionCodex.counts(state).owned==0,"Historical honor survives sale while current state falls")
	check(MuseumMilestoneDefinition.goals().size()>=15,"At least fifteen stable reachable configured targets")
	var ids:Dictionary={}
	for goal in MuseumMilestoneDefinition.goals():ids[goal.id]=true;check(goal.target>0 and goal.reward!="","Target is finite with visible cosmetic reward: "+goal.id)
	check(ids.size()==MuseumMilestoneDefinition.goals().size(),"Goal IDs unique")
	print("[11H3] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
