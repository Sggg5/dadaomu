class_name BossVisual
extends RefCounted
## Explicit asset gap: all Bosses retain their dedicated legacy telegraphs/body.
## Never substitute a magnified ordinary enemy for a Boss animation.
static func has_dedicated_asset(_id: StringName) -> bool:
	return false
