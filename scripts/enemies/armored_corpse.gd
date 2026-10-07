class_name ArmoredCorpse
extends ScarabEnemy
## 慢速大体型近战，复用可读咬击状态机，不创建通用护甲系统。
func _draw_body(color: Color) -> void:
	draw_rect(Rect2(-20,-20,40,40),color)
	draw_rect(Rect2(-15,-15,30,30),Color("5a6260"),false,4)
