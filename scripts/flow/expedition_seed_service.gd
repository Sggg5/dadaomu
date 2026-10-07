class_name ExpeditionSeedService
extends RefCounted
## 正式下墓的纯派生函数；不读存档/时钟，不创建地图，不消耗随机流。
const MAX_SEED: int = 2147483647
const DEFAULT_SITE_ID: StringName = &"DEFAULT_TOMB"
const VERSION: int = 1

static func derive(campaign_seed: int, day_number: int, site_id: StringName = DEFAULT_SITE_ID) -> int:
	assert(campaign_seed >= 1 and campaign_seed <= MAX_SEED and day_number >= 1 and site_id != &"")
	return 1 + AntiquePool.stable_score(campaign_seed, day_number, site_id, &"EXPEDITION", VERSION)
