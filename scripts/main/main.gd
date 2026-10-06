extends Control
## Phase 0 启动入口：只承担骨架验证，不提前承载单局或玩法状态。


func _ready() -> void:
	print("[大盗墓时代] Phase 0 bootstrap ready")


func _on_quit_pressed() -> void:
	get_tree().quit()
