extends RefCounted
var test:SceneTree
var session:DungeonSession
var world:RoomController
var boss:Enemy
const TOMB:TombDefinition=preload("res://data/tombs/default_tomb.tres")
func _init(context:SceneTree)->void:test=context
func setup(definition:BossDefinition,empty_geometry:bool=false)->void:
	if is_instance_valid(session):
		session.queue_free()
		await test.frames(3)
	session=preload("res://scenes/main/dungeon_test.tscn").instantiate()
	session.seed_value=33
	test.root.add_child(session)
	test.session=session
	test.current_scene=session
	await test.frames(3)
	world=session.world
	world.boss_definition=definition
	if empty_geometry:
		world.boss_arena_override=BossArenaDefinition.new()
		world.boss_arena_override.id=&"UNIT_OPEN"
		world.boss_arena_override.tags=definition.compatible_arena_tags.duplicate()
		world.layout.rooms[world.layout.boss_id].definition=world.layout.rooms[world.layout.boss_id].definition.duplicate()
		world.layout.rooms[world.layout.boss_id].definition.obstacles=[]
	world._switch_room(world.layout.boss_id,-1)
	await test.frames(3)
	boss=world.current_room.boss_encounter.boss
func observe(frames:int)->void:
	world.player.weapon.cooldown_remaining=10000 # unit phase observation: no player shots, no HP/invulnerability cheats
	var driver=preload("res://tests/threat_fight_driver.gd").new(test)
	for i in range(int(frames/3)):
		if world.player.health.is_dead:break
		var actors:Array=boss.combat_targets() if boss.has_method("combat_targets") else [boss]
		if actors.is_empty():break
		await driver.shoot_safe(actors[0])
