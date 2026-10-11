extends Node2D
## Normal Jinbei architecture. Reads existing walls/obstacles; never changes geometry.
const ARCH = preload("res://scripts/art/tomb_quality_architecture.gd")
const PROP = preload("res://scripts/art/tomb_quality_prop.gd")
var room: Room
var replaced: Dictionary = {}
var previous_mode: int = -1
func _ready() -> void:
	z_index = -86
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var architecture = ARCH.new()
	architecture.room = room
	add_child(architecture)
	for surface in room.art_visual.space_surfaces:
		if surface is TombSpacePiece and surface.kind == "wall":
			replaced[surface] = surface.modulate
	var principal: int = -1
	var largest: float = 0
	for index in range(room.obstacles().size()):
		var rect: Rect2 = room.obstacles()[index]
		if rect.size.x >= 64 and rect.size.y >= 60 and rect.size.x / rect.size.y < 2 and rect.get_area() > largest:
			principal = index
			largest = rect.get_area()
	for index in range(room.obstacles().size()):
		var rect: Rect2 = room.obstacles()[index]
		var kind: String = room.art_visual.prop_kind(rect, index)
		if index != principal and kind != "altar": continue
		for surface in room.art_visual.space_surfaces:
			if surface is TombSpacePiece and surface.footprint == rect:
				replaced[surface] = surface.modulate
		var prop = PROP.new()
		prop.footprint = rect
		prop.asset_id = "a5_principal" if index == principal else "a5_offering"
		add_child(prop)
	for side in room.doors:
		var door: Door = room.doors[side]
		replaced[door] = door.modulate
		var gate = PROP.new()
		gate.door = door
		gate.asset_id = "a5_gate"
		add_child(gate)
	_process(0)
func _process(_delta: float) -> void:
	visible = ArtRenderSettings.active() and not room.art_visual.use_old_space
	var mode: int = ArtRenderSettings.mode if visible else -1
	if mode != previous_mode:
		previous_mode = mode
		for item in replaced:
			if is_instance_valid(item): item.modulate = Color.TRANSPARENT if visible else replaced[item]
		queue_redraw()
func _draw() -> void:
	# Low-opacity static contact light also works without real-time Enhanced lamps.
	for rect in room.obstacles():
		for spread in range(12, 0, -2):
			draw_rect(Rect2(rect.position + Vector2(-spread, 0), rect.size + Vector2(spread * 2, spread)), Color(.015, .024, .028, .035))
func _exit_tree() -> void:
	for item in replaced:
		if is_instance_valid(item): item.modulate = replaced[item]
