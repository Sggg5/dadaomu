# 现有资源审计与计划

基线角色、敌人、Boss、普通房间与博物馆主体均以CanvasItem即时几何绘制。已有地区地图SVG与研究目录JPG属于独立资料用途，不作为本次原创角色素材。研究媒体授权不因本阶段改变。

| 系统 | 原入口 | 新素材目标 | 保护边界 |
|---|---|---|---|
| 玩家 | scripts/player/player.gd | 四方向48×64动作 | Circle16、HP80、360度瞄准 |
| 尸蟞/枪手 | scripts/enemies/enemy.gd | 两行六动作 | 前摇/HP/速度/伤害 |
| Room | scripts/rooms/room.gd | 石板、旧木、分层障碍与灯 | Rect与Door、Physics layer1 |
| 博物馆 | scripts/museum/museum.gd | 木地面、展柜、家具 | 展位归属/经营/Profile10 |
| 古董 | DisplayArtifactGlyph/AntiquePedestal | 原8件独立图标 | ID、数值、42件回退 |
| Boss/危险区 | bosses、combat | 保留明确旧视觉 | 状态机/伤害/死亡结算 |

审计检查：Player、Enemy、Room、RegionalRoomDecor、Museum、MuseumPlayer、MuseumVisitor、DisplayCase、AntiquePedestal与即时图标。Boss和危险区的专属完整动画仍需要逐件制作，不用普通敌人放大冒充。
