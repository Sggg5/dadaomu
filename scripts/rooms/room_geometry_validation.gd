class_name RoomGeometryValidation
extends RefCounted
## 24px实体裕量与32px网格洪泛：验证四入口、主要活动区域和全部可走格连通。
## 数据期校验，不替代运行时Physics扫掠或AI视线。
static func validation_error(geometry:RoomGeometryDefinition)->String:
	var free:Dictionary[Vector2i,bool]={}
	for y in range(13):
		for x in range(35):
			var point:=Vector2(96+x*32,176+y*32)
			if geometry.obstacles.all(func(rect:Rect2)->bool:return not rect.grow(24).has_point(point)):free[Vector2i(x,y)]=true
	var center:=Vector2i(17,6)
	# 中央棺布局允许中心被占，但必须有同一连通的主要活动区域。
	if not free.has(center):center=Vector2i(17,2)
	if not free.has(center):return "No main activity region"
	var reached:Dictionary[Vector2i,bool]={center:true}
	var queue:Array[Vector2i]=[center]
	var cursor:=0
	while cursor<queue.size():
		var cell:=queue[cursor]
		cursor+=1
		for offset in DungeonRoom.OFFSETS:
			var next:=cell+offset
			if free.has(next) and not reached.has(next):reached[next]=true;queue.append(next)
	for entry in [Vector2i(17,1),Vector2i(33,6),Vector2i(17,11),Vector2i(1,6)]:
		if not reached.has(entry):return "Blocked or disconnected entry"
	if reached.size()!=free.size():return "Disconnected walkable region"
	return ""
