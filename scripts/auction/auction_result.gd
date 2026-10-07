class_name AuctionResult
extends RefCounted
## 纯结算快照，不保存场景、竞买人或MuseumState引用。
var instance_id: StringName
var sold: bool = false
var market_value: int
var reserve_price: int
var final_bid: int
var commission: int
var net_proceeds: int
var bid_history: Array[String] = []
