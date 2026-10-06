class_name RoomController
extends Node2D
## 消费注入的 DungeonLayout，持有唯一玩家和各房状态，不负责生成算法。
## 门请求后立即冻结输入，再延迟卸载房间，避免在物理查询中删除碰撞体。

signal room_changed(room_id: StringName)
signal restart_requested
signal room_cleared(context: RoomClearContext)
signal floor_exit_requested
signal run_complete_requested
signal boss_defeated
signal extraction_requested

const ROOM_SCENE: PackedScene = preload("res://scenes/rooms/room.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/player/projectile.tscn")
const ANTIQUE_POOL: AntiquePool = preload("res://data/antiques/formal_pool.tres")
var run_seed: int
var antique_loot: AntiqueLootService = AntiqueLootService.new()
var layout: DungeonLayout
var rewards: RelicRewardService
var floor_number: int = 1
var floor_offset: int = 0
var boss_definition: BossDefinition
var final_floor: bool = false
var run_finished: bool = false
var antique_panel: AntiqueInventoryPanel

@onready var player: Player = $Player
@onready var hud: RoomTestHUD = $HUD

var states: Dictionary[StringName, RoomState] = {}
var current_room: Room
var current_id: StringName
var transitioning: bool = false
var _restarting: bool = false


func _ready() -> void:
	assert(layout != null and layout.rooms.has(layout.start_id), "Inject a DungeonLayout before adding RoomController")
	antique_loot.configure(run_seed,floor_number,layout)
	for room_id in layout.rooms:
		assert(layout.rooms[room_id].definition != null)
		states[room_id] = RoomState.new()
	player.weapon.attack_requested.connect(_spawn_projectile)
	player.health.changed.connect(hud.show_hp)
	player.antiques.changed.connect(func() -> void: hud.show_antiques(player.antiques))
	hud.show_antiques(player.antiques)
	antique_panel = AntiqueInventoryPanel.new()
	antique_panel.inventory = player.antiques
	antique_panel.can_manage = func() -> bool: return not run_finished and player.controls_enabled and not player.health.is_dead
	add_child(antique_panel)
	player.died.connect(_on_player_died)
	if rewards != null:
		room_cleared.connect(rewards.on_room_cleared)
		rewards.reward_available.connect(_create_pedestal)
		player.died.connect(rewards.stop)
	hud.damage_requested.connect(apply_test_damage)
	hud.restart_requested.connect(restart)
	hud.quit_requested.connect(_quit)
	hud.show_hp(player.health.current_hp, player.health.max_hp)
	var relic_panel := RelicDebugPanel.new()
	relic_panel.name = "RelicDebugPanel"
	relic_panel.runtime = player.relics
	add_child(relic_panel)
	_switch_room(layout.start_id, -1)
	print("[大盗墓时代] Dungeon ready: Seed %d, %d rooms" % [layout.seed_value, layout.rooms.size()])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("test_damage") and not event.is_echo():
		apply_test_damage()
	elif event.is_action_pressed("restart") and not event.is_echo():
		restart()
	elif event.is_action_pressed("quit"):
		_quit()


func apply_test_damage() -> void:
	if not transitioning and not run_finished:
		player.take_damage(25.0)


func restart() -> void:
	if _restarting:
		return
	_restarting = true
	player.set_controls_enabled(false)
	if restart_requested.has_connections():
		restart_requested.emit()
	else:
		# 独立回归夹具重新注入固定图，生产入口由 Session 接管。
		get_tree().call_deferred("reload_current_scene")


func _quit() -> void:
	get_tree().quit()


func request_traversal(side: int) -> bool:
	if run_finished: return false
	if transitioning or _restarting or player.health.is_dead or current_room == null:
		return false
	if current_room.room_state.status != RoomState.Status.CLEARED:
		return false
	var neighbors: Dictionary[int, StringName] = layout.rooms[current_id].neighbors
	if not neighbors.has(side) or not current_room.doors[side].is_open:
		return false
	transitioning = true
	player.set_controls_enabled(false)
	_switch_room.call_deferred(neighbors[side], Door.opposite(side))
	return true


