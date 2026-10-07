class_name AuctionSession
extends Node2D
## 独立夜间场景。持拍品数值快照和竞价状态，不接触Museum钱包或Dungeon。
signal return_requested(result: AuctionResult)
var bidding := AuctionBidding.new()
var lot_name: String
var condition: int
var day: int
var info: Label
var history: Label
var _returning: bool = false


func configure(item: OwnedAntique, definition: AntiqueDefinition, day_number: int, auction_seed: int, mode: int) -> void:
	lot_name = definition.display_name
	condition = item.condition
	day = day_number
	bidding.configure(item,definition,day_number,auction_seed,mode)


func _ready() -> void:
	info = _label(Vector2(110,45),24,Vector2(1060,285))
	history = _label(Vector2(130,455),18,Vector2(1020,210))
	_refresh()


func _label(location: Vector2, size_value: int, dimensions: Vector2) -> Label:
	var label := Label.new()
	label.position = location
	label.size = dimensions
	label.add_theme_font_size_override("font_size",size_value)
	add_child(label)
	return label


func advance() -> bool:
	if bidding.finished or _returning: return false
	var bid := bidding.next_round()
	_refresh()
	return bid


func request_return() -> bool:
	if not bidding.finished or _returning: return false
	_returning = true
	return_requested.emit(bidding.result)
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo(): return
	if event.is_action_pressed("interact"):
		if bidding.finished: request_return()
		else: advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("quit"): get_tree().quit()


func _refresh() -> void:
	var leader := AntiqueMarketService.CONFIG.bidder_names[bidding.highest_bidder] if bidding.highest_bidder >= 0 else "尚无出价"
	info.text = "第%d天 · 夜间拍卖会\n%s · 品相%d\n市场估值%s · 起拍%s · 保留价%s\n当前报价%s · 最高出价者：%s\n%s" % [day,lot_name,condition,AntiqueDefinition.money(bidding.market_value),AntiqueDefinition.money(bidding.starting_bid),AntiqueDefinition.money(bidding.reserve_price),AntiqueDefinition.money(bidding.current_bid),leader,"[E] 返回博物馆（推进到次日）" if bidding.finished else "[E] 下一轮竞价 · 每次一口"]
	if bidding.finished:
		var result := bidding.result
		info.text += "\n成交价%s · 佣金10%%：-%s · 实际到账%s" % [AntiqueDefinition.money(result.final_bid),AntiqueDefinition.money(result.commission),AntiqueDefinition.money(result.net_proceeds)] if result.sold else "\n流拍 · 古董将退回库房，本次无收入"
	history.text = "竞价历史（最近7条）\n"+"\n".join(bidding.history.slice(maxi(0,bidding.history.size()-7)))
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(70,30,1140,660),Color("20262b"))
	draw_rect(Rect2(70,30,1140,660),Color("bcb09a"),false,3)
	draw_rect(Rect2(580,280,120,65),Color("b29974"))
	for index in range(3):
		var location := Vector2(270+index*370,385)
		draw_circle(location,20,Color("da947f") if index != bidding.highest_bidder else Color("efc96e"))
		draw_string(ThemeDB.fallback_font,location+Vector2(-60,45),AntiqueMarketService.CONFIG.bidder_names[index],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
