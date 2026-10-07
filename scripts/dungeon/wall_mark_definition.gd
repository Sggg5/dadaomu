class_name WallMarkDefinition
extends RefCounted
## 一块墙面异常的只读生成数据；真假只影响检查结果，不影响初始呈现。
var id: StringName
var side: int
var position: Vector2
var variant: int
var is_secret: bool = false
var inspect_result: String