func run()->void:
	for number in range(1,6):
		for definition:Variant in TOMB.floor_at(number).boss_pool.bosses:
			await setup(definition)
			test.check(world.hud.boss_display.visible and world.hud.boss_display.label.text.contains(definition.display_name),"HUD reveals selected Boss only on entry")
			if boss.has_method("combat_targets"):
				var actors:Array=boss.combat_targets()
				test.check(actors.size()==2 and actors[0].health!=actors[1].health,"Twins have two independently damageable Health objects")
				await observe(600)
				test.check(not (actors[0].state==&"WINDUP" and actors[1].state==&"WINDUP"),"Shared rhythm avoids simultaneous twin windups")
				actors[0].health.take_damage(9999)
				await test.frames(2)
				test.check(not world.current_room.boss_encounter.finished and actors[1].solo and actors[1].may_attack,"One twin death unlocks solo skill without completing encounter")
				test.check(is_equal_approx(boss.health.current_hp,actors[1].health.current_hp),"Shared HUD follows surviving independent health")
				actors[1].health.take_damage(9999)
				await test.frames(2)
				test.check(world.current_room.boss_encounter.finished and session.bosses_defeated==1,"Both twin deaths complete exactly one Boss encounter")
				continue
			await observe(900)
			boss.health.take_damage(boss.health.current_hp-boss.health.max_hp*0.4)
			await observe(900)
			boss.health.take_damage(boss.health.current_hp-boss.health.max_hp*0.2)
			await observe(600)
			var phases:Dictionary=boss.get("phases_seen")
			test.check(phases.size()>=2,"Real HP loss activates Boss phases: "+str(definition.id))
			test.check(int(boss.get("skills_executed"))>=3,"Multiple real skills execute: "+str(definition.id))
			if boss is MechanismBoss:test.check(boss.combinations>0 and boss.state in [&"RECOVERY",&"WAIT",&"WINDUP",&"DASH",&"TRANSITION"],"Boss combines skills with explicit recovery/transition state")
			test.capture(str(definition.id)+"_phase_low")
			var old_room:=world.current_room
			world.player.health.take_damage(9999)
			await test.frames(2)
			test.check(not world.hud.boss_display.visible and world.player.health.is_dead,"Boss death UI hides HUD and stops combat")
			test.key(KEY_R)
			await test.frames(5)
			test.check(not is_instance_valid(old_room),"Boss and owned warning zones release on room unload")
	# Destructible eggs, alive/total caps and cancellation.
	await setup(TOMB.floor_at(1).boss_pool.bosses[0])
	var encounter:=world.current_room.boss_encounter
	encounter.create_eggs(20)
	test.check(encounter.eggs.size()==4 and encounter.targets().size()==5,"At most four hittable eggs join encounter targets")
	var egg:=encounter.eggs[0]
	egg.take_damage(9999)
	await test.frames(2)
	test.check(egg.health.is_dead and not egg.hatched,"Player can destroy egg before three-second hatch")
	await observe(240)
	test.check(encounter.total_summons>0 and encounter.total_summons<=18 and encounter.targets().size()<=11,"Egg hatch produces bounded scarabs, never endless swarm")
	encounter.stop()
	var summons:=encounter.total_summons
	encounter._summon(20)
	encounter.create_eggs(20)
	test.check(encounter.total_summons==summons,"Stopped encounter refuses late summons and eggs")
	# Frontal armor, missed slam and collision with world open fixed break window.
	await setup(TOMB.floor_at(4).boss_pool.bosses[0])
	var armored:=boss as MechanismBoss
	armored.set("armor_direction",Vector2.RIGHT)
	world.player.global_position=armored.global_position+Vector2(100,0)
	var hp:=armored.health.current_hp
	armored.take_damage(20)
	test.check(is_equal_approx(hp-armored.health.current_hp,9),"Front armor visibly reduces damage")
	armored.current={"kind":&"CIRCLE"}
	world.player.position=Vector2(1040,496)
	armored._on_skill_finished(&"CIRCLE")
	test.check(is_equal_approx(armored.get("broken"),2.5),"Missed slam opens 2.5-second break window")
	hp=armored.health.current_hp
	armored.take_damage(20)
	test.check(is_equal_approx(hp-armored.health.current_hp,20),"Broken armor allows normal damage")
	armored.phase_index=3
	armored.current={"kind":&"CHARGE"}
	armored.locked=Vector2.RIGHT
	armored.wall_hit=true
	armored._on_skill_finished(&"CHARGE")
	var shards:=world.current_room.projectiles.get_children().filter(func(node:Node)->bool:return node is EnemyProjectile)
	test.check(shards.size()==5 and shards.all(func(node:EnemyProjectile)->bool:return node.velocity.dot(Vector2.RIGHT)<0),"Wall-break fragments fan back into arena instead of vanishing into wall")
	# The actual charge collision branch cannot damage a nearby player through a central wall.
	await setup(TOMB.floor_at(2).boss_pool.bosses[0],true)
	if not (boss is MechanismBoss):return
	var room:=world.current_room
	room._add_block(room.get_node("Walls"),Rect2(650,220,20,300))
	boss.global_position=Vector2(600,368)
	world.player.position=Vector2(690,368)
	world.player.set_physics_process(false)
	boss.ai_enabled=false
	world.player.force_update_transform()
	boss.force_update_transform()
	await test.frames(2)
	boss.ai_enabled=true
	boss.current={"kind":&"CHARGE","damage":18,"duration":0.45,"speed":650}
	boss.state=&"DASH"
	boss.timer=0.45
	boss.locked=Vector2.RIGHT
	await test.frames(10)
	test.check(world.player.health.current_hp==80 and boss.wall_hit and boss.state!=&"DASH","Enhanced charge stops at real wall without proximity damage behind it")
	# Ground targeting must actually cover the snapshot position; cosmetic previews never consume defense.
	await setup(TOMB.floor_at(1).boss_pool.bosses[1],true)
	var caster:=boss as MechanismBoss
	world.player.position=Vector2(900,368)
	caster.pending=[caster.action(&"HANDS",0.8,12,{"count":3})]
	caster._next_action()
	test.check(world.current_room.get_children().any(func(node:Node)->bool:return node is BossTelegraph and node.shape==BossTelegraph.Shape.CIRCLE and node.contains(world.player.global_position)),"Ground hands include a marked player snapshot, requiring movement")
	world.player.relics.inventory.add(preload("res://data/relics/ward_coin.tres"))
	world.player.relics.notify_room_cleared(RoomClearContext.new())
	caster.zone(BossTelegraph.Shape.CIRCLE,world.player.global_position,70,0.01,0,0.2)
	await test.frames(5)
	world.player.take_damage(10)
	test.check(is_equal_approx(world.player.health.current_hp,73.5),"Zero-damage visual telegraph cannot consume one-hit ward defense")
	# Pounce locks a landing point and reaches it by collision sweeps, rather than disguising a short charge.
	await setup(TOMB.floor_at(5).boss_pool.bosses[0],true)
	var pounce:=boss as MechanismBoss
	pounce.ai_enabled=false
	pounce.global_position=Vector2(400,368)
	world.player.global_position=Vector2(900,368)
	world.player.set_physics_process(false)
	world.player.force_update_transform()
	pounce.force_update_transform()
	await test.frames(2)
	pounce.ai_enabled=true
	pounce.pending=[pounce.action(&"POUNCE",0.8,18,{"speed":550,"duration":0.5})]
	pounce._next_action()
	var landing:=pounce.endpoint
	test.check(landing==Vector2(900,368) and world.current_room.get_children().any(func(node:Node)->bool:return node is BossTelegraph and node.shape==BossTelegraph.Shape.CIRCLE and is_equal_approx(node.radius,70)),"Pounce shows locked 70px landing circle")
	await test.frames(45)
	test.check(pounce.state==&"WINDUP" and world.player.health.current_hp==80,"Pounce remains harmless throughout its warning")
	world.player.global_position=Vector2(700,496)
	world.player.force_update_transform()
	await test.frames(40)
	test.check(pounce.endpoint==landing and pounce.global_position.distance_to(landing)<2 and world.player.health.current_hp==80,"Sidestep dodges fixed landing; pounce travels full500px without teleport")
	await setup(TOMB.floor_at(1).boss_pool.bosses[0])
	var container:=world.current_room.projectiles
	for i in range(250):container.add_child(Node2D.new())
	EnemyVolley.fire(boss,Vector2.RIGHT,12,0.2,7,240)
	test.check(container.get_child_count()==256,"Boss volley honors exact shared256 cap even near capacity")
	session.queue_free()
	await test.frames(3)
