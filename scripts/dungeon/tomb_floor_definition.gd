class_name TombFloorDefinition
extends Resource
## 单层编排数据。最终层由Tomb数组位置决定，不保存第二份final标记。
enum TerminalMode { COMBAT, BOSS }
@export var display_name: String
@export var dungeon_config: DungeonConfig
@export var terminal_mode: TerminalMode = TerminalMode.COMBAT
@export var boss_pool: BossPoolDefinition
@export_range(0, 80) var rest_amount: int = 0
@export_range(0, 3) var combat_cache_count: int = 1
@export var antique_reward_profile: AntiqueRewardProfile
@export var geometry_pool:RoomGeometryPool
@export var boss_arena_pool:BossArenaPool

func validation_error() -> String:
	if geometry_pool!=null and not geometry_pool.validation_error().is_empty():return "Invalid geometry pool"
	if boss_arena_pool!=null and not boss_arena_pool.validation_error().is_empty():return "Invalid arena pool"
	if geometry_pool!=null and terminal_mode==TerminalMode.BOSS and boss_arena_pool==null:return "Production Boss floor requires separate Arena pool"
	if display_name.is_empty(): return "Floor name required"
	if dungeon_config == null or not dungeon_config.validation_error().is_empty(): return "Invalid floor config"
	if terminal_mode not in [TerminalMode.COMBAT, TerminalMode.BOSS]: return "Invalid terminal mode"
	if (terminal_mode == TerminalMode.BOSS) != (boss_pool != null): return "Boss mode requires a pool"
	if boss_pool != null and not boss_pool.validation_error().is_empty(): return "Invalid Boss pool"
	if combat_cache_count < 0 or combat_cache_count > 3: return "Invalid combat cache budget"
	if rest_amount < 0 or rest_amount > 80: return "Invalid rest amount"
	if antique_reward_profile != null and not antique_reward_profile.validation_error().is_empty(): return "Invalid antique profile"
	return ""
