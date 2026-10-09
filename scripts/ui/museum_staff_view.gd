class_name MuseumStaffView
extends VBoxContainer
## Bounded personnel and artifact lists. Services retain all authority, including OPEN read-only.
var state:MuseumState
var business:MuseumBusiness
var employees:ItemList
var detail:Label
var hire:Button
var fire:Button
var hall:OptionButton
var assign:Button
var search:LineEdit
var artifacts:ItemList
var queue:ItemList
var submit:Button
var cancel_task:Button
var heading:Label
var ids:Array[StringName]=[]
var artifact_ids:Array[StringName]=[]
var task_ids:Array[int]=[]
var page:=0
var queue_page:=0
func _ready()->void:
	var row:=HBoxContainer.new();add_child(row)
	employees=ItemList.new();employees.custom_minimum_size=Vector2(240,140);row.add_child(employees)
	var controls:=VBoxContainer.new();row.add_child(controls);controls.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	detail=Label.new();detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.custom_minimum_size=Vector2(0,65);controls.add_child(detail)
	var actions:=HBoxContainer.new();controls.add_child(actions)
	hire=_button(actions,"招聘",_hire);fire=_button(actions,"解雇",_fire)
	hall=OptionButton.new();actions.add_child(hall)
	for id in [&"MAIN",&"EAST",&"WEST"]:hall.add_item(state.display_catalog.halls[id].display_name)
	assign=_button(actions,"指派导览厅",_assign)
	search=LineEdit.new();search.placeholder_text="搜索本人馆藏名称 / 实例ID（仅列当前岗位可处理项）";add_child(search)
	search.text_changed.connect(func(_s:String)->void:page=0;refresh())
	var lists:=HBoxContainer.new();lists.size_flags_vertical=Control.SIZE_EXPAND_FILL;add_child(lists)
	artifacts=ItemList.new();queue=ItemList.new()
	for list in [artifacts,queue]:list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.custom_minimum_size=Vector2(0,130);lists.add_child(list)
	var buttons:=HBoxContainer.new();add_child(buttons)
	_button(buttons,"库房上一页",func()->void:page=maxi(0,page-1);refresh())
	_button(buttons,"库房下一页",func()->void:page+=1;refresh())
	submit=_button(buttons,"委托选中藏品",_enqueue)
	_button(buttons,"队列上一页",func()->void:queue_page=maxi(0,queue_page-1);refresh())
	_button(buttons,"队列下一页",func()->void:queue_page+=1;refresh())
	cancel_task=_button(buttons,"取消选中任务",_cancel)
	heading=Label.new();add_child(heading)
	employees.item_selected.connect(func(_index:int)->void:page=0;refresh())
	for child in [detail,heading]:child.add_theme_color_override("font_color",Color("382d22"));child.add_theme_font_size_override("font_size",16)
	refresh()
func _button(parent:Node,text:String,action:Callable)->Button:
	var button:=Button.new();button.text=text;button.add_theme_font_size_override("font_size",15);button.pressed.connect(action);parent.add_child(button);return button
func selected_id()->StringName:
	var selected:=employees.get_selected_items()
	return ids[selected[0]] if not selected.is_empty() else ids[0] if not ids.is_empty() else &""
