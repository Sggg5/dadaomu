class_name Health
extends Node
## 生命状态属于实例。死亡只发出一次，调用者决定尸体/场景的生命周期。

signal changed(current_hp: float, max_hp: float)
signal damaged(amount: float)
signal died

var max_hp: float = 1.0
var current_hp: float = 1.0
var is_dead: bool = false


func initialize(value: float) -> void:
	max_hp = maxf(value, 1.0)
	current_hp = max_hp
	is_dead = false
	changed.emit(current_hp, max_hp)


func take_damage(amount: float) -> bool:
	if is_dead or amount <= 0.0 or not is_finite(amount):
		return false
	var actual_damage := minf(amount, current_hp)
	current_hp -= actual_damage
	is_dead = current_hp <= 0.0
	changed.emit(current_hp, max_hp)
	damaged.emit(actual_damage)
	if is_dead:
		died.emit()
	return true
