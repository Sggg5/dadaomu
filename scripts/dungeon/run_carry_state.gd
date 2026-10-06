class_name RunCarryState
extends RefCounted
## 仅HP与只读定义引用；不跨层复用效果实例、计数、冷却或Burn。
var current_hp: float
var relic_definitions: Array[RelicDefinition] = []


static func capture(player: Player) -> RunCarryState:
	var state := RunCarryState.new()
	state.current_hp = player.health.current_hp
	for id in player.relics.inventory.ids():
		state.relic_definitions.append(player.relics.inventory.get_effect(id).definition)
	return state


func apply(player: Player) -> void:
	player.health.restore(current_hp)
	for data in relic_definitions: player.relics.inventory.add(data)
