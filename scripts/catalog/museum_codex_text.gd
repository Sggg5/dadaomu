class_name MuseumCodexText
extends RefCounted
## Plain text only: no BBCode evaluation, economic queries, or state mutation.
static func known(value: Variant) -> String:
	if value == null or str(value).is_empty(): return "未知 / 来源未提供"
	if value is Array:
		if value.is_empty(): return "未知 / 来源未提供"
		return "; ".join(value.map(func(v: Variant) -> String: return known(v)))
	return str(value)

static func owned(state: MuseumState, item: OwnedAntique) -> String:
	var definition := MuseumState.POOL.find_by_id(item.definition_id)
	var text := "%s\n玩家实际馆藏 · 实例 %s\n定义 %s · 第%d天入藏\n" % [definition.display_name,item.instance_id,item.definition_id,item.acquired_day]
	text += "已鉴定 · 品相%d\n" % item.condition if item.identified else "待正式鉴定 · 品相及经济结果隐藏\n"
	text += "位置：%s\n\n%s\n\n游戏原创藏品；不等于任何真实博物馆对象。" % ["库房" if state.case_for(item.instance_id) == &"" else str(state.case_for(item.instance_id)),definition.description]
	if definition.content_review_status==&"PLAYTEST_PENDING_HISTORICAL_REVIEW":
		text+="\n\n试玩待史学审核 · %s\n%s\n参考链接（仅类型/时期，不是本实物出处）：\n%s"%[definition.culture_period,definition.historical_reference_note,"\n".join(definition.reference_urls)]
	return text

static func research(catalog: MuseumResearchCatalog, row: Dictionary) -> String:
	var title: String = row.original_name if row.get("recommended_zh_name") == null else row.recommended_zh_name
	var text := "%s\n官方原文：%s\n研究记录：%s\n\n研究参考 · 不代表玩家拥有或1933年已发现\n" % [title,row.original_name,row.object_id]
	for pair in [["类型","category"],["文明","culture"],["时期","historical_period"],["来源年代","date_label"],["地质年代","geological_period"],["材质","material"],["收藏机构","museum_name"],["馆藏编号","accession_number"],["资料状态","verification_status"]]:
		text += "%s：%s\n" % [pair[0],known(row.get(pair[1]))]
	var article := catalog.article(str(row.get("article_id", "")))
	if not article.is_empty(): text += "\n中文图鉴 · %s · v%d\n推荐译名待审；AI草稿未经专家审核\n%s\n" % [article.review_status,article.editor_version,article.body]
	else: text += "\n暂无中文图鉴。官方摘要：\n%s\n" % known(row.get("description"))
	var natural: Variant = row.get("natural_history")
	if natural is Dictionary:
		text += "\n自然史学术审核：%s\n" % natural.academic_review
		for key: String in natural.fields:
			var values: Array = natural.fields[key]
			text += "%s：%s\n" % [key,known(values.map(func(v: Dictionary) -> Variant: return v.get("value")))]
		text += "待核实：%s\n" % known(natural.issues)
	text += "\n原始资料来源（可复制链接）：\n%s\n元数据许可：%s\n" % [known(row.source_urls),known(row.get("source_licenses"))]
	return text
