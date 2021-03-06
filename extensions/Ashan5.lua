--[[*************************************************
    这是 忧郁の月兔 制作的【英雄无敌Ⅵ-亚山之殇-资料片】
]]--*************************************************

--[[
    创建拓展包“亚山之殇-争锋模式”
]]--
Ashan5 = sgs.Package("Ashan5", sgs.Package_GeneralPack)

sgs.LoadTranslationTable{
    ["Ashan5"] = "争锋模式",
}

--[[************
    争锋模式简述
]]--************
--[[
	国战的基本规则大致无变化
	规则1：争锋模式仅在开场时存在君主的势力不小于两个时生效。
	规则2：游戏开始时，展示每个势力的第一名君主，称为领主（第二名君主将成为野心家）。领主的体力上限+1并摸一张牌。领主的摸牌阶段额外摸一张牌。
	规则3：领主展示结束后，不存在领主的势力需要选择并成为一个存在领主的势力或选择成为野心家。
	规则4：当领主杀死其势力的其他角色时，该角色成为野心家。当一名角色杀死其领主时，该角色成为野心家。当一名野心家杀死一名领主时，该野心家成为该势力的领主，原领主成为野心家。
	规则5：当一名角色死亡后，其势力的领主失去1点体力并弃置一张牌。
	规则6：当一名领主死亡后，该势力所有角色依次死亡（天灾），未亮将的该势力角色成为野心家；若杀手有势力，杀手所在势力的角色依次回复1点体力否则摸一张牌。
]]--

--建立争锋模式效果
Mzhengfeng_mode = sgs.General(Ashan5, "Mzhengfeng_mode", "god", 0, true, true)

Mzhengfeng1 = sgs.CreateTriggerSkill{
	name = "Mzhengfeng1",
}

Mzhengfeng_mode:addSkill(Mzhengfeng1)

--翻译表
sgs.LoadTranslationTable{
	["Mzhengfeng_mode"] = "争锋模式",
	["&Mzhengfeng_mode"] = "争锋模式",
	["#Mzhengfeng_mode"] = "民间国战",
	["cv:Mzhengfeng_mode"] = "无",
	["illustrator:Mzhengfeng_mode"] = "无",
	["designer:Mzhengfeng_mode"] = "月兔君",
	["Mzhengfeng1"] = "争锋模式",
	[":Mzhengfeng1"] = "国战的基本规则大致无变化\n\n规则1：争锋模式仅在开场时存在君主的势力不小于两个时生效。\n\n规则2：游戏开始时，展示每个势力的第一名君主，称为领主（第二名君主将成为野心家）。领主的体力上限+1并摸一张牌。领主的摸牌阶段额外摸一张牌。\n\n规则3：领主展示结束后，不存在领主的势力需要选择并成为一个存在领主的势力或选择成为野心家。\n\n规则4：当领主杀死其势力的其他角色时，该角色成为野心家。当一名角色杀死其领主时，该角色成为野心家。当一名野心家杀死一名领主时，该野心家成为该势力的领主，原领主成为野心家。\n\n规则5：当一名角色死亡后，其势力的领主失去1点体力并弃置一张牌。\n\n规则6：当一名领主死亡后，该势力所有角色依次死亡（天灾），未亮将的该势力角色成为野心家；若杀手有势力，杀手所在势力的角色依次回复1点体力否则摸一张牌。",
}

return {Ashan5}