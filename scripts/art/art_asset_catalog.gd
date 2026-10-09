class_name ArtAssetCatalog
extends RefCounted
## Missing PNGs are a normal fallback, never an error in gameplay configuration.
static var _textures: Dictionary = {}
static func texture(id: String) -> Texture2D:
	var path := "res://assets/art/%s.png" % id
	if not ResourceLoader.exists(path): return null
	if not _textures.has(id): _textures[id] = load(path) as Texture2D
	return _textures[id] as Texture2D
static func frame(id: String, column: int, row: int) -> Texture2D:
	var image := texture(id)
	if image == null: return null
	var frame_texture := AtlasTexture.new()
	frame_texture.atlas = image
	frame_texture.region = Rect2(column * 48, row * 64, 48, 64)
	return frame_texture
