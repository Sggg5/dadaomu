extends RefCounted
## 在真实墙体和玩家碰撞体中检查敌方弹丸，不把碰撞替换成直接伤害调用。

const SCENE: PackedScene = preload("res://scenes/enemies/enemy_projectile.tscn")
var arena: RefCounted
var check: Callable


func _init(context: RefCounted, assertion: Callable) -> void:
	arena = context
	check = assertion


func shoot(origin: Vector2, direction: Vector2, speed: float = 750.0, lifetime: float = 3.0) -> EnemyProjectile:
	var request := AttackRequest.new()
	request.origin = origin
	request.direction = direction
	request.damage = 12.0
	request.speed = speed
	request.lifetime = lifetime
	var bullet := SCENE.instantiate() as EnemyProjectile
	arena.room.projectiles.add_child(bullet)
	bullet.setup(request)
	bullet.track_player(arena.player)
	return bullet


func run() -> void:
	arena.reset_hp()
	var bullet := shoot(arena.player.position - Vector2(80, 0), Vector2.RIGHT)
	await arena.frames(7)
	check.call(arena.player.health.current_hp == 88.0 and not is_instance_valid(bullet), "Enemy projectile hits Player once and is consumed")
	await arena.frames(8)
	check.call(arena.player.health.current_hp == 88.0, "Consumed enemy bullet cannot damage twice")
	bullet = shoot(Vector2(1180, 500), Vector2.RIGHT, 2000.0)
	await arena.frames(3)
	check.call(not is_instance_valid(bullet), "Enemy projectile sweep collides with wall")
	var friendly := arena.spawn(arena.SCARAB, Vector2(800, 500)) as Enemy
	friendly.stop_ai()
	bullet = shoot(Vector2(740, 500), Vector2.RIGHT, 500.0)
	await arena.frames(12)
	check.call(friendly.health.current_hp == friendly.definition.max_hp and is_instance_valid(bullet), "Enemy bullet passes enemies without friendly fire")
	bullet.queue_free()
	bullet = shoot(Vector2(700, 560), Vector2.RIGHT, 1.0, 0.02)
	await arena.frames(4)
	check.call(not is_instance_valid(bullet), "Enemy projectile lifetime expires safely")
	bullet = shoot(Vector2(700, 560), Vector2.RIGHT, 1.0, 100.0)
	arena.player.health.take_damage(1000.0)
	await arena.frames(2)
	check.call(not is_instance_valid(bullet) and not friendly.ai_enabled, "Player death cancels tracked bullets and enemy AI")
