class_name MuseumAchievementRecord
extends RefCounted
## Immutable completion evidence, never a cash/reward transaction.
static func create(goal:Dictionary,day:int,value:int,event:String)->Dictionary:
	return {"id":goal.id,"day_number":day,"metric":goal.metric,"value":value,"event":event,"reward":goal.reward}
