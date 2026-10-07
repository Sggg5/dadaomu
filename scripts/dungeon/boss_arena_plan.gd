class_name BossArenaPlan
extends RefCounted
const ARENA_VERSION:int=1
static func pick(run_seed:int,floor_number:int,room_id:StringName,pool:BossArenaPool,boss:BossDefinition)->RoomGeometryDefinition:
	assert(pool!=null and pool.validation_error().is_empty())
	var candidates:=pool.compatible(boss)
	assert(not candidates.is_empty(),"Boss has no compatible arena")
	# Independent namespace; does not consume BossRunPlan or ordinary geometry RNG.
	return RoomGeometryPlan.pick(run_seed,floor_number,room_id,StringName("BOSS_ARENA:%s:V%d"%[pool.id,ARENA_VERSION]),candidates)
