extends SceneTree
## Isolated native Room fixture, explicitly not the formal GameFlow journey.
var checks: int = 0
var failures: int = 0
func _initialize() -> void: run.call_deferred()
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(label)
	else: print("[PASS] ",label)
func run() -> void:
	ArtRenderSettings.initialized=true; ArtRenderSettings.mode=1
	var room := preload("res://scenes/rooms/room.tscn").instantiate() as Room
	var definition := RoomDefinition.new(); definition.room_id=&"PROPORTIONS_FIXTURE"
	var geometry := RoomGeometryDefinition.new(); geometry.id=&"PROPORTIONS_FIXTURE"
	geometry.obstacles=[Rect2(240,300,40,90),Rect2(520,300,220,55),Rect2(880,300,72,112)]
	room.geometry=geometry
	room.configure(definition,RoomState.new(),[0,1,2,3],RoomDefinition.Type.START)
	root.add_child(room)
	await process_frame; await physics_frame; await process_frame
	for surface in room.art_visual.space_surfaces:
		if surface is TombSpacePiece and surface.kind!="wall":
			var fitted: Rect2=surface.fitted_illustration()
			check(is_equal_approx(fitted.size.x/fitted.size.y,.8),"Uniform illustration ratio "+str(surface.footprint.size))
			var ray:=PhysicsRayQueryParameters2D.create(room.to_global(surface.footprint.get_center()),room.to_global(surface.footprint.get_center()+Vector2(0,1)),1)
			ray.hit_from_inside=true
			check(not room.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(),"Visible pedestal has actual layer1 obstacle")
	for mode in [1,2]:
		ArtRenderSettings.mode=mode; await process_frame; await process_frame
		if DisplayServer.get_name()!="headless":
			RenderingServer.force_draw()
			root.get_texture().get_image().save_png("res://docs/screenshots/phase_12a3/proportions_fixture_%d.png" % mode)
	room.queue_free(); await process_frame
	print("[Phase12A3 proportions] %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
