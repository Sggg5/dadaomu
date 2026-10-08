class_name RoomGeometryDefinition
extends Resource
## 只读空间数据，与Encounter敌人组合、地图拓扑和运行时状态独立。
@export var id:StringName
@export var obstacles:Array[Rect2]=[]
@export var environments:Array[EncounterHazardDefinition]=[]
@export var tags:Array[StringName]=[]
@export_range(1,100) var selection_weight:int=8

@export var floor_color:Color=Color(0,0,0,0)
@export var wall_color:Color=Color("4f4b43")
@export var accent_color:Color=Color("9b8c68")
@export var visual_motif:StringName=&""
