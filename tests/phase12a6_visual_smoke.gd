extends "res://tests/phase12a6_capture.gd"
var exercised:bool=false
func pause_actors(room:Room,value:bool) -> void:
	super.pause_actors(room,value)
	if not value or exercised:return
	exercised=true
	for actor in room.damage_targets():
		var visual=room.get_node("EnemyArt_"+str(actor.get_instance_id()))
		var old_velocity:Vector2=actor.velocity
		var old_aim:Vector2=actor.aim_direction
		var old_state:int=actor.state
		var old_dying:bool=actor.dying
		var old_timer:float=actor._death_remaining
		var old_warning:bool=actor.telegraphing
		var old_mode:int=ArtRenderSettings.mode
		var old_atlas:Texture2D=visual.atlas
		var hp:float=actor.health.current_hp
		for i in range(4):
			actor.aim_direction=[Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT,Vector2.UP][i]
			actor.velocity=Vector2.ZERO;visual._process(.016)
			check(visual.direction==i,"Independent native direction "+str(i))
			actor.velocity=actor.aim_direction*50;visual._process(.016)
			check(visual.pose=="walk" and visual.cell%16 in range(2,6),"Walk animation exact pose range")
			actor.telegraphing=true;visual._process(.016)
			check(visual.pose=="windup" and visual.warning.visible,"Warning retained on replacement")
			actor.telegraphing=false;actor.velocity=Vector2.ZERO
			actor.state=CorpseDog.State.DASH if actor is CorpseDog else ScarabEnemy.State.RECOVERY
			visual._process(.016)
			check(visual.pose=="attack","Actual AI state maps attack pose")
			visual.hit_time=.12;visual._process(.016)
			check(visual.pose=="hurt","Damage flash independent of body direction")
			visual.hit_time=0;actor.state=old_state
		actor.dying=true
		for fraction in [.99,.70,.45,.10]:
			actor._death_remaining=actor.definition.death_duration*fraction;visual._process(.016)
			check(visual.pose=="death" and visual.cell%16>=12,"Four collapse frames within original lifetime")
		actor.dying=old_dying;actor._death_remaining=old_timer
		ArtRenderSettings.mode=0;visual._process(.016)
		check(actor.modulate==visual.original_tint and not visual.visible,"Legacy restores full real enemy fallback")
		ArtRenderSettings.mode=2;visual.atlas=null;visual._process(.016)
		check(actor.modulate==visual.original_tint and not visual.visible,"Missing enemy atlas preserves body and warning fallback")
		visual.atlas=old_atlas;ArtRenderSettings.mode=old_mode
		actor.velocity=old_velocity;actor.aim_direction=old_aim;actor.state=old_state;actor.telegraphing=old_warning
		visual.pose="idle";visual.hit_time=0;visual.seen_states.clear();visual.seen_directions.clear();visual._process(.016)
		check(actor.health.current_hp==hp and actor.body_radius()==14,"Pose unit exercise changes neither HP nor collision")
	check(room.get_node("CombatArtSample").effects.size()<=48,"Readability effects have bounded buffer")
