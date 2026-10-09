class_name MuseumVisitStatistics
extends RefCounted
## Deduplicates complete views independently from exactly-once paid visitors.
var services:Dictionary={}
var _service_seen:Dictionary={}
var hall_visits:Dictionary={}
var unit_visits:Dictionary={}
var topic_visits:Dictionary={}
var interests:Dictionary={}
var view_count:=0
var artifact_views:=0
var feedback:Array[String]=[]
var _seen:Dictionary={}
var _visitors:Dictionary={}
var _instances:Dictionary={}
func record(visitor_index:int,result:Dictionary)->bool:
	var key:="%d:%s"%[visitor_index,result.unit_id]
	if _seen.has(key):return false
	_seen[key]=true
	_visitors[visitor_index]=true
	view_count+=1
	hall_visits[result.hall_id]=hall_visits.get(result.hall_id,0)+1
	unit_visits[result.unit_id]=unit_visits.get(result.unit_id,0)+1
	if not str(result.topic_id).is_empty():topic_visits[result.topic_id]=topic_visits.get(result.topic_id,0)+1
	for id in result.instance_ids:
		artifact_views+=1
		_instances[id]=true
	for category in result.categories:interests[category]=interests.get(category,0)+1
	feedback.append(result.feedback)
	if feedback.size()>8:feedback.pop_front()
	return true
func snapshot()->Dictionary:
	return {"service_visits":services.duplicate(),"view_count":view_count,"artifact_views":artifact_views,"unique_viewers":_visitors.size(),"unique_artifacts":_instances.size(),"hall_visits":hall_visits.duplicate(),"unit_visits":unit_visits.duplicate(),"topic_visits":topic_visits.duplicate(),"interests":interests.duplicate(),"feedback":feedback.duplicate()}

func record_service(index:int,id:StringName)->bool:
	var key:="%d:%s"%[index,id]
	if _service_seen.has(key):return false
	_service_seen[key]=true
	services[str(id)]=services.get(str(id),0)+1
	return true
