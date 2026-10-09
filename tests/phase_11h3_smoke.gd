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
	var exhibition:=preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(50)
	var score:=MuseumReputationService.evaluate(exhibition).score;var honors:=exhibition.achievements.duplicate(true)
	for index in range(20):
		ExhibitionService.stop(exhibition,&"MAIN");ExhibitionService.start(exhibition,&"MAIN",&"HAN_WEI")
	check(MuseumReputationService.evaluate(exhibition).score==score and exhibition.achievements==honors,"Restarting same qualified topic never stacks reputation/honors")
	exhibition.withdraw_unit(&"CASE_2")
	check(MuseumReputationService.evaluate(exhibition).metrics.topics==1 and exhibition.achievements.has("TWO_TOPICS"),"Withdrawal invalidates current topic strength but retains historical honor")
	print("[11H3] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
