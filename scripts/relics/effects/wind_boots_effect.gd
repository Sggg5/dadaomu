extends RelicEffect
var remaining:float=0
func _on_install()->void:runtime.player_damaged.connect(_hurt)
func _on_uninstall()->void:runtime.player_damaged.disconnect(_hurt)
func _hurt(_amount:float)->void:remaining=0.8
func tick(delta:float)->void:remaining=maxf(0,remaining-delta)
func movement_multiplier()->float:return 1.2 if remaining>0 else 1.0
