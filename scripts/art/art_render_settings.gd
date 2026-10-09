class_name ArtRenderSettings
extends RefCounted
## Visual-only setting. Never serialized to the player profile or gameplay RNG.
enum Mode { LEGACY, BASIC, ENHANCED }
static var mode: int = Mode.BASIC
static var initialized: bool = false
static func initialize() -> void:
	if initialized: return
	initialized = true
	for arg in OS.get_cmdline_user_args():
		if arg == "--art-mode=legacy": mode = Mode.LEGACY
		elif arg == "--art-mode=enhanced": mode = Mode.ENHANCED
static func active() -> bool:
	initialize()
	return mode != Mode.LEGACY