func refresh()->void:
	if not is_instance_valid(employees):return
	var selected:=selected_id();ids.assign(MuseumStaffService.catalog().keys());ids.sort_custom(func(a:StringName,b:StringName)->bool:return str(a)<str(b));employees.clear()
	for id in ids:
		var d:MuseumStaffDefinition=MuseumStaffService.catalog()[id]
		var employed:=state.staff.members.has(id) and state.staff.members[id].employment_status==&"ACTIVE"
		employees.add_item("%s · %s · %s"%[d.display_name,_job(d.job),"在职" if employed else "可聘"])
	if selected==&"":selected=ids[0]
	employees.select(maxi(0,ids.find(selected)))
	var definition:MuseumStaffDefinition=MuseumStaffService.catalog()[selected]
	var active:=state.staff.members.has(selected) and state.staff.members[selected].employment_status==&"ACTIVE"
	var live_day:=business.workday!=null and business.workday.day==state.day_number
	var attending:bool=selected in business.workday.paid_ids if live_day else str(selected) in state.staff.payroll_days.get(state.day_number,{"paid_ids":[]}).paid_ids
	var count:=int(business.workday.completed_counts.get(str(selected),0))+int(business.workday.guide_counts.get(str(selected),0)) if live_day else state.staff.members[selected].last_completed_count if active and state.staff.members[selected].last_attended_day==state.day_number else 0
	var current:=""
	for task in state.staff.tasks:
		if task.staff_id==selected and task.status in [&"PENDING",&"WAITING_FUNDS"]:current+=" #%d"%task.task_id
	detail.text="%s · %s · 技能%d\n招聘 ¥%d / 日薪 ¥%d · 每日能力%d · 今日%s，实际完成%d\n任务：%s"%[definition.display_name,_job(definition.job),definition.skill_level,definition.hire_cost,definition.daily_wage,definition.work_capacity,"出勤" if attending else "未出勤",count,current if current!="" else "无"]
	hire.disabled=not state.can_edit() or active;fire.disabled=not state.can_edit() or not active
	assign.disabled=not state.can_edit() or not active or definition.job!=&"GUIDE"
	for i in range(3):hall.set_item_disabled(i,[&"MAIN",&"EAST",&"WEST"][i] not in state.display_catalog.hall_ids(state.museum_level))
	if active:hall.select([&"MAIN",&"EAST",&"WEST"].find(state.staff.members[selected].assigned_hall))
	var old_artifact:StringName=artifact_ids[artifacts.get_selected_items()[0]] if not artifacts.get_selected_items().is_empty() else &""
	var eligible:Array[OwnedAntique]=[]
	for item in state.collection.all_items():
		var name_text:=MuseumState.POOL.find_by_id(item.definition_id).display_name
		if MuseumStaffTasks.eligible(state,definition.job,item.instance_id) and (search.text.is_empty() or search.text.to_lower() in (name_text+str(item.instance_id)).to_lower()):eligible.append(item)
	page=clampi(page,0,maxi(0,ceili(eligible.size()/20.0)-1));artifacts.clear();artifact_ids.clear()
	for item in eligible.slice(page*20,(page+1)*20):
		artifact_ids.append(item.instance_id);artifacts.add_item("%s · %s · %s"%[item.instance_id,MuseumState.POOL.find_by_id(item.definition_id).display_name,"未鉴定" if not item.identified else "品相%d / 修复¥%d"%[item.condition,state.restoration_cost(item.instance_id)]])
	if old_artifact in artifact_ids:artifacts.select(artifact_ids.find(old_artifact))
	var old_task:=task_ids[queue.get_selected_items()[0]] if not queue.get_selected_items().is_empty() else 0
	queue_page=clampi(queue_page,0,maxi(0,ceili(state.staff.tasks.size()/20.0)-1));queue.clear();task_ids.clear()
	for task in state.staff.tasks.slice(queue_page*20,(queue_page+1)*20):
		task_ids.append(task.task_id)
		var progress:float=business.workday.task_progress(task) if live_day else task.worked_seconds/task.duration()
		queue.add_item("#%d %s %s · %s %.0f%%"%[task.task_id,task.instance_id,{&"RESEARCH":"研究%d级"%task.target_level,&"INSPECT":"保护检查",&"APPRAISE":"鉴定",&"RESTORE":"修复"}.get(task.action(),str(task.action())),_status(task.status),progress*100])
	if old_task in task_ids:queue.select(task_ids.find(old_task))
	submit.disabled=not state.can_edit() or not active or definition.job==&"GUIDE";cancel_task.disabled=not state.can_edit()
	heading.text="现金 ¥%d · 库房%d件 / 页%d · 工作记录%d / 页%d · OPEN只读；完工闭馆提交"%[state.cash,eligible.size(),page+1,state.staff.tasks.size(),queue_page+1]
func _job(job:StringName)->String:return {&"GUIDE":"导览员",&"APPRAISER":"鉴定员",&"CONSERVATOR":"修复师"}.get(job,"")
func _status(status:StringName)->String:return {&"PENDING":"待作业",&"WAITING_FUNDS":"待资金",&"COMPLETED":"完成",&"CANCELLED":"取消"}.get(status,"")
func _hire()->void:MuseumStaffService.hire(state,selected_id());refresh()
func _fire()->void:MuseumStaffService.dismiss(state,selected_id());refresh()
func _assign()->void:MuseumStaffService.assign_hall(state,selected_id(),[&"MAIN",&"EAST",&"WEST"][hall.selected]);refresh()
func _enqueue()->void:
	if not artifacts.get_selected_items().is_empty():MuseumStaffTasks.enqueue(state,selected_id(),artifact_ids[artifacts.get_selected_items()[0]])
	refresh()
func _cancel()->void:
	if not queue.get_selected_items().is_empty():MuseumStaffTasks.cancel(state,task_ids[queue.get_selected_items()[0]])
	refresh()


