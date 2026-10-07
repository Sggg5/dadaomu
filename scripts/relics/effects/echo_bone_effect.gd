extends HitRelicEffect
var hits:int=0
func _on_hit(context:ProjectileHitContext)->void:
	if context.tags.has(&"echo"):return
	hits+=1
	if hits%5!=0:return
	var request:=AttackRequest.new()
	request.origin=context.position
	request.direction=context.direction
	request.damage=6
	request.speed=320
	request.lifetime=1
	request.tags.append(&"echo")
	runtime.weapon.attack_requested.emit(request)