func _switch_room(target_id: StringName, entry_side: int) -> void:
	if player.health.is_dead or _restarting:
		transitioning = false
		return
	if is_instance_valid(current_room):
		current_room.process_mode = Node.PROCESS_MODE_DISABLED
		$RoomHost.remove_child(current_room)
		current_room.queue_free()
	current_id = target_id
	current_room = ROOM_SCENE.instantiate() as Room
	var sides: Array[int] = []
	var node := layout.rooms[target_id]
	for side in node.neighbors:
		sides.append(side)
	current_room.boss_definition = boss_definition
	current_room.can_exit = func() -> bool: return not run_finished and not transitioning and not _restarting
	if node.room_type == RoomDefinition.Type.ANTIQUE: current_room.antique_definition = ANTIQUE_POOL.pick(run_seed,floor_number,target_id)
	if antique_loot.has_cache(target_id): current_room.cache_definition = ANTIQUE_POOL.pick(run_seed,floor_number,target_id,&"combat_cache")
	current_room.final_floor = final_floor
	current_room.boss_defeated.connect(func() -> void: boss_defeated.emit())
	current_room.run_complete_requested.connect(func() -> void: run_complete_requested.emit())
	current_room.extraction_requested.connect(func() -> void: extraction_requested.emit())
	current_room.configure(node.definition, states[target_id], sides, node.room_type, player, EncounterDifficulty.from_depth(node.distance_from_start + floor_offset))
	hud.hide_boss()
	current_room.boss_started.connect(hud.show_boss)
	current_room.floor_exit_requested.connect(func() -> void: floor_exit_requested.emit())
	current_room.traversal_requested.connect(request_traversal)
	current_room.state_changed.connect(func(_status: RoomState.Status) -> void: _refresh_hud())
	current_room.enemy_count_changed.connect(func(_count: int) -> void: _refresh_hud())
	$RoomHost.add_child(current_room)
	current_room.enemy_spawner.enemy_killed.connect(player.relics.notify_enemy_killed)
	player.relics.room = current_room
	current_room.cleared.connect(_on_room_cleared)
	player.global_position = current_room.to_global(current_room.get_entry_position(entry_side))
	player.velocity = Vector2.ZERO
	current_room.enter()
	transitioning = false
	player.set_controls_enabled(true)
	_refresh_hud()
	room_changed.emit(current_id)


func _spawn_projectile(request: AttackRequest) -> void:
	if run_finished: return
	if transitioning or player.health.is_dead or _restarting:
		return
	var projectile := PROJECTILE_SCENE.instantiate() as Projectile
	current_room.projectiles.add_child(projectile)
	projectile.setup(request)
	player.relics.bind_projectile(projectile)


func _refresh_hud() -> void:
	hud.show_room(layout.rooms[current_id], current_room.room_state, current_room.remaining_count())
	hud.show_map(layout, states, current_id)
	hud.show_floor(floor_number, current_room.difficulty.depth, current_room.difficulty.tier)


func _on_player_died() -> void:
	antique_panel.panel.hide()
	player.set_controls_enabled(false)
	current_room.stop_combat()
	hud.hide_boss()
	var pedestal := current_room.get_node_or_null("RelicPedestal")
	if pedestal != null:
		pedestal.queue_free()
	hud.show_death()


func _on_room_cleared() -> void:
	var context := RoomClearContext.new()
	context.room_id = scoped_room_id(current_id)
	context.room_type = current_room.room_type
	context.was_combat = context.room_type == RoomDefinition.Type.COMBAT
	context.enemy_count = 1 if current_room.boss_definition != null and context.room_type == RoomDefinition.Type.BOSS else (current_room.definition.spawns.size() if context.room_type in [RoomDefinition.Type.COMBAT, RoomDefinition.Type.BOSS] else 0)
	player.relics.notify_room_cleared(context)
	room_cleared.emit(context)


func _create_pedestal(definition: RelicDefinition, room_id: StringName) -> void:
	if player.health.is_dead or room_id != scoped_room_id(current_id):
		return
	var pedestal := RelicPedestal.new()
	pedestal.name = "RelicPedestal"
	pedestal.definition = definition
	pedestal.player = player
	pedestal.position = RelicPedestal.safe_position(current_room)
	current_room.add_child(pedestal)


func scoped_room_id(id: StringName) -> StringName:
	return id if floor_number == 1 else StringName("F%d:%s" % [floor_number, id])
