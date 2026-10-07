class_name OwnedAntique
extends RefCounted
## 一件馆藏的身份；重复Definition也有不同instance_id，不保存夜间Pickup。
var instance_id: StringName
var definition_id: StringName
var acquired_day: int
var identified: bool = false
var condition: int = 100
