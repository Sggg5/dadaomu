class_name MuseumFacilityState
extends RefCounted
## Pure progression/expense values. Stable facilities derive from display IDs, never RNG.
var levels:Dictionary[StringName,int]={}
var expenses:Array[Dictionary]=[]
var next_transaction:=1
func level(id:StringName)->int:return levels.get(id,0)
func record(day:int,kind:String,id:String,amount:int,from_level:int,to_level:int)->void:
	expenses.append({"transaction_id":next_transaction,"day_number":day,"kind":kind,"target_id":id,"amount":amount,"from_level":from_level,"to_level":to_level})
	next_transaction+=1
