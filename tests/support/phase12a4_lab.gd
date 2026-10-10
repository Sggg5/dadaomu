extends RefCounted
## Test-only injection into the EXISTING RoomGeometryPlan. Never a map generator.
const LAB_VERSION: int=1
const POOL_PATH="res://tests/fixtures/phase12a4/experimental_pool.tres"
const DECOR=preload("res://tests/support/phase12a4_decor.gd")
var world: RoomController
var room_id: StringName
var original: RoomGeometryDefinition
func _init(controller: RoomController) -> void:
	world=controller; room_id=world.current_id; original=world.current_room.geometry
func select(index: int) -> void:
	assert(index in range(4))
	var pool:=load(POOL_PATH) as RoomGeometryPool
	var selected: RoomGeometryDefinition=original if index==0 else pool.geometries[index-1]
	assert(RoomGeometryValidation.validation_error(selected).is_empty())
	# All resets are limited to the memory fixture; production resources untouched.
	world.geometry_plan.assigned[room_id]=selected
	world.states[room_id]=RoomState.new()
	world.player.health.initialize(world.player.stats.max_hp)
	world.player.invulnerability_remaining=0
	world._switch_room(room_id,Door.Direction.SOUTH)
	if index>0:
		var decor=DECOR.new(); decor.room=world.current_room; decor.layout_index=index
		world.current_room.add_child(decor)
static func metrics(geometry: RoomGeometryDefinition) -> Dictionary:
	var free:=0
	for y in range(13):
		for x in range(35):
			var p:=Vector2(96+x*32,176+y*32)
			if geometry.obstacles.all(func(rect:Rect2)->bool:return not rect.grow(24).has_point(p)): free+=1
	var blocked_area:=0.0
	for rect in geometry.obstacles: blocked_area+=rect.get_area()
	return {"id":str(geometry.id),"obstacle_collisions":geometry.obstacles.size(),"grid_walkable_ratio_24px":float(free)/455,"raw_floor_free_ratio":1-blocked_area/Room.ROOM_RECT.get_area(),"connectivity_error":RoomGeometryValidation.validation_error(geometry),"lab_version":LAB_VERSION}
