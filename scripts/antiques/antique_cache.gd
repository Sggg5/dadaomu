class_name AntiqueCache
extends AntiquePedestal
## 清场陪葬匣，复用同一领取接口；不关门、不触发clear或遗物奖励。


func _ready() -> void:
	source_id = &"combat_cache"
	caption = "陪葬匣"
	super._ready()


static func safe_position(room: Room) -> Vector2:
	var candidates: Array[Vector2] = [Room.ROOM_RECT.get_center()+Vector2(0,-160),Room.ROOM_RECT.get_center()+Vector2(-256,0),Room.ROOM_RECT.get_center()+Vector2(256,0)]
	for y in range(208,538,80):
		for x in range(160,1160,80): candidates.append(Vector2(x,y))
	var relic := room.get_node_or_null("RelicPedestal") as Node2D
	for point in candidates:
		if not Room.ROOM_RECT.grow(-40).has_point(point): continue
		if room.obstacles().any(func(rect: Rect2) -> bool: return rect.grow(40).has_point(point)): continue
		if relic != null and point.distance_to(relic.position) < 160: continue
		return point
	return room.get_entry_position(room.doors.keys()[0])
