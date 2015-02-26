--[[*************************************************
    这是 忧郁の月兔 制作的【英雄无敌Ⅵ-亚山之殇-资料片】
]]--*************************************************

--[[
    创建拓展包“亚山之殇-血洗模式”
]]--
Ashan4 = sgs.Package("Ashan4", sgs.Package_GeneralPack)

sgs.LoadTranslationTable{
    ["Ashan4"] = "血洗模式",
}

--[[************
    血洗模式简述
]]--************
--[[
	国战的基本规则大致无变化
	规则1：血洗模式仅在开场时不存在君主时生效。
	规则2：当一名角色杀死了与其相同势力的其他角色时，该角色成为野心家。
	规则3：当一名角色死亡后，若存在杀手且杀手有势力：该角色所在势力的其他角色依次死亡（天灾）；若杀手不为野心家，杀手所在势力的角色依次依次回复1点体力否则摸一张牌；若杀手为野心家，其回复体力至上限并将手牌补至体力上限。
	规则4：当一名角色杀死一名其他角色后，直到其准备阶段结束，其与其他角色的距离+1，其他角色与其的距离-1。
]]--


--建立血洗模式效果
Mxuexi_mode = sgs.General(Ashan4, "Mxuexi_mode", "god", 0, true, true)

Mxuexi1 = sgs.CreateDistanceSkill{
	name = "Mxuexi1",
	correct_func = function(self, from, to)
		if from:objectName() ~= to:objectName() then
			if to:getMark("@xuexi") > 0 then
				local x = to:getMark("@xuexi")
				return -x
			end
			if from:getMark("@xuexi") > 0 then
				local x = from:getMark("@xuexi")
				return x
			end
		end
	end,
}

Mxuexi_mode:addSkill(Mxuexi1)

--翻译表
sgs.LoadTranslationTable{
	["Mxuexi_mode"] = "血洗模式",
	["&Mxuexi_mode"] = "血洗模式",
	["#Mxuexi_mode"] = "民间国战",
	["cv:Mxuexi_mode"] = "无",
	["illustrator:Mxuexi_mode"] = "无",
	["designer:Mxuexi_mode"] = "月兔君",
	["Mxuexi1"] = "血洗模式",
	[":Mxuexi1"] = "国战的基本规则大致无变化\n\n规则1：血洗模式仅在开场时不存在君主时生效。\n\n规则2：当一名角色杀死了与其相同势力的其他角色时，该角色成为野心家。\n\n规则3：当一名角色死亡后，若存在杀手且杀手有势力：该角色所在势力的其他角色依次死亡（天灾）；若杀手不为野心家，杀手所在势力的角色依次依次回复1点体力否则摸一张牌；若杀手为野心家，其回复体力至上限并将手牌补至体力上限。\n\n规则4：当一名角色杀死一名其他角色后，直到其准备阶段结束，其与其他角色的距离+1，其他角色与其的距离-1。",
}

return {Ashan4}