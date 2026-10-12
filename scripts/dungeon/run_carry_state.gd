class_name RunCarryState
extends RefCounted
## 仅HP、遗物/古董只读定义引用；不跨层复用效果实例、计数、冷却或Burn。
var current_hp: float
var relic_definitions: Array[RelicDefinition] = []
var antique_definitions: Array[AntiqueDefinition] = []


static func capture(player: Player) -> RunCarryState:
	var state := RunCarryState.new()
	state.current_hp = player.health.current_hp
	state.antique_definitions = player.antiques.items()
	for id in player.relics.inventory.ids():
		state.relic_definitions.append(player.relics.inventory.get_effect(id).definition)
	return state


func apply(player: Player) -> void:
	player.health.restore(current_hp)
	assert(player.antiques.restore_carry(antique_definitions), "Cross-floor antique carry must be valid")
	for data in relic_definitions: player.relics.inventory.add(data)
