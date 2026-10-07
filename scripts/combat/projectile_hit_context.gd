class_name ProjectileHitContext
extends RefCounted
## 成功伤害之后的同步通知；target 只在回调期间保证有效，禁止长期保存节点。
var hit_count: int = 1
var tags: Array[StringName] = []
var direction: Vector2
var target: Object
var position: Vector2
var damage: float
var origin: Vector2
