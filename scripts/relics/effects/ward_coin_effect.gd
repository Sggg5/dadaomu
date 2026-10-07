extends RelicEffect
var charged:bool=false
func _on_install()->void:runtime.room_cleared.connect(_clear)
func _on_uninstall()->void:runtime.room_cleared.disconnect(_clear)
func _clear(_context:RoomClearContext)->void:charged=true
func received_damage(amount:float)->float:
	if not charged:return amount
	charged=false
	return amount*0.65
