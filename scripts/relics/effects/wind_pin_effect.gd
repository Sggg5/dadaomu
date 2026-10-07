extends HitRelicEffect
var slows:Dictionary[int,WeakRef]={}
func _on_hit(context:ProjectileHitContext)->void:
	if not context.target is Enemy or context.target.health.is_dead:return
	var id:int=context.target.get_instance_id()
	var slow:BriefSlow=slows[id].get_ref() as BriefSlow if slows.has(id) else null
	if is_instance_valid(slow):slow.remaining=0.7;return
	slow=BriefSlow.new()
	slow.target=context.target
	context.target.add_child(slow)
	slows[id]=weakref(slow)
	own(slow)
