extends RefCounted
var test:SceneTree
var session:DungeonSession
var room:Room
var player:Player
func _init(context:SceneTree)->void:test=context
func fresh(obstacles:Array[Rect2]=[])->void:
	if is_instance_valid(session):
		session.queue_free()
		await test.frames(3)
	session=preload("res://scenes/main/dungeon_test.tscn").instantiate()
	session.seed_value=33
	test.root.add_child(session)
	test.session=session
	test.current_scene=session
	await test.frames(3)
	room=session.world.current_room
	player=session.world.player
	player.position=Vector2(1000,320)
	room.definition=room.definition.duplicate()
	room.definition.obstacles=obstacles
	for rect in obstacles:room._add_block(room.get_node("Walls"),rect)
func spawn(id:String,point:Vector2=Vector2(400,320))->Enemy:
	var entry:=EnemySpawnDefinition.new()
	entry.enemy_scene=load("res://scenes/enemies/%s.tscn"%id)
	entry.enemy_definition=load("res://data/enemies/%s.tres"%id)
	entry.position=point
	var data:=RoomDefinition.new()
	data.entry_grace_time=0.35
	data.spawns.append(entry)
	room.enemy_spawner.spawn(data)
	return room.enemy_spawner.get_child(0) as Enemy
func run()->void:
	for id in ["burrowing_corpse","exploding_corpse","splitting_corpse","tomb_crossbow","rotting_corpse","hanging_corpse"]:
		await fresh()
		var actor:=spawn(id)
		var position:=actor.position
		await test.frames(15)
		test.check(actor.position==position and not actor.telegraphing,"New enemy honors entrance grace: "+id)
		await test.frames(10)
		test.check(actor.can_act() and actor.definition.roles>0 and not actor.definition.response_hint.is_empty(),"New enemy activates with role and hint: "+id)
		test.check(actor.take_damage(1) and actor.health.current_hp<actor.health.max_hp,"New enemy real hurt feedback: "+id)
		actor.health.take_damage(9999)
		await test.frames(2)
		test.check(actor.dying and not actor.ai_enabled,"New enemy death stops AI: "+id)
		if id=="splitting_corpse":
			test.check(room.enemy_spawner.get_remaining()==2 and room.enemy_spawner.death_births==2,"Split children included in pending and living clear counts")
			actor.death_spawns()
			test.check(room.enemy_spawner.death_births==2,"Split cannot repeat")
			for child in room.enemy_spawner.get_children():
				if child is Enemy and not child.health.is_dead:child.health.take_damage(9999)
			await test.frames(2)
			test.check(room.enemy_spawner.get_remaining()==0,"No further recursive split")
		await test.frames(30)
		test.check(not is_instance_valid(actor),"Dead actor releases: "+id)
	for id in ["burrowing_corpse","exploding_corpse","splitting_corpse","tomb_crossbow","rotting_corpse","hanging_corpse"]:
		await fresh()
		var attacker:=spawn(id,Vector2(700,320))
		player.position=Vector2(760,320)
		var warned:=false
		for frame in range(300):
			if is_instance_valid(attacker):warned=warned or attacker.telegraphing
			for hazard in room.hazards.get_children():warned=warned or hazard.phase==EncounterHazard.Phase.WARN
			await test.frames(1)
			if player.health.is_dead:break
		test.check(warned,"Real readable warning before attack: "+id)
		test.check(player.health.current_hp<80,"Real live attack damages a stationary player: "+id)
	await fresh()
	var burrow:=spawn("burrowing_corpse") as BurrowingCorpse
	await test.frames(145)
	test.check(burrow.state==BurrowingCorpse.State.BURIED and not burrow.take_damage(5),"Buried corpse rejects damage temporarily")
	player.velocity=Vector2(100,0)
	await test.frames(38)
	test.check(burrow.state==BurrowingCorpse.State.WARNING and burrow.marker!=null and is_equal_approx(burrow.marker.data.warning_time,0.8),"Burrow has real legal dusty warning")
	test.capture("burrow_warning")
	var marker:=burrow.marker
	burrow.health.take_damage(9999)
	await test.frames(60)
	test.check(not is_instance_valid(marker) and room.hazards.get_child_count()==0,"Killed underground actor cannot resurface or leave attack")
	await fresh()
	var corpse:=spawn("exploding_corpse") as ExplodingCorpse
	corpse.stop_ai()
	player.position=corpse.position+Vector2(30,0)
	corpse.health.take_damage(9999)
	await test.frames(25)
	test.check(player.health.current_hp==80 and room.hazards.get_child_count()==1,"Killed exploding corpse waits visible delay")
	await test.frames(20)
	test.check(player.health.current_hp==62,"Killed exploding corpse attacks once after 0.6s")
	await test.frames(30)
	test.check(player.health.current_hp==62 and room.hazards.get_child_count()==0,"Explosion expires without recursion")
	await fresh()
	var crossbow:=spawn("tomb_crossbow") as TombCrossbow
	await test.frames(86)
	test.check(crossbow.winding and crossbow.timer>0.65 and crossbow.timer<=0.8,"Crossbow locks visible line for 0.8s")
	test.capture("crossbow_lock")
	var locked:=crossbow.locked_point
	player.position+=Vector2(0,120)
	await test.frames(60)
	test.check(crossbow.shots==1 and crossbow.locked_point==locked and player.health.current_hp==80,"Sidestep dodges arrow; line does not track")
	await fresh([Rect2(580,240,60,160)])
	crossbow=spawn("tomb_crossbow") as TombCrossbow
	crossbow.stop_ai()
	crossbow.ai_enabled=true
	await test.frames(60)
	test.check(not crossbow.winding and crossbow.shots==0,"Crossbow cannot lock through solid obstacle")
	await fresh()
	var hanger:=spawn("hanging_corpse") as HangingCorpse
	await test.frames(100)
	test.check(hanger.drops==1 and room.hazards.get_child_count()==1,"Hanging corpse creates marked drop")
	test.capture("hanging_warning")
	player.position=Vector2(800,480)
	await test.frames(70)
	test.check(player.health.current_hp==80,"Marked drop is dodgeable")
	await fresh()
	for repeat in range(8):room.hazards.spill(Vector2(480+repeat*5,320),4)
	test.check(room.hazards.get_child_count()==4,"Rot pools capped at four")
	player.position=Vector2(480,320)
	await test.frames(30)
	test.check(player.health.current_hp==80,"Poison is interval damage, not per-frame contact")
	await test.frames(30)
	test.check(player.health.current_hp<80 and player.health.current_hp>=64,"Poison finite slow ticks")
	await test.frames(250)
	test.check(room.hazards.get_child_count()==0,"Poison areas expire after four seconds")
	await fresh()
	var dog:=spawn("elite_corpse_dog") as EliteCorpseDog
	dog.activation_remaining=0
	dog.dash_direction=Vector2.RIGHT
	dog._recover()
	test.check(room.projectiles.get_child_count()==2,"Elite dog produces two short lateral waves")
	await fresh()
	var paper:=spawn("elite_paper_spirit")
	paper.health.take_damage(9999)
	await test.frames(26)
	test.check(room.projectiles.get_child_count()==8,"Elite paper death creates warned slow ring")
	await fresh()
	var mother:=spawn("elite_brood_mother")
	mother.health.take_damage(9999)
	await test.frames(2)
	test.check(room.enemy_spawner.get_remaining()==2 and room.enemy_spawner.death_births==2,"Elite mother last scarabs keep room combat alive")
	await fresh()
	var water:=EncounterHazardDefinition.new()
	water.kind=EncounterHazardDefinition.Kind.WATER
	water.position=player.position
	room.room_state.status=RoomState.Status.ACTIVE
	room.hazards.create(water)
	await test.frames(2)
	test.check(player.environment_speed_multiplier==0.75 and player.health.current_hp==80,"Water only mildly slows, never damages")
	room.hazards.blast(player.position,0.8,80,10)
	var old_room:=room
	var old_hazard:=room.hazards.get_child(0)
	session.queue_free()
	await test.frames(60)
	test.check(not is_instance_valid(old_room) and not is_instance_valid(old_hazard),"Unload cancels hazards, actors and pending damage")
