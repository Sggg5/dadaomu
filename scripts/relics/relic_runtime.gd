class_name RelicRuntime
extends Node
## Player 拥有的局部 Hook 入口，跨房保留；无全局总线、地图算法或 ID 分支。
signal attack_prepared(context: AttackContext)
signal projectile_spawned(projectile: Projectile)
signal projectile_hit(context: ProjectileHitContext)
signal enemy_killed(enemy: Node2D)
signal player_damaged(amount: float)
signal room_cleared(context: RoomClearContext)

var inventory: RelicInventory
var health: Health
var weapon: RangedWeapon
var room: Room
var _active: bool = false


func configure(player_health: Health, player_weapon: RangedWeapon) -> void:
	health = player_health
	weapon = player_weapon
	inventory = RelicInventory.new(self)
	_active = true
	weapon.attack_modifier = prepare_attack
	health.damaged.connect(_on_damaged)
	health.died.connect(shutdown)


func is_active() -> bool:
	return _active and is_instance_valid(health) and not health.is_dead


func prepare_attack(request: AttackRequest) -> Array[AttackRequest]:
	var context := AttackContext.new(request)
	if is_active():
		inventory.modify_attack(context)
		attack_prepared.emit(context)
	return context.requests if is_active() else []


func bind_projectile(projectile: Projectile) -> void:
	if not is_active():
		return
	projectile.hit.connect(_on_projectile_hit)
	projectile_spawned.emit(projectile)


func notify_enemy_killed(enemy: Node2D) -> void:
	if is_active():
		enemy_killed.emit(enemy)


func notify_room_cleared(context: RoomClearContext) -> void:
	if is_active():
		room_cleared.emit(context)


func _on_projectile_hit(context: ProjectileHitContext) -> void:
	if is_active():
		projectile_hit.emit(context)


func _on_damaged(amount: float) -> void:
	# 致命一击时 Health 已标记死亡；不允许效果逆转死亡或重复结算。
	if is_active():
		player_damaged.emit(amount)


func shutdown() -> void:
	_active = false
	if inventory != null:
		inventory.clear()
	if is_instance_valid(weapon):
		weapon.attack_modifier = Callable()


func _exit_tree() -> void:
	shutdown()
	if is_instance_valid(health):
		if health.damaged.is_connected(_on_damaged):
			health.damaged.disconnect(_on_damaged)
		if health.died.is_connected(shutdown):
			health.died.disconnect(shutdown)
	# RefCounted inventory/effects 回指 runtime，离树时明确断开所有权。
	inventory = null
