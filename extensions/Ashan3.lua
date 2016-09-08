--[[********************************************
    这是 忧郁の月兔 制作的【英雄无敌Ⅵ-亚山之殇】
]]--********************************************

--[[
    创建拓展包“亚山之殇-暗”
]]--
Ashan3 = sgs.Package("Ashan3", sgs.Package_GeneralPack)

sgs.LoadTranslationTable{
    ["Ashan3"] = "亚山之殇-暗",
}

--[[[******************
    创建架空势力【暗】
]]--[******************
sgs.addNewKingdom("an", "#388E8E")
--[[
do
    require  "lua.config" 
	local config = config
	local kingdoms = config.kingdoms
            table.insert(kingdoms,"an")
	config.color_de = "#696969"
end
]]
sgs.LoadTranslationTable{
	["an"] = "暗",
}

--[[******************
    建立一些通用内容
]]--******************
--建立空卡
MemptyCard = sgs.CreateSkillCard{
	name = "MemptyCard",
}
--建立table-qlist函数
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for _, x in ipairs(theTable) do
		result:append(x)
	end
	return result
end
--建立获取服务器玩家函数
function getServerPlayer(room, name)
	for _, p in sgs.qlist(room:getAlivePlayers()) do
		if p:objectName() == name then return p end
	end
	return nil
end

--[[******************
    创建种族【墓园】
]]--******************

--[[
   创建武将【骷髅矛手】
]]--
Mskeleton = sgs.General(Ashan3, "Mskeleton", "an", 3)
--[[
【尖矛】当你使用【杀】对目标角色造成一次伤害后，你可以弃置其装备区一张牌。
【腐骨】锁定技，当你被其他角色指定为普通【杀】的目标后，若其与你的距离大于1，则该【杀】对你无效。
【蛛网】限定技，弃牌阶段结束时，若你已受伤，你可以弃置一张武器牌，然后使你距离1内一名已受伤角色与其他角色的距离+1。
]]--
Mjianmao = sgs.CreateTriggerSkill{
	name = "Mjianmao",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		local damage = data:toDamage()
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if damage.to:hasEquip() then
				if damage.card and damage.card:isKindOf("Slash") and not (damage.chain or damage.transfer) then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local damage = data:toDamage()
		local id = room:askForCardChosen(player, damage.to , "e", self:objectName())
		room:throwCard(id, damage.to, player)
	end,
}
Mfugu = sgs.CreateTriggerSkill{
	name = "Mfugu", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.TargetConfirmed},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local use = data:toCardUse()
			if use.card and use.from and use.card:isKindOf("Slash") and use.from:distanceTo(player) > 1 and not use.card:isKindOf("NatureSlash") and use.to:contains(player) then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		room:setPlayerFlag(player, "Mfugu_avoid")
	end,
}

Mfugu_avoid = sgs.CreateTriggerSkill{
	name = "#Mfugu_avoid",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.SlashEffected},
	can_trigger = function(self, event, room, player, data)
		local effect = data:toSlashEffect()
		if player and player:isAlive() and player:hasSkill("Mfugu") and player:hasFlag("Mfugu_avoid") then
			if effect.from and effect.from:distanceTo(player) > 1 and effect.slash:objectName() == "slash" then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		room:setPlayerFlag(player, "-Mfugu_avoid")
		room:notifySkillInvoked(player, self:objectName())
		return true
	end,
	on_effect = function(self,event,room,player,data)
		local effect = data:toSlashEffect()
		local log = sgs.LogMessage()
			log.type = "#DanlaoAvoid"
            log.from = effect.to
            log.arg2 = self:objectName()
            log.arg = effect.slash:objectName()
        room:sendLog(log)
		return true
	end,
}
Mzhuwang = sgs.CreateTriggerSkill{
	name = "Mzhuwang",
	frequency = sgs.Skill_Limited,
	limit_mark = "@zhuwang_use",
	events = {sgs.EventPhaseEnd},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Discard and player:isWounded() and player:getMark("@zhuwang_use") == 1 then
				local weapon
				for _, card in sgs.qlist(player:getCards("he")) do
					if card:isKindOf("Weapon") then
						weapon = card
						break
					end
				end
				local targets = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:isWounded() and player:distanceTo(p) == 1 then
						targets:append(p)
					end
				end
				if weapon and not targets:isEmpty() then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if room:askForCard(player, ".Weapon", "@zhuwang_invoke", data, sgs.Card_MethodDiscard) then
			room:setPlayerMark(player, "@zhuwang_use", 0)
			room:broadcastSkillInvoke(self:objectName())
			room:doSuperLightbox("Mskeleton", self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:isWounded() and player:distanceTo(p) == 1 then
				targets:append(p)
			end
		end
		if targets:isEmpty() then return false end
		local target = room:askForPlayerChosen(player, targets, self:objectName())
		room:setPlayerMark(target, "@zhuwang", 1)
		local log = sgs.LogMessage()
			log.type = "#zhuwang"
			log.from = target
		room:sendLog(log)
	end,
}
Mzhuwang_far = sgs.CreateDistanceSkill{
	name = "#Mzhuwang_far",
	correct_func = function(self, from, to)
		if from:getMark("@zhuwang") == 1 then
			return 1
		end
	end,
}
--加入技能“尖矛”“腐骨”“蛛网”
Mskeleton:addSkill(Mjianmao)
Mskeleton:addSkill(Mfugu)
Mskeleton:addSkill(Mfugu_avoid)
Mskeleton:addSkill(Mzhuwang)
Mskeleton:addSkill(Mzhuwang_far)
Ashan3:insertRelatedSkills("Mfugu", "#Mfugu_avoid")
Ashan3:insertRelatedSkills("Mzhuwang", "#Mzhuwang_far")
--翻译表
sgs.LoadTranslationTable{
	["Mskeleton"] = "骷髅矛手",
	["&Mskeleton"] = "骷髅矛手",
	["#Mskeleton"] = "不死仆从",
	["Mjianmao"] = "尖矛",
	["$Mjianmao"] = "你的命是我的了！",
	[":Mjianmao"] = "当你使用【杀】对目标角色造成一次伤害后，你可以弃置其装备区一张牌。",
	["Mfugu"] = "腐骨",
	["#Mfugu_avoid"] = "腐骨",
	[":Mfugu"] = "锁定技，当你被其他角色指定为普通【杀】的目标后，若其与你的距离大于1，则该【杀】对你无效。",
	["$Mfugu"] = "喇……没射中！",
	["#fugu"] = "%from 空洞的骨架使攻击落空！",
	["Mzhuwang"] = "蛛网",
	["#Mzhuwang_far"] = "蛛网",
	["$Mzhuwang"] = "血肉都是皮囊！",
	["#zhuwang"] = "%from 与其他角色的距离永久+1！",
	["@zhuwang_use"] = "蛛网使用",
	["@zhuwang"] = "蛛网",
	[":Mzhuwang"] = "限定技，弃牌阶段结束时，若你已受伤，你可以弃置一张武器牌，然后使你距离1内一名已受伤角色与其他角色的距离+1。",
	["@zhuwang_invoke"] = "是否弃置一张武器牌发动技能“蛛网”？",
	["~Mskeleton"] = "这就是死亡吗？希望它不是……",
	["cv:Mskeleton"] = "骷髅射手",
	["illustrator:Mskeleton"] = "英雄无敌6",
	["designer:Mskeleton"] = "月兔君",
}

--[[
   创建武将【噬尸鬼】
]]--
Mghoul = sgs.General(Ashan3, "Mghoul", "an", 5)
--[[
【贪婪】锁定技，出牌阶段，你使用【杀】时无距离限制，你可以额外使用一张【杀】。
【憎恶】锁定技，当你使用的【杀】被目标角色的【闪】抵消时，若其有手牌，你失去1点体力然后弃置其一张手牌。
]]--
Mtanlan = sgs.CreateTargetModSkill{
    name = "Mtanlan",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:hasShownSkill(self) then
			return 1
		end
	end,
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play and player:hasShownSkill(self) then
			return 1000
		end
	end,
}
Mzengwu = sgs.CreateTriggerSkill{
    name = "Mzengwu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.SlashMissed},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local effect = data:toSlashEffect()
			if not effect.to:isKongcheng() then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local effect = data:toSlashEffect()
		room:loseHp(player)
		room:getThread():delay(500)
		local card = room:askForCardChosen(player, effect.to, "h", self:objectName())
		room:throwCard(card, effect.to, player)
	end,
}
--加入技能“贪婪”、“憎恶”
Mghoul:addSkill(Mtanlan)
Mghoul:addSkill(Mzengwu)
--翻译表
sgs.LoadTranslationTable{
    ["Mghoul"] = "噬尸鬼",
	["&Mghoul"] = "噬尸鬼",
	["#Mghoul"] = "死者之恨",
	["Mtanlan"] = "贪婪",
	["$Mtanlan"] = "什么东西在你身体里？",
	[":Mtanlan"] = "锁定技，出牌阶段，你使用【杀】时无距离限制，你可以额外使用一张【杀】。",
	["Mzengwu"] = "憎恶",
	["$Mzengwu"] = "狂暴湮没了我们！",
	[":Mzengwu"] = "锁定技，当你使用的【杀】被目标角色的【闪】抵消时，若其有手牌，你失去1点体力然后弃置其一张手牌。",
	["~Mghoul"] = "我的骨头散了架……",
	["cv:Mghoul"] = "噬魂鬼",
	["illustrator:Mghoul"] = "英雄无敌6",
	["designer:Mghoul"] = "月兔君",
}

--[[
   创建武将【怨魂】
]]--
Mspectre = sgs.General(Ashan3, "Mspectre", "an", 3, false)
--[[
*【哀嚎】摸牌阶段，你可以放弃摸牌，改为选择一种花色并展示牌堆顶五张牌，然后将与所选择花色相同的牌置于弃牌堆并获得其余的牌；若以此法获得五张牌，将你武将牌叠置。
*【印记】副将技，锁定技，若你的武将牌为叠置，你跳过弃牌阶段。
*【无形】主将技，若你的手牌数不大于当前回合角色，则【南蛮入侵】和【万箭齐发】对你无效。
]]--
Maihao = sgs.CreateTriggerSkill{
    name = "Maihao",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.EventPhaseStart},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Draw then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local suit = room:askForSuit(player, self:objectName())
		local log = sgs.LogMessage()
	        log.type = "#aihao"
			log.from = player
			log.arg = sgs.Card_Suit2String(suit)
		room:sendLog(log)
        local idlist = room:getNCards(5)
        for _,ids in sgs.qlist(idlist) do
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SHOW, player:objectName(),"", self:objectName(), "")
            room:moveCardTo(sgs.Sanguosha:getCard(ids), nil, nil, sgs.Player_PlaceTable, reason, true)
        end
        room:getThread():delay(2000)
		local emptycard = MemptyCard:clone()
        for _,id in sgs.qlist(idlist) do
            if sgs.Sanguosha:getCard(id):getSuit() ~= suit then
                emptycard:addSubcard(sgs.Sanguosha:getCard(id))
            end
        end
		player:obtainCard(emptycard, true)
        if emptycard:subcardsLength() == 4 then
            room:broadcastSkillInvoke(self:objectName(), 2)
		elseif emptycard:subcardsLength() == 5 then
            room:broadcastSkillInvoke(self:objectName(), 3)
			if player:faceUp() then
				player:turnOver()
			end
        end
		return true
	end,
}
Myinji = sgs.CreateTriggerSkill{
	name = "Myinji",
	events = {sgs.EventPhaseChanging},
	frequency = sgs.Skill_Compulsory,
	relate_to_place = "deputy",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local change = data:toPhaseChange() 
			if change.to == sgs.Player_Discard and not player:isSkipped(sgs.Player_Discard) and not player:faceUp() then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or player:askForSkillInvoke(self:objectName(), data) then
			if player:getHandcardNum() > player:getMaxCards() then
				room:broadcastSkillInvoke(self:objectName())
				room:notifySkillInvoked(player, self:objectName())
			end
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		player:skip(sgs.Player_Discard)
	end,
}
Mwuxing = sgs.CreateTriggerSkill{
	name = "Mwuxing",
	events = {sgs.TargetConfirmed},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local use = data:toCardUse()
			if use.card and (use.card:isKindOf("SavageAssault") or use.card:isKindOf("ArcheryAttack")) and use.to:contains(player) then
				local current = room:getCurrent()
				if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
					if player:getHandcardNum() <= current:getHandcardNum() then
						return self:objectName()
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self) or player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		room:setPlayerFlag(player, "wuxing_avoid")
	end,
}
Mwuxing_avoid = sgs.CreateTriggerSkill{
	name = "#Mwuxing_avoid",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardEffected},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill("Mwuxing") and player:hasFlag("wuxing_avoid") then
			local effect = data:toCardEffect()
			if effect.card and effect.card:isNDTrick() and (effect.card:isKindOf("SavageAssault") or effect.card:isKindOf("ArcheryAttack")) then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		room:setPlayerFlag(player, "-wuxing_avoid")
		room:notifySkillInvoked(player, self:objectName())
		return true
	end,
	on_effect = function(self, event, room, player, data)
		local effect = data:toCardEffect()
		local log = sgs.LogMessage()
			if effect.from then
				log.type = "$CancelTarget"
				log.from = effect.from
			else
				log.type = "$CancelTargetNoUser"
			end
			log.to:append(player)
			log.arg = effect.card:objectName()
		room:sendLog(log)
		return true
	end,
}
--加入技能“哀嚎”、“印记”、“无形”
Mspectre:addSkill(Maihao)
Mspectre:addSkill(Myinji)
Mspectre:addSkill(Mwuxing)
Mspectre:addSkill(Mwuxing_avoid)
Ashan3:insertRelatedSkills("Mwuxing", "#Mwuxing_avoid")
--翻译表
sgs.LoadTranslationTable{
    ["Mspectre"] = "怨魂",
	["&Mspectre"] = "怨魂",
	["#Mspectre"] = "无尽苦痛",
	["Maihao"] = "哀嚎",
	["$Maihao1"] = "当心点~",
	["$Maihao2"] = "看看都给我带来些什么~",
	["$Maihao3"] = "回到我身边！回到我身边吧！",
	["#aihao"] = "%from 选择了 %arg 花色！",
	[":Maihao"] = "摸牌阶段，你可以放弃摸牌，改为选择一种花色并展示牌堆顶五张牌，然后将与所选择花色相同的牌置于弃牌堆并获得其余的牌；若以此法获得五张牌，将你武将牌叠置。",
	["Myinji"] = "印记",
	["$Myinji"] = "多漂亮的死亡啊~",
	[":Myinji"] = "副将技，锁定技，若你的武将牌已叠置，你跳过弃牌阶段。",
	["Mwuxing"] = "无形",
	["$wuxing"] = "无形",
	["$Mwuxing"] = "有些东西不是所有人都能看得见~",
	["#Mwuxing_avoid"] = "无形",
	[":Mwuxing"] = "主将技，若你的手牌数不大于当前回合角色，则【南蛮入侵】和【万箭齐发】对你无效。",
	["~Mspectre"] = "生命抛弃了我……",
	["cv:Mspectre"] = "死亡先知",
	["illustrator:Mspectre"] = "英雄无敌6",
	["designer:Mspectre"] = "月兔君",
}

--[[
   创建武将【大尸巫】
]]--
Marchlich = sgs.General(Ashan3, "Marchlich", "an", 3)
--珠联璧合：怨魂
Marchlich:addCompanion("Mspectre")
--[[
*【魂拥】出牌阶段开始时，若你的手牌数不大于X，你可以弃置所有手牌然后摸X张牌（X为你的体力上限）。
*【汲取】弃牌阶段开始时，若你的手牌数小于体力，你可以选择一项：1.令距离1内的一名其他角色正面朝上交给你一张手牌；2.弃置攻击范围内一名与你不同势力的角色一张牌。
*【死亡】主将技，限定技，当其他势力角色进入濒死时，若伤害来源与你相同势力，你可以弃置一张黑桃手牌进行一次判定：若结果为黑色，该角色死亡。
]]--
Mhunyong = sgs.CreateTriggerSkill{
    name = "Mhunyong",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.EventPhaseStart},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Play then
				if player:getHandcardNum() <= player:getMaxHp() then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			if player:getHandcardNum() < player:getMaxHp() then
				room:broadcastSkillInvoke(self:objectName(), 1)
			else
				room:broadcastSkillInvoke(self:objectName(), 2)
			end
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		player:throwAllHandCards()
	    player:drawCards(player:getMaxHp())
	end,
}
Mjiqu = sgs.CreateTriggerSkill{
    name = "Mjiqu",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.EventPhaseStart},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Discard and player:getHandcardNum() < player:getHp() then
				local targets1 = sgs.SPlayerList()
				local targets2 = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if not p:isKongcheng() and player:distanceTo(p) == 1 then
					    targets1:append(p)
					end
					if p:hasShownOneGeneral() and player:inMyAttackRange(p) and not p:isNude() and not (player:isFriendWith(p) or player:willBeFriendWith(p)) then
						targets2:append(p)
					end
				end
				if not (targets1:isEmpty() and targets2:isEmpty()) then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local targets1 = sgs.SPlayerList()
		local targets2 = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if not p:isKongcheng() and player:distanceTo(p) == 1 then
				targets1:append(p)
			end
			if p:hasShownOneGeneral() and player:inMyAttackRange(p) and not p:isNude() and not (player:isFriendWith(p) or player:willBeFriendWith(p)) then
				targets2:append(p)
			end
		end
		if not targets1:isEmpty() then
			if not targets2:isEmpty() then
				choice = room:askForChoice(player, self:objectName(), "jiqu_get+jiqu_drop", data)
			else
				choice = "jiqu_get"
			end
		else
			choice = "jiqu_drop"
		end
		if choice == "jiqu_get" then
			room:broadcastSkillInvoke(self:objectName(), 1)
			local target = room:askForPlayerChosen(player, targets1, self:objectName())
			local id = room:askForExchange(target, self:objectName(), 1, 1, "jiqu_give", "", ".|.|.|hand"):getSubcards():first()
			room:obtainCard(player, id, true)
		else
			room:broadcastSkillInvoke(self:objectName(), 2)
			local target = room:askForPlayerChosen(player, targets2, self:objectName())
			id = room:askForCardChosen(player, target, "he", self:objectName())
			room:throwCard(id, target, player)
		end
	end,
}
Msiwang = sgs.CreateTriggerSkill{
	name = "Msiwang",
	frequency = sgs.Skill_Limited,
	limit_mark = "@siwang_use",
	events = {sgs.Dying},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		local lich =  room:findPlayerBySkillName(self:objectName())
		if lich and lich:isAlive() then
			local dying = data:toDying()
			local damage = dying.damage
			if not dying.who:hasShownOneGeneral() then return "" end
			if damage and damage.from and not (lich:isFriendWith(dying.who) or lich:willBeFriendWith(dying.who)) and (lich:isFriendWith(damage.from) or lich:willBeFriendWith(damage.from)) and player:getMark("@siwang_use") == 1 then
				local spade
			    for _, card in sgs.qlist(player:getCards("h")) do
				    if card:getSuit() == sgs.Card_Spade then
					    spade = card
					    break
					end
				end
			    if spade then
					return self:objectName(), lich
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		local lich =  room:findPlayerBySkillName(self:objectName())
		if room:askForCard(lich, ".|spade|.|hand", "@siwang_invoke", data, sgs.Card_MethodDiscard) then
			room:setPlayerMark(lich, "@siwang_use", 0)
			room:broadcastSkillInvoke(self:objectName(), 1)
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local dying = data:toDying()
		local lich =  room:findPlayerBySkillName(self:objectName())
		local judge = sgs.JudgeStruct()
			judge.pattern = ".|black|."
			judge.who = lich
			judge.good = true
			judge.reason = self:objectName()
			judge.play_animation = true
			judge.negative = false
		room:judge(judge)
		if judge:isGood() then
			room:broadcastSkillInvoke(self:objectName(), 2)
			room:doSuperLightbox("Marchlich", self:objectName())
			room:setEmotion(dying.who, "bad")
			room:killPlayer(dying.who, dying.damage)
		else
			room:broadcastSkillInvoke(self:objectName(), 3)
			local log = sgs.LogMessage()
				log.type = "#siwang"
				log.from = dying.who
			room:sendLog(log)
			room:setEmotion(dying.who, "good")
		end
		return false
	end,
}				
--加入技能“魂拥”、“汲取”、“死亡”
Marchlich:addSkill(Mhunyong)
Marchlich:addSkill(Mjiqu)
Marchlich:addSkill(Msiwang)				
--翻译表
sgs.LoadTranslationTable{
    ["Marchlich"] = "大尸巫",
	["&Marchlich"] = "大尸巫",
	["#Marchlich"] = "亡灵大师",
	["Mhunyong"] = "魂拥",
	["$Mhunyong1"] = "腐烂的气味，又来了。",
	["$Mhunyong2"] = "（呼气）把他吸入！",
	[":Mhunyong"] = "出牌阶段开始时，若你的手牌数不大于X，你可以弃置所有手牌然后摸X张牌（X为你的体力上限）。",
	["Mjiqu"] = "汲取",
	["$Mjiqu1"] = "腐烂的味道，是甜的。",
	["$Mjiqu2"] = "你将枯萎于此！",
	["jiqu_get"] = "活力汲取",
	["jiqu_drop"] = "虚弱诅咒",
	["jiqu_give"] = "请正面朝上交给对方一张手牌。",
	[":Mjiqu"] = "弃牌阶段开始时，若你的手牌数小于体力，你可以选择一项：1.令距离1内的一名其他角色正面朝上交给你一张手牌；2.弃置攻击范围内一名与你不同势力的角色一张牌。",
	["Msiwang"] = "死亡",
	["@siwang_used"] = "死亡免疫",
	["$Msiwang1"] = "收割生命！",
	["$Msiwang2"] = "击倒！",
	["$Msiwang3"] = "魔法不足！",
	["#siwang"] = "%from 免疫于死亡诅咒！",
	["@siwang_invoke"] = " 是否弃置一张黑桃手牌发动技能“死亡”？",
	[":Msiwang"] = "主将技，限定技，当其他势力角色进入濒死时，若伤害来源与你相同势力，你可以弃置一张黑桃手牌进行一次判定：若结果为黑色，该角色死亡。",
	["~Marchlich"] = "一场狂热的梦……",
	["cv:Marchlich"] = "死灵法师",
	["illustrator:Marchlich"] = "英雄无敌6",
	["designer:Marchlich"] = "月兔君",
}

--[[
   创建武将【腐毒拉玛苏】
]]--
Mlamasu = sgs.General(Ashan3, "Mlamasu", "an", 4, false)
--珠联璧合：噬尸鬼、吸血伯爵
Mlamasu:addCompanion("Mghoul")
Mlamasu:addCompanion("Mvampire")
--[[
*【虫息】锁定技，当你对攻击范围内其他角色造成一次伤害后，其获得1枚“虫”标记（最多2枚）。锁定技，拥有“虫”标记的角色若已受伤，其手牌上限-X（X为“虫”标记数目），其回复体力后进行一次判定，若为红色，移除1枚“虫”标记然后你摸一张牌。
*【瘟疫】主将技，限定技，当你处于濒死状态时，你可以令拥有“虫”标记的角色依次失去X点体力并移除所有“虫”标记（X为“虫”标记数目），然后你回复体力至Y（Y为受到此技能影响的角色数目）。
]]--
Mchongxi = sgs.CreateTriggerSkill{
	name = "Mchongxi",
	frequency =sgs.Skill_Compulsory,
	events = {sgs.Damage},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if player:objectName() ~= damage.to:objectName() and damage.to:isAlive() and player:inMyAttackRange(damage.to) then
				if damage.to:getMark("chong") > 1 then return "" end
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local damage = data:toDamage()
		damage.to:gainMark("@chong", 1)
		local log = sgs.LogMessage()
			log.type = "#chongxi1"
			log.from = damage.to
		room:sendLog(log)
	end,
}
Mchongxi_recover = sgs.CreateTriggerSkill{
	name = "#Mchongxi_recover",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.HpRecover},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:getMark("@chong") > 0 then
			local judge = sgs.JudgeStruct()
				judge.pattern = ".|red|."
				judge.who = player
				judge.good = true
				judge.reason = self:objectName()
				judge.play_animation = true
				judge.negative = false
			room:judge(judge)
			if judge:isGood() then
				room:broadcastSkillInvoke(self:objectName(), 2)
				player:loseMark("@chong", 1)
				room:notifySkillInvoked(player, self:objectName())
				local log = sgs.LogMessage()
					log.type = "#chongxi2"
					log.from = player
				room:sendLog(log)
				local lamasu =  room:findPlayerBySkillName("Mchongxi")
				if lamasu and lamasu:isAlive() then
					lamasu:drawCards(1)
				end
			end
		end
	end,
}
Mchongxi_max = sgs.CreateMaxCardsSkill{
	name = "#Mchongxi_max",
	extra_func = function(self,player)
		local x = player:getMark("@chong")
		if x > 0 and player:isWounded() then
			return -x
		end
	end,
}
Mwenyi = sgs.CreateTriggerSkill{
	name = "Mwenyi",
	limit_mark = "@wenyi_use",
	frequency = sgs.Skill_Limited,
	relate_to_place = "head",
	events = {sgs.AskForPeaches}, 
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local dying = data:toDying()
			if player:objectName() == dying.who:objectName() and player:getMark("@wenyi_use") == 1 then
				for	_,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getMark("@chong") > 0 then
						return self:objectName()
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:setPlayerMark(player, "@wenyi_use", 0)
			room:broadcastSkillInvoke(self:objectName())
			room:doSuperLightbox("Mlamasu", self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local x = 0
		for	_,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getMark("@chong") > 0 then
				x = x+1
			end
		end
		x = math.min(x, player:getMaxHp())
		if x > 0 then
			for	_,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getMark("@chong") > 0 then
					room:loseHp(p, p:getMark("@chong"))
					p:loseAllMarks("@chong")
					room:getThread():delay(500)
				end
			end
			if not player:isAlive() then return end
			x = x - player:getHp()
			local recover = sgs.RecoverStruct()
				recover.recover = x
			room:recover(player, recover)
		end
	end,
}
--加入技能“虫息”、“瘟疫”
Mlamasu:addSkill(Mchongxi)
Mlamasu:addSkill(Mchongxi_max)
Mlamasu:addSkill(Mchongxi_recover)
Mlamasu:addSkill(Mwenyi)
Ashan3:insertRelatedSkills("Mchongxi", "#Mchongxi_recover")
Ashan3:insertRelatedSkills("Mchongxi", "#Mchongxi_max")
--翻译表
sgs.LoadTranslationTable{
    ["Mlamasu"] = "腐毒拉玛苏",
	["&Mlamasu"] = "腐毒拉玛苏",
	["#Mlamasu"] = "孪生瘟疫",
	["Mchongxi"] = "虫息",
	["#Mchongxi_max"] = "虫息",
	["#Mchongxi_recover"] = "虫息",
	["$Mchongxi1"] = "用餐时间到了。",
	["$Mchongxi2"] = "失败！",
	["#chongxi1"] = "%from 的手牌上限-1！",
	["#chongxi2"] = "%from 的手牌上限+1！",
	["@chong"] = "虫",
	[":Mchongxi"] = "锁定技，当你对攻击范围内其他角色造成一次伤害后，其获得1枚“虫”标记（最多2枚）。锁定技，拥有“虫”标记的角色若已受伤，其手牌上限-X（X为“虫”标记数目），其回复体力后进行一次判定，若为红色，移除1枚“虫”标记然后你摸一张牌。",
	["Mwenyi"] = "瘟疫",
	[":Mwenyi"] = "主将技，限定技，当你处于濒死状态时，你可以令拥有“虫”标记的角色依次失去X点体力并移除所有“虫”标记（X为“虫”标记数目），然后你回复体力至Y（Y为受到此技能影响的角色数目）。",
	["$Mwenyi"] = "别死了亲爱的！（啃噬）",
	["@wenyi_use"] = "瘟疫使用",
	["~Mlamasu"] = "我的生命被终结了！",
	["cv:Mlamasu"] = "育母蜘蛛",
	["illustrator:Mlamasu"] = "英雄无敌6",
	["designer:Mlamasu"] = "月兔君",
}

--[[
   创建武将【吸血伯爵】
]]--
Mvampire = sgs.General(Ashan3, "Mvampire", "an", 4)
--[[
*【血握】当你受到一次伤害时，你可以防止此伤害并获得1枚“血”标记。锁定技，出牌阶段，当你对距离2内一名其他角色造成一次伤害后，你移除1枚“血”标记并摸一张牌。锁定技，出牌阶段结束时时，你失去X点体力并移除所有“血”标记（X为你拥有的“血”标记数目）。
*【时空】主将技，锁定技，此武将牌上单独的阴阳鱼个数-1。主将技，出牌阶段开始前，若你拥有“血”标记且装备区不为空，你可以弃置装备区所有牌并跳过出牌阶段，若如此做，移除所有“血”标记，直到下次出牌阶段开始前，当你被指定为基本牌的目标时，你取消之。
]]--
Mvampire:setHeadMaxHpAdjustedValue(-1)
Mxuewo = sgs.CreateTriggerSkill{
	name = "Mxuewo",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageInflicted, sgs.Damage, sgs.EventPhaseEnd},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if event == sgs.DamageInflicted then
				return self:objectName()
			elseif event == sgs.Damage then
				local damage = data:toDamage()
				if player:distanceTo(damage.to) <= 2 and player:distanceTo(damage.to) ~= -1 and player:getPhase() == sgs.Player_Play and player:getMark("@xue") > 0 then
					return self:objectName()
				end
			else
				if player:getPhase() == sgs.Player_Play and player:getMark("@xue") > 0 then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if event == sgs.DamageInflicted then
			if player:askForSkillInvoke(self:objectName(), data) then
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 1)
				return true
			end
		elseif event == sgs.Damage then
			room:broadcastSkillInvoke(self:objectName(), 2)
			return true
		else
			room:broadcastSkillInvoke(self:objectName(), 3)
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		if event == sgs.DamageInflicted then
			local log = sgs.LogMessage()
			    log.type = "#xuewo"
		        log.from = player
		    room:sendLog(log)
			player:gainMark("@xue", 1)
			return true
		elseif event == sgs.Damage then
			if player:getMark("@xue") > 0 then
				player:loseMark("@xue", 1)
				player:drawCards(1)
			end
		else
			local x = player:getMark("@xue")
			room:loseHp(player, x)
			player:loseAllMarks("@xue")
		end
	end,
}
Mshikong = sgs.CreateTriggerSkill{
	name = "Mshikong",
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseChanging, sgs.TargetConfirming},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if event == sgs.EventPhaseChanging then
				local change = data:toPhaseChange()
				if change.to == sgs.Player_Play and not player:isSkipped(sgs.Player_Play) then
					if player:getMark("@shikong") == 1 then
						room:setPlayerMark(player, "@shikong", 0)
						local log = sgs.LogMessage()
							log.type = "#shikong2"
							log.from = player
						room:sendLog(log)
					end
					local change = data:toPhaseChange()
					if player:getMark("@xue") > 0 and player:hasEquip() then
						return self:objectName()
					end
				end
			else
				local use = data:toCardUse()
				if use.card and use.card:isKindOf("BasicCard") and use.to:contains(player) and player:getMark("@shikong") == 1 then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if event == sgs.EventPhaseChanging then
			if player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName(), 1)
				player:throwAllEquips()
				local log = sgs.LogMessage()
					log.type = "#shikong1"
					log.from = player
				room:sendLog(log)
				player:skip(sgs.Player_Play)
				return true
			end
		else
			room:broadcastSkillInvoke(self:objectName(), 2)
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		if event == sgs.EventPhaseChanging then
			player:loseAllMarks("@xue")
			room:setPlayerMark(player, "@shikong", 1)
		else
			local use = data:toCardUse()
			sgs.Room_cancelTarget(use, player)
			data:setValue(use)
			return false
		end
	end,
}
--加入技能“血握”、“时空”
Mvampire:addSkill(Mxuewo)
Mvampire:addSkill(Mshikong)
--翻译表
sgs.LoadTranslationTable{
    ["Mvampire"] = "吸血伯爵",
	["&Mvampire"] = "吸血伯爵",
	["#Mvampire"] = "返老还童",
	["Mxuewo"] = "血握",
	["$Mxuewo1"] = "浴血奋战！",
	["$Mxuewo2"] = "沐浴着你的鲜血。",
	["$Mxuewo3"] = "不！",
	["#xuewo"] = "%from 抑制住伤势！",
	["@xue"] = "血",
	[":Mxuewo"] = "当你受到一次伤害时，你可以防止此伤害并获得1枚“血”标记。锁定技，出牌阶段，当你对距离2内一名其他角色造成一次伤害后，你移除1枚“血”标记并摸一张牌。锁定技，出牌阶段结束时时，你失去X点体力并移除所有“血”标记（X为你拥有的“血”标记数目）。",
	["Mshikong"] = "时空",
	["$Mshikong1"] = "休养生息，伺机再战！",
	["$Mshikong2"] = "哈……摄点血！",
	["#shikong1"] = "%from 超脱了这个时空！",
	["#shikong2"] = "%from 回归了这个时空！",
	[":Mshikong"] = "主将技，锁定技，此武将牌上单独的阴阳鱼个数-1。主将技，出牌阶段开始前，若你拥有“血”标记且装备区不为空，你可以弃置装备区所有牌并跳过出牌阶段，若如此做，移除所有“血”标记，直到下次出牌阶段开始前，当你被指定为基本牌的目标时，你取消之。",
	["~Mvampire"] = "我的血，被你夺走了……",
	["cv:Mvampire"] = "血魔",
	["illustrator:Mvampire"] = "英雄无敌6",
	["designer:Mvampire"] = "月兔君",
}

--[[
   创建武将【织命蛛后】
]]--
Mweaver = sgs.General(Ashan3, "Mweaver", "an", 3, false)
--珠联璧合：骷髅矛手
Mweaver:addCompanion("Mskeleton")
--[[
【邪知】主将技，当你使用一张非延时锦囊时，若你有手牌，你可以进行一次判定：若结果为黑色，你获得该判定牌；若结果为红色，你弃置一张手牌然后获得该判定牌。
【命运】主将技，锁定技，当你受到一次无属性伤害时，若其不是由真实的牌引起的，你防止之。
【流逝】副将技，当你使用或打出一张【杀】时，你可以令一名攻击范围内其他角色进行一次判定：若结果为黑色，其失去1点体力；否则你对自己造成1点伤害。
【归宿】副将技，锁定技，当你造成或受到一次无属性伤害后，你摸一张牌。
*【双身】限定技，准备阶段开始时，若你没有手牌、已受伤且有另一名武将（非君主），你可以移除另一张武将牌，然后回复体力至上限并将手牌数补至体力上限。
]]--
Mxiezhi = sgs.CreateTriggerSkill{
	name = "Mxiezhi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardResponded},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local card = nil
			if event == sgs.CardUsed then
				local use = data:toCardUse()
				card = use.card
			elseif event == sgs.CardResponded then
				local response = data:toCardResponse()
				card = response.m_card
			end
			if card:isNDTrick() and not player:isKongcheng() then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local judge = sgs.JudgeStruct()
		    judge.who = player
		    judge.pattern = ".|spade,club|."
		    judge.good = true
	        judge.reason = self:objectName()
			judge.play_animation = true
			judge.negative = false
	    room:judge(judge)
	    if judge:isGood() then
			room:broadcastSkillInvoke(self:objectName(), 1)
			player:obtainCard(judge.card, true)
	    else
			room:broadcastSkillInvoke(self:objectName(), 2)
			room:askForDiscard(player, self:objectName(), 1, 1, false, false)
			player:obtainCard(judge.card, true)
        end
	end,
}
Mmingyun = sgs.CreateTriggerSkill{
	name = "Mmingyun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if damage.nature ~= sgs.DamageStruct_Normal then return "" end
			if damage.card and not damage.card:isVirtualCard() then return "" end
			return self:objectName()
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local log = sgs.LogMessage()
			log.type = "#mingyun"
			log.from = player
			log.arg = self:objectName()
		room:sendLog(log)
		return true
	end,
}
Mliushi = sgs.CreateTriggerSkill{
	name = "Mliushi", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardUsed, sgs.CardResponded},
	relate_to_place = "deputy",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if event == sgs.CardUsed then
				local use = data:toCardUse()
				if not use.card:isKindOf("Slash") then
					return ""
				end
			elseif event == sgs.CardResponded then
				local response = data:toCardResponse()
				if not response.m_card:isKindOf("Slash") then
					return ""
				end
			end	
			local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:inMyAttackRange(p) then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:inMyAttackRange(p) then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, self:objectName())
			local judge = sgs.JudgeStruct()
				judge.pattern = ".|red|."
				judge.good = true
				judge.reason = self:objectName()
				judge.who = target
				judge.play_animation = true
				judge.negative = false
			room:judge(judge)
			if judge:isGood() then
				room:broadcastSkillInvoke(self:objectName(), 2)
				local damage = sgs.DamageStruct()
					damage.damage = 1
					damage.from = player
					damage.to = player
				room:damage(damage)
			else
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:loseHp(target, 1)
			end
		end
	end,
}
Mguisu = sgs.CreateTriggerSkill{
	name = "Mguisu",
	frequency = sgs.Skill_Compulsory,
	events={sgs.Damage, sgs.Damaged},
	relate_to_place = "deputy",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if damage.nature == sgs.DamageStruct_Normal then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		player:drawCards(1)
	end,
}
Mshuangshen = sgs.CreateTriggerSkill{
	name = "Mshuangshen",
	limit_mark = "@shuangshen_use",
	frequency = sgs.Skill_Limited,
	events = {sgs.EventPhaseStart},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Start then
				if not player:isLord() and player:isKongcheng() and player:isWounded() and player:getMark("@shuangshen_use") == 1 then
					if player:getGeneralName() == "Mweaver" and not string.find(player:getGeneral2Name(), "sujiang") then
						return self:objectName()
					elseif player:getGeneral2Name() == "Mweaver" and not string.find(player:getGeneralName(), "sujiang") then
						return self:objectName()
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:setPlayerMark(player, "@shuangshen_use", 0)
			room:broadcastSkillInvoke(self:objectName())
			if player:getGeneralName() == "Mweaver" then
				room:doSuperLightbox("Mweaver", self:objectName())
			else
				room:doSuperLightbox("Mspider", self:objectName())
			end
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		if player:getGeneralName() == "Mweaver" then
			player:removeGeneral(false)
		else
			player:removeGeneral(true)
		end
		local x = player:getMaxHp() - player:getHp()
		local recover = sgs.RecoverStruct()
			recover.recover = x
			recover.who = player
		room:recover(player, recover)
		player:drawCards(player:getMaxHp() - player:getHandcardNum())
	end,
}
--加入技能“邪知、“命运”、”“流逝”、“归宿”、“双身”
Mweaver:addSkill(Mliushi)
Mweaver:addSkill(Mguisu)
Mweaver:addSkill(Mxiezhi)
Mweaver:addSkill(Mmingyun)
Mweaver:addSkill(Mshuangshen)	
--翻译表
sgs.LoadTranslationTable{
    ["Mweaver"] = "织命蛛后",
	["&Mweaver"] = "织命蛛后",
	["#Mweaver"] = "死亡投影",
	["Mxiezhi"] = "邪知",
	["$Mxiezhi1"] = "太好了！",
	["$Mxiezhi2"] = "毫无价值的存在！",
	[":Mxiezhi"] = "主将技，当你使用一张非延时锦囊时，若你有手牌，你可以进行一次判定：若结果为黑色，你获得该判定牌；若结果为红色，你弃置一张手牌然后获得该判定牌。",
	["Mmingyun"] = "命运",
	["$Mmingyun"] = "死亡无法靠近我！",
	["#mingyun"] = "由于 %arg 的效果，%from 受到的伤害无效！",
	[":Mmingyun"] = "主将技，锁定技，当你受到一次无属性伤害时，若其不是由真实的牌引起的，你防止之。",
	["Mliushi"] = "流逝",
	["$Mliushi1"] = "和我比你差的太远了！",
	["$Mliushi2"] = "什么？",
	[":Mliushi"] = "副将技，当你使用或打出一张【杀】时，你可以令一名攻击范围内其他角色进行一次判定：若结果为黑色，其失去1点体力；否则你对自己造成1点伤害。",
	["Mguisu"] = "归宿",
	["$Mguisu"] = "又回来了。",
	[":Mguisu"] = "副将技，锁定技，当你造成或受到一次无属性伤害后，你摸一张牌。",
	["Mshuangshen"] = "双身",
	["$Mshuangshen"] = "你没看到我的出现！",
	[":Mshuangshen"] = "限定技，准备阶段开始时，若你没有手牌、已受伤且有另一名武将（非君主），你可以移除另一张武将牌，然后回复体力至上限并将手牌数补至体力上限。",
	["~Mweaver"] = "你很幸运……",
	["cv:Mweaver"] = "复仇之魂",
	["illustrator:Mweaver"] = "英雄无敌6",
	["designer:Mweaver"] = "月兔君",
}
					
--[[
   创建武将【阴魂龙】
]]--
Mwraith = sgs.General(Ashan3, "Mwraith", "an", 4)
--[[
【枯萎】锁定技，其他势力的角色死亡时，若你已受伤，你回复1点体力，否则你与其余角色的距离-1。
【衰老】结束阶段开始时，你可以弃置一张基本牌令一名攻击范围内已受伤其他角色进行一次判定：若结果为红桃，其摸一张牌；否则你摸一张牌且直到你下回合开始时其手牌上限-X（X为其已损失体力值）。
*【奴役】主将技，限定技，弃牌阶段开始时，若你已受伤，你可以正面朝上交给一名其他角色三张不同类型的牌，将其视为“龙仆”并回复1点体力。锁定技，当你受到一点伤害后，“龙仆”摸一张牌然后选择一项：1.交给你两张手牌；2.其失去1点体力使你回复1点体力。
*【永暗】副将技，准备阶段开始时，若你区域内没有牌，你可以弃置场上装备区所有牌。
]]--			
Mkuwei = sgs.CreateTriggerSkill{
	name = "Mkuwei",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},				
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local death = data:toDeath()
			if death.who:hasShownOneGeneral() and death.who:objectName() ~= player:objectName() and not (player:isFriendWith(death.who) or player:willBeFriendWith(death.who)) then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local log = sgs.LogMessage()
            log.type = "#kuwei"
			log.from = player
		room:sendLog(log)
		local death = data:toDeath()
		if player:isWounded() then
			local Recover = sgs.RecoverStruct()
			    Recover.recover = 1
				Recover.who = player
			room:recover(player, Recover)
		else
			player:gainMark("@kuwei")
		end
	end,
}
Mkuwei_close = sgs.CreateDistanceSkill{
	name = "#Mkuwei_close",
	correct_func = function(self, from, to)
	    local x = from:getMark("@kuwei")
		if x > 0 then
			if from:hasSkill("Mkuwei") and from:hasShownSkill(Mkuwei) then
				return -x
			end
		end
	end,
}					
Mshuailao = sgs.CreateTriggerSkill{
	name = "Mshuailao", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Finish then
				local basic
				for _, card in sgs.qlist(player:getHandcards()) do
					if card:isKindOf("BasicCard") then
						basic = card
						break
					end
				end
				if basic then
					local targets = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:isWounded() then
							targets:append(p)
						end
					end
					if not targets:isEmpty() then
						return self:objectName()
					end
				end
			elseif player:getPhase() == sgs.Player_Start then
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					room:setPlayerMark(p, "@shuailao", 0)
				end
		    end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if room:askForCard(player, "BasicCard", "@shuailao_invoke", data, sgs.Card_MethodDiscard) then
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:isWounded() then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, self:objectName())
			local judge = sgs.JudgeStruct()
				judge.pattern = ".|heart|."
				judge.good = true
				judge.reason = self:objectName()
				judge.who = target
				judge.play_animation = true
				judge.negative = false
			room:judge(judge)
			if judge:isGood() then
				room:broadcastSkillInvoke(self:objectName(), 2)
				target:drawCards(1)
			else
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:setPlayerMark(target, "@shuailao", 1)
				local log = sgs.LogMessage()
                    log.type = "#shuailao"
					log.from = target
		        room:sendLog(log)
				player:drawCards(1)
			end
		end
	end,
}
Mshuailao_max = sgs.CreateMaxCardsSkill{
	name = "#Mshuailao_max",
	extra_func = function(self,player)
		if player:getMark("@shuailao") > 0 and player:isWounded() then
			local wraith
			for _,p in sgs.qlist(player:getAliveSiblings()) do
				if p:hasSkill("Mshuailao") and p:hasShownSkill(Mshuailao) then
					wraith = p
					break
				end
			end
			if wraith then
				local x = player:getLostHp()
				return -x
			end
		end
	end,
}				
Myongan = sgs.CreateTriggerSkill{
	name = "Myongan", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},
	relate_to_place = "deputy",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then		
			if player:getPhase() == sgs.Player_Start and player:isAllNude() then
				local suffer
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasEquip() then
						suffer = p
						break
					end
				end
				if suffer then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasEquip() then
				p:throwAllEquips()
			end
		end
	end,
}
MnuyiCard = sgs.CreateSkillCard{
	name = "MnuyiCard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select, Self)
		if #targets == 0 then
		    return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	feasible = function(self, targets, Self)
		return #targets == 1
	end ,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:setPlayerMark(player, "@nuyi_use", 0)
		room:broadcastSkillInvoke("Mnuyi", 1)
		room:doSuperLightbox("Mwraith", self:objectName())
		target:obtainCard(self, true)
		room:setPlayerMark(target, "@nuyi", 1)
		local log = sgs.LogMessage()
	        log.type = "#nuyi"
			log.from = target
			log.to:append(player)
		room:sendLog(log)
		if player:isWounded() then
			local Recover = sgs.RecoverStruct()
			    Recover.recover = 1
				Recover.who = player
			room:recover(player, Recover)
		end
	end,
}
MnuyiVS = sgs.CreateViewAsSkill{
	name = "Mnuyi",
	n = 3,
	view_filter = function(self, selected, to_select)
		if #selected == 3 then return false end
		for _,card in ipairs(selected) do
		    if card:isKindOf("BasicCard") and to_select:isKindOf("BasicCard") then
			    return false
			elseif card:isKindOf("EquipCard") and to_select:isKindOf("EquipCard") then
			    return false
			elseif card:isKindOf("TrickCard") and to_select:isKindOf("TrickCard") then
			    return false
			end
		end
		return true
	end,
	view_as = function(self, cards) 
		if #cards ~= 3 then return nil end
		local nuyi_card = MnuyiCard:clone()
		for _,card in ipairs(cards) do
			nuyi_card:addSubcard(card)
		end
		return nuyi_card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@Mnuyi"
	end,
}
Mnuyi = sgs.CreateTriggerSkill{
	name = "Mnuyi",
	limit_mark = "@nuyi_use",
	frequency = sgs.Skill_Limited, 
	view_as_skill = MnuyiVS,
	events = {sgs.EventPhaseStart, sgs.Damaged},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then		
			if event == sgs.EventPhaseStart then
				if player:getPhase() == sgs.Player_Discard and player:getMark("@nuyi_use") == 1 and player:isWounded() and not player:isKongcheng() then
					local has_basic = false
					local has_equip = false
					local has_trick = false
					for _, card in sgs.qlist(player:getCards("he")) do
						if card:isKindOf("BasicCard") then
							has_basic = true
						elseif card:isKindOf("EquipCard") then
							has_equip = true
						elseif card:isKindOf("TrickCard") then
							has_trick = true
						end
					end
					if has_basic and has_equip and has_trick then
						local targets = sgs.SPlayerList()
						for _,p in sgs.qlist(room:getOtherPlayers(player)) do
							if player:getHp() >= p:getHp() then
								targets:append(p)
							end
						end
						if not targets:isEmpty() then
							return self:objectName()
						end
					end
				end
			else
				if player:getMark("@nuyi_use") == 0 then
					local target
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getMark("@nuyi") == 1 then
							target = p
							break
						end
					end
					if target then
						return self:objectName()
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if event == sgs.EventPhaseStart then
			if room:askForUseCard(player, "@@Mnuyi", "@nuyi_invoke") then
				return true
			end
		else
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,					
	on_effect = function(self,event,room,player,data)
		if event ==  sgs.Damaged then
			local damage = data:toDamage()
			local target
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getMark("@nuyi") == 1 then
					target = p
					break
				end
			end
			if target then
				for i = 1 , damage.damage, 1 do
					target:drawCards(1)
					if target:getHandcardNum() < 2 then
						room:loseHp(target)
						local recover = sgs.RecoverStruct()
							recover.who = target
							recover.recover = 1
						room:recover(player, recover)
						room:broadcastSkillInvoke(self:objectName(), 2)
					else
						id = room:askForExchange(target, self:objectName(), 2, 2, "nuyi_give", "", ".|.|.|hand")
						room:obtainCard(player, id, false)
						room:broadcastSkillInvoke(self:objectName(), 3)
					end
				end
			end
		end
		return false
	end,
}
--加入技能“枯萎”“衰老”“永暗”“奴役”
Mwraith:addSkill(Mkuwei)
Mwraith:addSkill(Mkuwei_close)
Mwraith:addSkill(Myongan)
Mwraith:addSkill(Mshuailao)
Mwraith:addSkill(Mshuailao_max)
Mwraith:addSkill(Mnuyi)
Ashan3:insertRelatedSkills("Mkuwei", "#Mkuwei_close")
Ashan3:insertRelatedSkills("Mshuailao", "#Mshuailao_max")
--翻译表
sgs.LoadTranslationTable{
    ["Mwraith"] = "阴魂龙",
	["&Mwraith"] = "阴魂龙",
	["#Mwraith"] = "不灭龙魂",
	["Mkuwei"] = "枯萎",
	["#Mkuwei_close"] = "枯萎",
	["$Mkuwei"] = "捕捉你的灵魂！",
	["#kuwei"] = "%from 吸收了死者的灵魂！",
	["@kuwei"] = "枯萎",
	[":Mkuwei"] = "锁定技，其他势力的角色死亡时，若你已受伤，你回复1点体力，否则你与其余角色的距离-1。",
	["Mshuailao"] = "衰老",
	["#Mshuailao_max"] = "衰老",
	["$Mshuailao1"] = "你现在孤立无援！",
	["$Mshuailao2"] = "你想多了。",
	["#shuailao"] = "%from 降低了手牌上限！",
	["@shuailao"] = "衰老",
	["@shuailao_invoke"] = "是否弃置一张基本牌发动技能“衰老”？",
	[":Mshuailao"] = "结束阶段开始时，你可以弃置一张基本牌令一名攻击范围内已受伤其他角色进行一次判定：若结果为红桃，其摸一张牌；否则你摸一张牌且直到你下回合开始时其手牌上限-X（X为其已损失体力值）。",
	["Myongan"] = "永暗",
	["$Myongan"] = "诅咒光明！",
	[":Myongan"] = "副将技，准备阶段开始时，若你区域内没有牌，你可以弃置场上装备区所有牌。",
	["Mnuyi"] = "奴役",
	["$Mnuyi1"] = "你给我带来了新的奴仆！",
	["$Mnuyi2"] = "我的力量再度崛起！",
	["$Mnuyi3"] = "不会留给你的！",
	["#nuyi"] = "%from 成为了 %to 的龙仆！",
	["@nuyi"] = "奴役",
	["MnuyiCard"] = "奴役",
	["mnuyi"] = "奴役",
	["MnuyiVS"] = "奴役",
	["nuyi_give"] = "请交给目标两张手牌。",
	["@nuyi_invoke"] = "是否交给一名其他角色三张不同类型的牌发动技能“奴役”？",
	["~Mnuyi"] = "选择三张不同类型的牌-点击确定。",
	[":Mnuyi"] = "主将技，限定技，弃牌阶段开始时，若你已受伤，你可以正面朝上交给一名其他角色三张不同类型的牌，将其视为“龙仆”并回复1点体力。锁定技，当你受到一点伤害后，“龙仆”须摸一张牌然后交给你两张手牌，否则其失去1点体力使你回复1点体力。",
	["~Mwraith"] = "又一次，心痛欲裂……",
	["cv:Mwraith"] = "暗影恶魔",
	["illustrator:Mwraith"] = "英雄无敌6",
	["designer:Mwraith"] = "月兔君",
}

--[[
   创建武将【亚莎】
]]--
Masha = sgs.General(Ashan3, "Masha", "an", 4, false)
lord_Masha = sgs.General(Ashan3, "lord_Masha$", "an", 4, false, true)
--非君主时珠联璧合：阴魂龙
Masha:addCompanion("Mwraith")
--[[
*【象征】君主技，锁定技，你拥有“亚莎之泪”。
“亚莎之泪”锁定技，准备阶段结束时，你须选择一个新的形态（在选择前你视为拥有“创造之愿”）：
创造之愿：锁定技，与你势力相同/不同的其他角色在出牌阶段结束时摸/弃置X张牌（X为其在出牌阶段内使用牌的次数且最大为2）。
平衡之心：与你势力相同/不同的角色出牌阶段开始时，若你有手牌，你可以令其将手牌补充/弃置到与你的手牌数相同。
灭亡之曲：锁定技，其他势力的角色准备阶段开始时，若其体力值大于你，其进行一次判定：若为红桃，你摸一张牌；若为方块，其跳过摸牌阶段；若为梅花，其跳过出牌阶段；若为黑桃，其弃置等同于已损失体力数的手牌否则失去1点体力。
*【秩序】其他角色结束阶段开始时，你可以将手牌补至X张（X为场上势力数且最大为3）。
]]--
Mxiangzheng = sgs.CreateTriggerSkill{
	name = "Mxiangzheng$",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseEnd},
	can_preshow = false,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and player:hasShownSkill(self) and player:getRole() ~= "careerist" then
			if player:getPhase() == sgs.Player_Start then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:getRole() == "careerist" then return false end
		room:notifySkillInvoked(player, self:objectName())
		if player:getMark("xiangzheng_creat") == 1 then
			choice = room:askForChoice(player, self:objectName(), "xiangzheng_balance+xiangzheng_death", data)
			room:setPlayerMark(player, "xiangzheng_creat", 0)
		elseif player:getMark("xiangzheng_balance") == 1 then
			choice = room:askForChoice(player, self:objectName(), "xiangzheng_creat+xiangzheng_death", data)
			room:setPlayerMark(player, "xiangzheng_balance", 0)
		elseif player:getMark("xiangzheng_death") == 1 then
			choice = room:askForChoice(player, self:objectName(), "xiangzheng_creat+xiangzheng_balance", data)
			room:setPlayerMark(player, "xiangzheng_death", 0)
		else
			choice = room:askForChoice(player, self:objectName(), "xiangzheng_creat+xiangzheng_balance+xiangzheng_death", data)
		end
		if choice == "xiangzheng_creat" then
			room:broadcastSkillInvoke(self:objectName())
			room:doSuperLightbox("Masha", "#Mchuangzao")
			local log = sgs.LogMessage()
				log.type = "#chuangzao"
				log.from = player
			room:sendLog(log)
			room:setPlayerMark(player, "xiangzheng_creat", 1)
			return true
		elseif choice == "xiangzheng_balance" then
			room:broadcastSkillInvoke(self:objectName())
			room:doSuperLightbox("Masha", "#Mpingheng")
			local log = sgs.LogMessage()
				log.type = "#pingheng"
				log.from = player
			room:sendLog(log)
			room:setPlayerMark(player, "xiangzheng_balance", 1)
			return true
		else
			room:broadcastSkillInvoke(self:objectName())
			room:doSuperLightbox("Masha", "#Mmiewang")
			local log = sgs.LogMessage()
				log.type = "#miewang"
				log.from = player
			room:sendLog(log)
			room:setPlayerMark(player, "xiangzheng_death", 1)
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		return false
	end,
}
Mchuangzao = sgs.CreateTriggerSkill{
	name = "#Mchuangzao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreCardUsed, sgs.EventPhaseEnd},
	can_trigger = function(self, event, room, player, data)
		local asha =  room:findPlayerBySkillName("Mxiangzheng")
		if asha and asha:isAlive() and asha:hasShownSkill(Mxiangzheng) and asha:getMark("xiangzheng_balance") == 0 and asha:getMark("xiangzheng_death") == 0 and asha:getRole() ~= "careerist" then
			if event == sgs.PreCardUsed then
				if player:getPhase() == sgs.Player_Play and player:objectName() ~= asha:objectName() then
					if player:hasShownOneGeneral() and player:getMark("create_use") < 2 then
						room:addPlayerMark(player, "create_use", 1)
					end
				end
			elseif event == sgs.EventPhaseEnd then
				if player:getPhase() == sgs.Player_Play then
					if player:getMark("create_use") > 0 then
						if player:isKongcheng() and not player:isFriendWith(asha) then
							room:setPlayerMark(player, "create_use", 0)
						else
							return self:objectName(), asha
						end
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		return true
	end,
	on_effect = function(self,event,room,player,data)
		if event == sgs.EventPhaseEnd then
			local asha =  room:findPlayerBySkillName("Mxiangzheng")
			room:notifySkillInvoked(asha, self:objectName())
			if asha and asha:isAlive() then
				local x = player:getMark("create_use")
				x = math.min(x, 2)
				if player:isFriendWith(asha) then
					room:broadcastSkillInvoke("Mxiangzheng", 4)
					player:drawCards(x)
					room:setPlayerMark(player, "create_use", 0)
				else
					if not player:isKongcheng() then
						room:broadcastSkillInvoke("Mxiangzheng", 5)
						room:setPlayerMark(player, "create_use", 0)
						if x < player:getHandcardNum() then
							room:askForDiscard(player, self:objectName(), x, x, false, false)
						else
							player:throwAllHandCards()
						end
					end
				end
			end
		end
		return false
	end,
}
Mpingheng = sgs.CreateTriggerSkill{
	name = "#Mpingheng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
		local asha =  room:findPlayerBySkillName("Mxiangzheng")
		if asha and asha:isAlive() and asha:hasShownSkill(Mxiangzheng) and asha:getMark("xiangzheng_balance") == 1 and asha:getRole() ~= "careerist" then
			if player:getPhase() == sgs.Player_Play and player:objectName() ~= asha:objectName() and player:hasShownOneGeneral() then
				if not asha:isKongcheng() then
					if (player:getHandcardNum() > asha:getHandcardNum() and not player:isFriendWith(asha)) or (player:getHandcardNum() < asha:getHandcardNum() and player:isFriendWith(asha)) then
						return self:objectName(), asha
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		local asha =  room:findPlayerBySkillName("Mxiangzheng")
		local ai_data = sgs.QVariant()
		ai_data:setValue(player)
		if asha:askForSkillInvoke(self:objectName(), ai_data) then
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local asha =  room:findPlayerBySkillName("Mxiangzheng")
		if asha and asha:isAlive() and not asha:isKongcheng() then
			local x = asha:getHandcardNum()
			local y = player:getHandcardNum()
			if x > y then
				room:broadcastSkillInvoke("Mxiangzheng", 6)
				player:drawCards(x-y)
			elseif x < y then
				room:broadcastSkillInvoke("Mxiangzheng", 7)
				room:askForDiscard(player, self:objectName(), y-x, y-x, false, false)
			end
		end
		return false
	end,
}
Mmiewang = sgs.CreateTriggerSkill{
	name = "#Mmiewang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
		local asha =  room:findPlayerBySkillName("Mxiangzheng")
		if asha and asha:isAlive() and asha:hasShownSkill(Mxiangzheng) and asha:getMark("xiangzheng_death") == 1 and asha:getRole() ~= "careerist" then
			if player:getPhase() == sgs.Player_Start and player:objectName() ~= asha:objectName() then
				if player:hasShownOneGeneral() and not player:isFriendWith(asha) and player:getHp() > asha:getHp() then
					return self:objectName(), asha
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		return true
	end,
	on_effect = function(self,event,room,player,data)
		local asha =  room:findPlayerBySkillName("Mxiangzheng")
		room:notifySkillInvoked(asha, self:objectName())
		if asha and asha:isAlive() then
			local judge = sgs.JudgeStruct()
		        judge.who = player
		        judge.pattern = ".|.|."
		        judge.good = true
	            judge.reason = self:objectName()
				judge.play_animation = true
				judge.negative = false
	        room:judge(judge)
			if judge.card:getSuit() == sgs.Card_Heart then
				room:broadcastSkillInvoke("Mxiangzheng", 8)
				asha:drawCards(1)
			elseif judge.card:getSuit() == sgs.Card_Diamond then
				room:broadcastSkillInvoke("Mxiangzheng", 9)
				if not player:isSkipped(sgs.Player_Draw) then
					player:skip(sgs.Player_Draw)
				end
			elseif judge.card:getSuit() == sgs.Card_Club then
				room:broadcastSkillInvoke("Mxiangzheng", 10)
				if not player:isSkipped(sgs.Player_Play) then
					player:skip(sgs.Player_Play)
				end
			else
				if player:isWounded() then
					room:broadcastSkillInvoke("Mxiangzheng", 11)
					local x = player:getLostHp()
					local y = player:getHandcardNum()
					if y > x then
						room:askForDiscard(player, self:objectName(), x, x, false, false)
					elseif y == x then
						player:throwAllHandCards()
					else
						room:loseHp(player, 1)
					end
				end
			end
		end
		return false
	end,
}
Mzhixu = sgs.CreateTriggerSkill{
	name = "Mzhixu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},		
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		local asha =  room:findPlayerBySkillName(self:objectName())
		if asha and asha:isAlive() then
			if player:getPhase() == sgs.Player_Finish and player:objectName() ~= asha:objectName() then
				local kingdom_num = 0
				local kingdoms = {}
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:getRole() ~= "careerist" and p:hasShownOneGeneral() then
						local flag = true
						local kingdom = p:getKingdom()
						for _,k in pairs(kingdoms) do
							if k == kingdom then
								flag = false
								break
							end
						end
						if flag then
							table.insert(kingdoms, kingdom)
						end
					end
				end
				local kingdom_num = #kingdoms
				kingdom_num = math.min(kingdom_num, 3)
				if asha:getHandcardNum() < kingdom_num then
					return self:objectName(), asha
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		local asha =  room:findPlayerBySkillName(self:objectName())
		if asha and asha:isAlive() then
			if asha:askForSkillInvoke(self:objectName(), data) then
				return true
			end
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local asha =  room:findPlayerBySkillName(self:objectName())
		if asha and asha:isAlive() then
			local kingdom_num = 0
			local kingdoms = {}
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getRole() ~= "careerist" then
					local flag = true
					local kingdom = p:getKingdom()
					for _,k in pairs(kingdoms) do
						if k == kingdom then
							flag = false
							break
						end
					end
					if flag then
						table.insert(kingdoms, kingdom)
					end
				end
			end
			local kingdom_num = #kingdoms
			kingdom_num = math.min(kingdom_num, 3)
			if asha:getHandcardNum() < kingdom_num then
				room:broadcastSkillInvoke(self:objectName())
				asha:drawCards(kingdom_num - asha:getHandcardNum())
			end
		end
		return false
	end,
}				
--武将加入技能“象征”“创造”“平衡”“灭亡”“秩序”
Masha:addSkill(Mzhixu)
lord_Masha:addSkill(Mxiangzheng)	
lord_Masha:addSkill(Mchuangzao)
lord_Masha:addSkill(Mpingheng)
lord_Masha:addSkill(Mmiewang)
lord_Masha:addSkill(Mzhixu)
Ashan3:insertRelatedSkills("Mxiangzheng", "#Mchuangzao")
Ashan3:insertRelatedSkills("Mxiangzheng", "#Mpingheng")
Ashan3:insertRelatedSkills("Mxiangzheng", "#Mmiewang")				
--武将注释
sgs.LoadTranslationTable{
	["lord_Masha"] = "亚莎",
	["&lord_Masha"] = "亚莎",
	["#lord_Masha"] = "秩序之龙",
	["Masha"] = "亚莎",
	["&Masha"] = "亚莎",
	["#Masha"] = "秩序之龙",
	["Mxiangzheng"] = "象征",
	["$Mxiangzheng1"] = "我会让他们心生畏惧。",
	["$Mxiangzheng2"] = "我可不要再心慈手软。",
	["$Mxiangzheng3"] = "月有盈亏，我的仁慈亦然!",
	["xiangzheng_creat"] = "创造之愿",
	["xiangzheng_balance"] = "平衡之心",
	["xiangzheng_death"] = "灭亡之曲",
	["#Mchuangzao"] = "创造",
	["#Mpingheng"] = "平衡",
	["#Mmiewang"] = "灭亡",
	["#chuangzao"] = "%from 选择了“创造”模式。",
	["#pingheng"] = "%from 选择了“平衡”模式。",
	["#miewang"] = "%from 选择了“灭亡”模式。",
	["$Mxiangzheng4"] = "忠诚的勇士理应受到庇护。",
	["$Mxiangzheng5"] = "毫无价值。",
	["$Mxiangzheng6"] = "星光灿烂。",
	["$Mxiangzheng7"] = "仅此而已？",
	["$Mxiangzheng8"] = "一轮新月。",
	["$Mxiangzheng9"] = "别跟暗月作对！",
	["$Mxiangzheng10"] = "夜幕降临。",
	["$Mxiangzheng11"] = "星空，取你性命！",
	[":Mxiangzheng"] = "君主技，锁定技，你拥有“亚莎之泪”。\n\n“亚莎之泪”\n锁定技，准备阶段结束时，你须选择一个新的形态（在选择前你视为拥有“创造之愿”）：\n【创造之愿】锁定技，与你势力相同/不同的其他角色在出牌阶段结束时摸/弃置X张牌（X为其在出牌阶段内使用牌的次数且最大为2）。\n【平衡之心】与你势力相同/不同的角色出牌阶段开始时，若你有手牌，你可以令其将手牌补充/弃置到与你的手牌数相同。\n【灭亡之曲】锁定技，其他势力的角色准备阶段开始时，若其体力值大于你，其进行一次判定：若为红桃，你摸一张牌；若为方块，其跳过摸牌阶段；若为梅花，其跳过出牌阶段；若为黑桃，其弃置等同于已损失体力数的手牌否则失去1点体力。",
	["Mzhixu"] = "秩序",
	["$Mzhixu"] = "又一轮月相开始了。",
	[":Mzhixu"] = "其他角色结束阶段开始时，你可以将手牌补至X张（X为场上势力数且最大为3）。",
	["~Masha"] = "我……本该做的更好……",
	["cv:Masha"] = "月之骑士",
	["illustrator:Masha"] = "英雄无敌6",
	["designer:Masha"] = "月兔君",
	["cv:lord_Masha"] = "月之骑士",
	["illustrator:lord_Masha"] = "英雄无敌6",
	["designer:lord_Masha"] = "月兔君",
}
					
					
--[[******************
    创建种族【地狱】
]]--******************

--[[
   创建武将【狂魔】
]]--
Mdemented = sgs.General(Ashan3, "Mdemented", "an", 3)
--珠联璧合：深渊领主
Mdemented:addCompanion("Mpitlord")
--[[
*【扭曲】锁定技，当你被指定为红色非延时锦囊的目标后，若你已受伤，你回复1点体力并使该锦囊对你无效。
【癫笑】锁定技，当你受到一次【杀】造成的伤害后，你造成的下一次伤害+1。锁定技，当你使用【杀】对目标角色造成一次伤害后，其造成的下一次伤害-1。
]]--
Mniuqu = sgs.CreateTriggerSkill{ 
    name = "Mniuqu",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetConfirmed},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local use = data:toCardUse()
			if use.card and use.card:isNDTrick() and use.card:isRed() and use.to:contains(player) and player:isWounded() then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self) or room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		if player:isWounded() then
			local recover = sgs.RecoverStruct()
				recover.recover = 1
				recover.who = player
			room:recover(player, recover)
		end
		room:setPlayerFlag(player, "Mniuqu_avoid")
	end,
}
Mniuqu_avoid = sgs.CreateTriggerSkill{
	name = "#Mniuqu_avoid",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardEffected},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill("Mniuqu") and player:hasFlag("Mniuqu_avoid") then
			local effect = data:toCardEffect()
			if effect.card and effect.card:isNDTrick() and effect.card:isRed() then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		room:setPlayerFlag(player, "-Mniuqu_avoid")
		room:notifySkillInvoked(player, self:objectName())
		return true
	end,
	on_effect = function(self, event, room, player, data)
		local effect = data:toCardEffect()
		local log = sgs.LogMessage()
			if effect.from then
				log.type = "$CancelTarget"
				log.from = effect.from
			else
				log.type = "$CancelTargetNoUser"
			end
			log.to:append(player)
			log.arg = effect.card:objectName()
		room:sendLog(log)
		return true
	end,
}
Mdianxiao = sgs.CreateTriggerSkill{
	name = "Mdianxiao",
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damaged, sgs.Damage},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if event == sgs.Damaged then
				if player:getMark("@dianxiaoA") == 0 and damage.card and damage.card:isKindOf("Slash") then
					return self:objectName()
				end
			else
				if damage.card and damage.card:isKindOf("Slash") and not (damage.chain or damage.transfer) and damage.to:isAlive() and damage.to:getMark("@dianxiaoB") == 0 then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if event == sgs.Damaged then
			if player:hasShownSkill(self) or room:askForSkillInvoke(player, "Mdianxiao1", data) then
				room:notifySkillInvoked(player, self:objectName())
				return true
			end
		else
			if player:hasShownSkill(self) or room:askForSkillInvoke(player, "Mdianxiao2", data) then
				room:notifySkillInvoked(player, self:objectName())
				return true
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local damage = data:toDamage()
		if event == sgs.Damaged then
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:setPlayerMark(player, "@dianxiaoA", 1)
			local log = sgs.LogMessage()
				log.type = "#dianxiao1"
				log.from = player
				log.arg = self:objectName()
			room:sendLog(log)
		else
			room:broadcastSkillInvoke(self:objectName(), 2)
			room:setPlayerMark(damage.to, "@dianxiaoB", 1)
			local log = sgs.LogMessage()
				log.type = "#dianxiao2"
				log.from = damage.to
				log.arg = self:objectName()
			room:sendLog(log)
		end
	end,
}
Mdianxiao_effect = sgs.CreateTriggerSkill{
	name = "#Mdianxiao_effect",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted, sgs.DamageCaused},
	can_trigger = function(self, event, room, player, data)
		local damage = data:toDamage()
		if event == sgs.DamageInflicted then
			if damage.from and damage.from:getMark("@dianxiaoB") == 1 then
				room:setPlayerMark(damage.from, "@dianxiaoB", 0)
				return self:objectName()
			end
		else
			if player and player:getMark("@dianxiaoA") == 1 then
			    room:setPlayerMark(player, "@dianxiaoA", 0)
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		return true
	end,
	on_effect = function(self, event, room, player, data)
		local damage = data:toDamage()
		if event == sgs.DamageInflicted then
			room:notifySkillInvoked(damage.from, self:objectName())
			room:broadcastSkillInvoke("Mdianxiao", 4)
			local log = sgs.LogMessage()
				log.type = "#DamageLess"
				log.from = damage.from
				log.arg = self:objectName()
			room:sendLog(log)
			if damage.damage > 1 then
				damage.damage = damage.damage - 1
				data:setValue(damage)
			else
				return true
			end
		else
			room:notifySkillInvoked(player, self:objectName())
			room:broadcastSkillInvoke("Mdianxiao", 3)
			local log = sgs.LogMessage()
				log.type = "#DamageMore"
				log.from = player
				log.arg = self:objectName()
			room:sendLog(log)
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
	end,
}
--加入技能“扭曲”“癫笑”
Mdemented:addSkill(Mniuqu)
Mdemented:addSkill(Mniuqu_avoid)
Mdemented:addSkill(Mdianxiao)
Mdemented:addSkill(Mdianxiao_effect)
Ashan3:insertRelatedSkills("Mniuqu", "#Mniuqu_avoid")
Ashan3:insertRelatedSkills("Mdianxiao", "#Mdianxiao_effect")
--翻译表
sgs.LoadTranslationTable{
    ["Mdemented"] = "狂魔",
	["&Mdemented"] = "狂魔",
	["#Mdemented"] = "疯癫不羁",
	["Mniuqu"] = "扭曲",
	["#Mniuqu_avoid"] = "扭曲",
	["$Mniuqu"] = "不再玩好心了，免得你误会我。",
	[":Mniuqu"] = "锁定技，当你被指定为红色非延时锦囊的目标后，若你已受伤，你回复1点体力并使该锦囊对你无效。",
	["Mdianxiao"] = "癫笑",
	["Mdianxiao1"] = "癫笑",
	["Mdianxiao2"] = "癫笑",
	["#Mdianxiao_effect"] = "癫笑",
	["$Mdianxiao1"] = "我会杀光你们全部！",
	["$Mdianxiao2"] = "仇恨让我兴奋！",
	["$Mdianxiao3"] = "（狂笑）",
	["$Mdianxiao4"] = "（狂笑）",
	["@dianxiaoA"] = "癫笑增强",
	["@dianxiaoB"] = "癫笑削弱",
	["#dianxiao1"] = "由于 %arg 的效果，%from 造成的下一次伤害+1。",
	["#dianxiao2"] = "由于 %arg 的效果，%from 造成的下一次伤害-1。",
	[":Mdianxiao"] = "锁定技，当你受到一次【杀】造成的伤害后，你造成的下一次伤害+1。锁定技，当你使用【杀】对目标角色造成一次伤害后，其造成的下一次伤害-1。",
	["~Mdemented"] = "我的仇恨会带我回去！",
	["cv:Mdemented"] = "巨魔战将",
	["illustrator:Mdemented"] = "英雄无敌6",
	["designer:Mdemented"] = "月兔君",
}

--[[
   创建武将【狼魔】
]]--
Mcerberus = sgs.General(Ashan3, "Mcerberus", "an", 3)
--珠联璧合：暴魔
Mcerberus:addCompanion("Mravager")
--[[
*【悭吝】锁定技，摸牌阶段你放弃摸牌，改为随机摸一张到X+3张牌（X为你已损失体力，最大为2）。
*【饕餮】当你使用【杀】对目标角色造成一次伤害后，若其有手牌，你可以将其一张手牌暗置于其武将牌上称为“饕餮”。锁定技，当你受到其他角色造成的一次伤害后，若其在你的攻击范围内且其有“饕餮”牌，你须摸其“饕餮”数量的牌（最多三张），若此时你的手牌数大于该角色，你视为对该角色使用了一张【火杀】。
]]--
Mqianlin = sgs.CreateTriggerSkill{
	name = "Mqianlin",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Draw then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self) or room:askForSkillInvoke(player, self:objectName(), data) then
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		math.random()
		local x = math.min(2, player:getLostHp())
		math.random()
		local n = math.random(1, x+3)
		if n == 1 or n == 2 then
			room:broadcastSkillInvoke(self:objectName(), 1)
		elseif n == 3 or n == 4 then
			room:broadcastSkillInvoke(self:objectName(), 2)
		else
			room:broadcastSkillInvoke(self:objectName(), 3)
		end
		player:drawCards(n)
		return true
	end,
}
Mtaotie = sgs.CreateTriggerSkill{
	name = "Mtaotie",
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if damage.to:isAlive() and damage.card and damage.card:isKindOf("Slash") and not (damage.chain or damage.transfer) then
				if not damage.to:isKongcheng() then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local damage = data:toDamage()
		if not damage.to:isKongcheng() then
			local id = room:askForCardChosen(player, damage.to, "h", self:objectName())
			damage.to:addToPile("taotie", id, false)
		end
	end,
}
Mtaotie_effect = sgs.CreateTriggerSkill{
	name = "#Mtaotie_effect",
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damaged},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill("Mtaotie") then
			local damage = data:toDamage()
			if damage.from and damage.from:isAlive() and damage.from:getPile("taotie"):length() > 0 then
				if player:inMyAttackRange(damage.from) then
					return self:objectName(), player
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(Mtaotie) or room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), 2)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local damage = data:toDamage()
		local m = damage.from:getPile("taotie"):length()
		m = math.min(m,3)
		player:drawCards(m)
		room:getThread():delay(1000)
		if player:getHandcardNum() > damage.from:getHandcardNum() then
			local slash = sgs.Sanguosha:cloneCard("fire_slash")
			slash:setSkillName("Mtaotie")
			if player:canSlash(damage.from,slash,false) then
				room:broadcastSkillInvoke(self:objectName(), 3)
				local use = sgs.CardUseStruct()
					use.from = player
					use.to:append(damage.from)
					use.card = slash
				room:useCard(use, false)
			else
				room:broadcastSkillInvoke(self:objectName(), 4)
			end
		end
	end,
}
--加入技能“饕餮”“悭吝”
Mcerberus:addSkill(Mqianlin)
Mcerberus:addSkill(Mtaotie)
Mcerberus:addSkill(Mtaotie_effect)
Ashan3:insertRelatedSkills("Mtaotie", "#Mtaotie_effect")
--翻译表
sgs.LoadTranslationTable{
    ["Mcerberus"] = "狼魔",
	["&Mcerberus"] = "狼魔",
	["#Mcerberus"] = "贪婪成性",
	["Mqianlin"] = "悭吝",
	["$Mqianlin1"] = "你都做了什么？（我？）",
	["$Mqianlin2"] = "你确定不是你太走运？（当然不是！）",
	["$Mqianlin3"] = "（一次远远不够！）再多我就数不过来啦！",
	[":Mqianlin"] = "锁定技，摸牌阶段你放弃摸牌，改为随机摸一张到X+3张牌（X为你已损失体力，最大为2）。",
	["Mtaotie"] = "饕餮",
	["#Mtaotie_effect"] = "饕餮",
	["$Mtaotie1"] = "（我喜欢这样！）我也是！",
	["$Mtaotie2"] = "战利品得平分！（战利品得平分！）",
	["$Mtaotie3"] = "（下次注意点！）谁？我吗？",
	["$Mtaotie4"] = "（没什么好主意啊！）什么？",
	["taotie"] = "饕餮",
	[":Mtaotie"] = "当你使用【杀】对目标角色造成一次伤害后，若其有手牌，你可以将其一张手牌暗置于其武将牌上称为“饕餮”。锁定技，当你受到其他角色造成的一次伤害后，若其在你的攻击范围内且其有“饕餮”牌，你须摸其“饕餮”数量的牌（最多三张），若此时你的手牌数大于该角色，你视为对该角色使用了一张【火杀】。",
	["~Mcerberus"] = "（这都是你的错！（这都是你的错！）",
	["cv:Mcerberus"] = "食人魔法师",
	["illustrator:Mcerberus"] = "英雄无敌6",
	["designer:Mcerberus"] = "月兔君",
}

--[[
   创建武将【魅魔】
]]--
Mlilim = sgs.General(Ashan3, "Mlilim", "an", 3, false)
--[[
【愉悦】你使用【杀】指定一名异性目标后，你可以弃置一张手牌（若你已受伤则不弃）令该角色不能使用【闪】对此【杀】进行响应，若如此做，其摸一张牌。
*【诱惑】摸牌阶段，若你手牌数小于体力上限，你可以放弃摸牌，改为选择一个颜色并观看一名异性角色的手牌，然后你获得其所有与你所选颜色相同的手牌：若以此法获得至少三张手牌，其可以令你将武将牌叠置；若以此法没有获得手牌，你摸一张牌。
]]--
Myuyue = sgs.CreateTriggerSkill{
	name = "Myuyue",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetChosen},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") then
				if player:isWounded() or not player:isKongcheng() then
					local targets_names = {}
					for _,p in sgs.qlist(use.to) do
						if p:getGender() ~= player:getGender() then
							table.insert(targets_names,p:objectName())
						end	
					end
					if #targets_names > 0 then
						return self:objectName() .. "->" .. table.concat(targets_names, "+"), player
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, target, data, player)
		local ai_data = sgs.QVariant()
		ai_data:setValue(target)
		if player:askForSkillInvoke(self:objectName(), ai_data) then
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, target, data, player)
		local use = data:toCardUse()
		if player:isWounded() then
			room:broadcastSkillInvoke(self:objectName(), 2)
		else
			local id = room:askForExchange(player, self:objectName(), 1, 1, "yuyue_throw", "", ".|.|.|hand"):getSubcards():first()
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:throwCard(id, player, player)
		end
		local jink_list = player:getTag("Jink_"..use.card:toString()):toList()
		local new_jink_list = sgs.VariantList()
		local index = 0
		for _, p in sgs.qlist(use.to) do
			if p:objectName() == target:objectName() then
				new_jink_list:append(sgs.QVariant(0))
			else
				new_jink_list:append(jink_list:at(index))
			end
			index = index+1
		end
		local jink_data = sgs.QVariant(new_jink_list)
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		local log = sgs.LogMessage()
			log.type = "#NoJink"
			log.from = target
		room:sendLog(log)
		target:drawCards(1)
	end,
}
Myouhuo = sgs.CreateTriggerSkill{
    name = "Myouhuo",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.EventPhaseStart},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Draw and player:getHandcardNum() < player:getMaxHp() then
				local targets = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getGender() ~= player:getGender() and not p:isKongcheng() then
						targets:append(p)
					end
				end
				if not targets:isEmpty() then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		choice = room:askForChoice(player, self:objectName(), "youhuo_red+youhuo_black", data)
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getGender() ~= player:getGender() and not p:isKongcheng() then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, self:objectName())
			room:showAllCards(target, player)
			local m = 0
			local empty = MemptyCard:clone()
			if choice == "youhuo_black" then
				for _, cd in sgs.qlist(target:getHandcards()) do
					if cd:isBlack() then
						empty:addSubcard(cd)
					end
				end
			else
				for _, cd in sgs.qlist(target:getHandcards()) do
					if cd:isRed() then
						empty:addSubcard(cd)
					end
				end
			end
			room:getThread():delay(1000)
			if empty:subcardsLength() > 0 then
				room:broadcastSkillInvoke(self:objectName(), 2)
				player:obtainCard(empty, true)
				if empty:subcardsLength() >= 3 and player:faceUp() then
					local ai_data = sgs.QVariant()
					ai_data:setValue(player)
					choice = room:askForChoice(target, "youhuo_effect", "youhuo_yes+youhuo_no", ai_data)
					if choice == "youhuo_yes" then
						room:broadcastSkillInvoke(self:objectName(), 4)
						player:turnOver()
					end
				end
			else
				player:drawCards(1)
				room:broadcastSkillInvoke(self:objectName(), 3)
			end
			return true
		end
	end,
}
--加入技能“愉悦”“诱惑”
Mlilim:addSkill(Myuyue)
Mlilim:addSkill(Myouhuo)
--翻译表
sgs.LoadTranslationTable{
    ["Mlilim"] = "魅魔",
	["&Mlilim"] = "魅魔",
	["#Mlilim"] = "诱惑妖姬",
	["Myuyue"] = "愉悦",
	["yuyue_throw"] = "请弃置一张手牌。",
	["$Myuyue1"] = "我喜欢你抵抗的样子。",
	["$Myuyue2"] = "多么美妙的痛苦呀~",
	[":Myuyue"] = "你使用【杀】指定一名异性目标后，你可以弃置一张手牌（若你已受伤则不弃）令该角色不能使用【闪】对此【杀】进行响应，若如此做，其摸一张牌。",
	["Myouhuo"] = "诱惑",
	["youhuo_effect"] = "诱惑",
	["$Myouhuo1"] = "我真喜欢你挣扎的样子~",
	["$Myouhuo2"] = "有那么糟糕吗？",
	["$Myouhuo3"] = "真差劲！",
	["$Myouhuo4"] = "进来吧~",
	["youhuo_red"] = "红唇诱惑",
	["youhuo_black"] = "黑丝诱惑",
	["youhuo_yes"] = "推倒她",
	["youhuo_no"] = "不推倒",
	[":Myouhuo"] = "摸牌阶段，若你手牌数小于体力上限，你可以放弃摸牌，改为选择一个颜色并观看一名异性角色的手牌，然后你获得其所有与你所选颜色相同的手牌：若以此法获得至少三张手牌，其可以令你将武将牌叠置；若以此法没有获得手牌，你摸一张牌。",	
	["~Mlilim"] = "这是名为死亡的痛苦。",
	["cv:Mlilim"] = "痛苦女王",
	["illustrator:Mlilim"] = "英雄无敌6",
	["designer:Mlilim"] = "月兔君",
}	

--[[
   创建武将【衍魔】
]]--
Mbreeder = sgs.General(Ashan3, "Mbreeder", "an", 4, false)
--珠联璧合：魅魔，刑魔
Mbreeder:addCompanion("Mlilim")
Mbreeder:addCompanion("Mlacerator")
--[[
*【增殖】锁定技，当你的体力发生一次变化前，你摸一张牌。锁定技，你的回合外,若你已受伤，每当你的手牌数变化后，若你的手牌数不为X，你须将手牌补至或弃置至X张（X为你已损失体力）。
*【回归】副将技，当一名与你相同势力的其他角色进入濒死时，若你已受伤其可以令你回复1点体力，否则其可以令你将手牌数补充至体力上限，若如此做，该角色死亡（视为天灾）。
*【繁衍】主将技，当与你相同势力的其他角色死亡时，若其不为魔婴且你手牌数不小于两张，你可以弃置所有手牌令其在死亡（你无视特殊模式带来的死亡惩罚）后复活为“魔婴/士兵”，然后其摸两张牌。
]]--
Mzengzhi = sgs.CreateTriggerSkill{
	name = "Mzengzhi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.HpChanged, sgs.CardsMoveOneTime},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if event == sgs.HpChanged then
				return self:objectName()
			else
				local move = data:toMoveOneTime()
				if player:getPhase() == sgs.Player_NotActive and player:isWounded() then
					if (move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand))
						or (move.to and move.to :objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand) then
						local x = player:getLostHp()
						if player:getHandcardNum() ~= x then
							return self:objectName()
						end
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self) or room:askForSkillInvoke(player, self:objectName(), data) then
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		if event == sgs.HpChanged then
			room:broadcastSkillInvoke(self:objectName(), 1)
			player:drawCards(1)
		else
			if not player:isWounded() then return false end
			local x = player:getLostHp()
			local y = player:getHandcardNum()
			if y ~= x then
				if y < x then
					room:getThread():delay(500)
					room:broadcastSkillInvoke(self:objectName(), 2)
					player:drawCards(x - y)
				else
					room:getThread():delay(500)
					room:broadcastSkillInvoke(self:objectName(), 3)
					room:askForDiscard(player, self:objectName(), y-x, y-x, false, false)
				end
			end
		end
	end,
}
Mhuigui = sgs.CreateTriggerSkill{
	name = "Mhuigui",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Dying},
	relate_to_place = "deputy",
	can_trigger = function(self, event, room, player, data)
		local breeder =  room:findPlayerBySkillName(self:objectName())
		if breeder and breeder:isAlive() and breeder:hasShownSkill(self) then
			local dying = data:toDying()
			if dying.who:hasShownOneGeneral() and dying.who:objectName() == player:objectName() and dying.who:objectName() ~= breeder:objectName() and dying.who:isFriendWith(breeder) and (breeder:isWounded() or breeder:getHandcardNum() < breeder:getMaxHp()) then
				return self:objectName(), breeder
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		local breeder =  room:findPlayerBySkillName(self:objectName())
		local ai_data = sgs.QVariant()
		ai_data:setValue(breeder)
		if room:askForSkillInvoke(player, self:objectName(), ai_data) then
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local dying = data:toDying()
		local breeder =  room:findPlayerBySkillName(self:objectName())
		if breeder:isWounded() then
			local recover = sgs.RecoverStruct()
				recover.recover = 1
				recover.who = player
			room:recover(breeder, recover)
			room:notifySkillInvoked(breeder, self:objectName())
		else
			local x = breeder:getMaxHp() - breeder:getHandcardNum()
			if x > 0 then
				breeder:drawCards(x)
				room:notifySkillInvoked(breeder, self:objectName())
			end
		end
		room:killPlayer(dying.who)
	end,
}
Mfanyan = sgs.CreateTriggerSkill{
	name = "Mfanyan",  
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Death},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getHandcardNum() > 1 then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() and death.who:hasShownOneGeneral() and (player:isFriendWith(death.who) or player:willBeFriendWith(death.who)) then
				if death.who:getGeneralName() ~= "Mbug" then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if room:askForSkillInvoke(player, self:objectName(), data) then
			player:throwAllHandCards()
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		room:setPlayerMark(player, "chaomu", 1)
		room:setPlayerMark(player, "fanyan_ing", 1)
	end,
}
Mfanyan_effect = sgs.CreateTriggerSkill{
	name = "#Mfanyan_effect",  
	frequency = sgs.Skill_Compulsory,
	priority = -1,
	events = {sgs.BuryVictim},
	can_trigger = function(self, event, room, player, data)
		local breeder =  room:findPlayerBySkillName("Mfanyan")
		if breeder and breeder:isAlive() and breeder:getMark("fanyan_ing") == 1 then
			if player:objectName() ~= breeder:objectName() and player:isFriendWith(breeder) then
				room:setPlayerMark(breeder, "fanyan_ing", 0)
				room:notifySkillInvoked(player, self:objectName())
				player:removeGeneral(true)
				player:removeGeneral(false)
				room:setPlayerProperty(player, "general", sgs.QVariant("Mbug"))
				room:handleAcquireDetachSkills(player, "Mshimo")
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(2))
				room:setPlayerProperty(player, "hp", sgs.QVariant(2))
--				for _,skill in sgs.qlist(player:getVisibleSkillList()) do
--					room:handleAcquireDetachSkills(player, -skill:objectName())
--				end
				room:revivePlayer(player)
				player:drawCards(2)
			end
		end
		return ""
	end,
}
--加入技能“增殖”“巢母”“繁衍”
Mbreeder:addSkill(Mzengzhi)
Mbreeder:addSkill(Mfanyan)
Mbreeder:addSkill(Mfanyan_effect)
Mbreeder:addSkill(Mhuigui)
Ashan3:insertRelatedSkills("Mfanyan", "#Mfanyan_effect")
--翻译表
sgs.LoadTranslationTable{
    ["Mbreeder"] = "衍魔",
	["&Mbreeder"] = "衍魔",
	["#Mbreeder"] = "膨胀欲望",
	["Mzengzhi"] = "增殖",
	["$Mzengzhi1"] = "噢，我的猎物！",
	["$Mzengzhi2"] = "食欲焚身！",
	["$Mzengzhi3"] = "囊中之物。",
	[":Mzengzhi"] = "锁定技，当你的体力发生一次变化前，你摸一张牌。锁定技，你的回合外,若你已受伤，每当你的手牌数变化后，若你的手牌数不为X，你须将手牌补至或弃置至X张（X为你已损失体力）。",
	["Mfanyan"] = "繁衍",
	["$Mfanyan"] = "更多的嘴巴等着吃饭呢！",
	[":Mfanyan"] = "主将技，当与你相同势力的其他角色死亡时，若其不为魔婴且你手牌数不小于两张，你可以弃置所有手牌令其在死亡（你无视特殊模式带来的死亡惩罚）后复活为“魔婴/士兵”，然后其摸两张牌。",
	["Mhuigui"] = "回归",
	["$Mhuigui"] = "到妈妈这儿来！",
	[":Mhuigui"] = "副将技，当一名与你相同势力的其他角色进入濒死时，若你已受伤其可以令你回复1点体力，否则其可以令你将手牌数补充至体力上限，若如此做，该角色死亡（视为天灾）。",
	["~Mbreeder"] = "我，不该贪得无厌！",
	["cv:Mbreeder"] = "育母蜘蛛",
	["illustrator:Mbreeder"] = "英雄无敌6",
	["designer:Mbreeder"] = "月兔君",
}

--[[
   创建武将【魔婴】
]]--
Mbug = sgs.General(Ashan3, "Mbug", "an", -1, true, true)
--[[
*【噬魔】锁定技，当你对衍魔或与你相同势力的其他角色造成伤害时，防止之。锁定技，出牌阶段结束时，若你于此阶段造成了伤害，衍魔摸一张牌。锁定技，衍魔死亡时，你死亡。锁定技，你的死亡不触发奖惩。
]]--
Mshimo = sgs.CreateTriggerSkill{
	name = "Mshimo",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted, sgs.Damage, sgs.EventPhaseEnd, sgs.Death},
	can_trigger = function(self, event, room, player, data)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
		    if damage.from and damage.from:hasSkill(self:objectName()) and (damage.to:getMark("chaomu") == 1 or (damage.to:isFriendWith(damage.from) and damage.to:hasShownOneGeneral() and damage.to:objectName() ~= damage.from:objectName())) then
				return self:objectName(), damage.from
			end
		elseif event == sgs.Damage then
			if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play then
			    room:setPlayerFlag(player, "shimo_invoke")
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play and player:hasSkill(self:objectName()) and player:hasFlag("shimo_invoke") then
				room:setPlayerFlag(player, "-shimo_invoke")
				local breeder
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getMark("chaomu") == 1 then
						breeder = p
						break
				    end
				end
				if breeder then
					return self:objectName(), player
				end
			end
		else
			local death = data:toDeath()
			if death.who:getMark("chaomu") == 1 and player:hasSkill(self:objectName()) then
				return self:objectName(), player
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		return true
	end,
	on_effect = function(self, event, room, player, data)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:notifySkillInvoked(damage.from, self:objectName())
			local log = sgs.LogMessage()
	            log.type = "#shimo"
				log.from = damage.from
				log.to:append(damage.to)
				log.arg = self:objectName()
			room:sendLog(log)
			return true
		elseif event == sgs.EventPhaseEnd then
			local breeder
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getMark("chaomu") == 1 then
					breeder = p
					break
				end
			end
			if breeder then
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:notifySkillInvoked(breeder, self:objectName())
				breeder:drawCards(1)
			end
		elseif event == sgs.Death then
			room:broadcastSkillInvoke(self:objectName(), 3)
			room:notifySkillInvoked(player, self:objectName())
			room:killPlayer(player)
		end
	end,
}
--加入技能“噬魔”
Mbug:addSkill(Mshimo)
--翻译表
sgs.LoadTranslationTable{
    ["Mbug"] = "魔婴",
	["&Mbug"] = "魔婴",
	["#Mbug"] = "巢母之子",
	["Mshimo"] = "噬魔",
	["$Mshimo1"] = "吞噬并成长（英）。",
	["$Mshimo2"] = "到妈妈这儿来！",
	["$Mshimo3"] = "如此痛苦（英）",
	["#shimo"] = "由于 %arg 的效果，%from 无法对 %to 造成伤害！",
	[":Mshimo"] = "锁定技，当你对衍魔或与你相同势力的角色造成伤害时，防止之。锁定技，出牌阶段结束时，若你于此阶段造成了伤害，衍魔摸一张牌。锁定技，衍魔死亡时，你死亡。锁定技，你的死亡不执行奖惩",
	["~Mbug"] = "我的猎物都跑了。",
	["cv:Mbug"] = "赏金猎人",
	["illustrator:Mbug"] = "英雄无敌6",
	["designer:Mbug"] = "月兔君",
}
	
--[[
   创建武将【刑魔】
]]--
Mlacerator = sgs.General(Ashan3, "Mlacerator", "an", 4)
--[[
*【苦楚】当你对其他角色造成一次无属性伤害后，若其有手牌，你可以弃置一张牌进行一次判定：若结果为红桃，视为你对其使用了一张“决斗”；若结果为方块，你随机摸一到三张牌；若结果为梅花，对方弃置所有手牌然后摸一张牌；若结果为黑桃，若你已受伤，你回复1点体力并将你的武将牌叠置，否则你摸一张牌。
*【折磨】锁定技，当你被其他势力的角色指定为非延时锦囊的目标时，若你区域内有牌，你令其弃置你区域内一张牌，然后你摸一张牌并取消之：若此时该角色在你的攻击范围内，你可以对其使用一张【杀】。锁定技，杀死你的角色获得技能【施虐】。
*【施虐】锁定技，当你被其他角色指定为非延时锦囊的目标时，若你区域内有牌，你令其弃置你区域内一张牌，然后你取消之。
]]--
Mkuchu = sgs.CreateTriggerSkill{
	name = "Mkuchu", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if damage.to and damage.to:isAlive() and damage.to:objectName() ~= player:objectName() and not player:isKongcheng() and not damage.to:isKongcheng() and damage.nature == sgs.DamageStruct_Normal then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if room:askForCard(player, ".|.", "@kuchu_invoke", data, sgs.Card_MethodDiscard) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local damage = data:toDamage()
		local judge = sgs.JudgeStruct()
			judge.reason = self:objectName()
			judge.who = player
		room:judge(judge)
		room:getThread():delay(1000)
		if judge.card:getSuit() == sgs.Card_Heart then
			room:broadcastSkillInvoke(self:objectName(), 2)
			if damage.to:isAlive() then
				local duel = sgs.Sanguosha:cloneCard("duel")
				duel:setSkillName(self:objectName())
				if not player:isProhibited(damage.to, duel) then
					room:notifySkillInvoked(player, self:objectName())
					local use = sgs.CardUseStruct()
						use.from = player
						use.to:append(damage.to)
						use.card = duel
					room:useCard(use, false)
				end
			end
		elseif judge.card:getSuit() == sgs.Card_Diamond then
			math.random()
			room:broadcastSkillInvoke(self:objectName(), 3)
			local n = math.random(1,3)
			player:drawCards(n)
		elseif judge.card:getSuit() == sgs.Card_Club then
			room:broadcastSkillInvoke(self:objectName(), 4)
			if damage.to:isAlive() and not damage.to:isKongcheng() then
				damage.to:throwAllHandCards()
				damage.to:drawCards(1)
			end
		elseif judge.card:getSuit() == sgs.Card_Spade then
			room:broadcastSkillInvoke(self:objectName(), 5)
			if player:isWounded() then
				room:notifySkillInvoked(player, self:objectName())
				local recover = sgs.RecoverStruct()
					recover.recover = 1
					recover.who = player
				room:recover(player, recover)
				if player:faceUp() then
					player:turnOver()
				end
			else
				player:drawCards(1)
			end
		end
	end,
}
Mzhemo = sgs.CreateTriggerSkill{
	name = "Mzhemo",  
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirming},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local use = data:toCardUse()
			if use.card and use.from and use.card:isNDTrick() and use.to:contains(player) and use.from:hasShownOneGeneral() and not (player:isFriendWith(use.from) or player:willBeFriendWith(use.from)) and not player:isAllNude() then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local use = data:toCardUse()
		if not player:isAllNude() then
			local id = room:askForCardChosen(use.from, player, "hej", self:objectName())
			room:throwCard(id, player, use.from)
			player:drawCards(1)
			sgs.Room_cancelTarget(use, player)
			data:setValue(use)
			if player:inMyAttackRange(use.from) and use.from:isAlive() then
				if room:askForUseSlashTo(player, use.from, "@zhemo_slash") then
					room:broadcastSkillInvoke(self:objectName(), 2)
				else
					room:broadcastSkillInvoke(self:objectName(), 3)
				end
			end
		end
	end,
}
Mzhemo_effect = sgs.CreateTriggerSkill{
	name = "#Mzhemo_effect",  
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim},
	priority = -1,
	can_trigger = function(self, event, room, player, data)
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() and player:hasSkill("Mzhemo") then
			local damage = death.damage
			if damage and damage.from and not damage.from:hasSkill("Mshinue") then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(Mzhemo) or player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke("Mzhemo", 4)
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local death = data:toDeath()
		local damage = death.damage
		room:doLightbox("$zhemo", 2000)
		room:setPlayerMark(damage.from, "@zhemoget", 1)
		room:handleAcquireDetachSkills(damage.from, "Mshinue")
		room:getThread():delay(2000)
	end,
}
Mshinue = sgs.CreateTriggerSkill{
	name = "Mshinue",  
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirming},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local use = data:toCardUse()
			if use.card and use.from and use.to:contains(player) and use.card:isNDTrick() and use.from:objectName() ~= player:objectName() and not player:isAllNude() then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		room:broadcastSkillInvoke(self:objectName())
		room:notifySkillInvoked(player, self:objectName())
		return true
	end,
	on_effect = function(self,event,room,player,data)
		local use = data:toCardUse()
		if not player:isAllNude() then
			local id = room:askForCardChosen(use.from, player, "hej", self:objectName())
			room:throwCard(id, player, use.from)
			sgs.Room_cancelTarget(use, player)
			data:setValue(use)
		end
	end,
}
--加入技能“苦楚”“折磨”
Mlacerator:addSkill(Mkuchu)
Mlacerator:addSkill(Mzhemo)
Mlacerator:addSkill(Mzhemo_effect)
Ashan3:insertRelatedSkills("Mzhemo", "#Mzhemo_effect")
local skill=sgs.Sanguosha:getSkill("Mshinue")
if not skill then
	local skillList=sgs.SkillList()
	skillList:append(Mshinue)
	sgs.Sanguosha:addSkills(skillList)
end
--翻译表
sgs.LoadTranslationTable{
    ["Mlacerator"] = "刑魔",
	["&Mlacerator"] = "刑魔",
	["#Mlacerator"] = "残酷折磨",
	["Mkuchu"] = "苦楚",
	["$Mkuchu1"] = "碎裂吧！",
	["$Mkuchu2"] = "我们追求的就是不平衡。",
	["$Mkuchu3"] = "让我来扭转战局。",
	["$Mkuchu4"] = "悲痛送给你。",
	["$Mkuchu5"] = "不洁之物在聚集。",
	["@kuchu_invoke"] = "是否弃置一张牌发动“苦楚”？",
	[":Mkuchu"] = "当你对其他角色造成一次无属性伤害后，若其有手牌，你可以弃置一张牌进行一次判定：若结果为红桃，视为你对其使用了一张“决斗”；若结果为方块，你随机摸一到三张牌；若结果为梅花，对方弃置所有手牌然后摸一张牌；若结果为黑桃，若你已受伤，你回复1点体力并将你的武将牌叠置，否则你摸一张牌。",
	["Mzhemo"] = "折磨",
	["#Mzhemo_effect"] = "折磨",
	["$Mzhemo1"] = "将你抹去。",
	["$Mzhemo2"] = "折磨！",
	["$Mzhemo3"] = "该死！",
	["$Mzhemo4"] = "你和这个世界一样，终会被毁灭！",
	["$zhemo"] = "你和这个世界一样终会被毁灭！",
	["@zhemoget"] = "折磨获取",
	["@zhemo_slash"] = "是否对目标使用一张【杀】？",
	[":Mzhemo"] = "锁定技，当你被其他势力的角色指定为非延时锦囊的目标时，若你区域内有牌，你令其弃置你区域内一张牌，然后你摸一张牌并取消之：若此时该角色在你的攻击范围内，你可以对其使用一张【杀】。锁定技，杀死你的角色获得技能【施虐】。",
	["Mshinue"] = "施虐",
	["$Mshinue"] = "三倍的折磨。",
	[":Mshinue"] = "锁定技，当你被其他角色指定为非延时锦囊的目标时，若你区域内有牌，你令其弃置你区域内一张牌，然后你取消之。",
	["~Mlacerator"] = "我将回到人性最黑暗的深渊中。",
	["cv:Mlacerator"] = "受折磨的灵魂",
	["illustrator:Mlacerator"] = "英雄无敌6",
	["designer:Mlacerator"] = "月兔君",
}

--[[
   创建武将【暴魔】
]]--
Mravager = sgs.General(Ashan3, "Mravager", "an", 4)
--[[
*【暴行】锁定技，你根据X的大小你获得以下效果（X为已损失体力）：
	【X>0】锁定技，你的普通【杀】均视为【火杀】。
	【X>1】锁定技，当你使用【杀】指定目标后，你弃置其一张牌:此【杀】被【闪】抵消后，其摸一张牌，然后你将一张牌置于牌堆顶。
	【X>2】当你受到一次其他角色造成的伤害后，你可以摸一张牌并视为对伤害来源使用了一张【火杀】：若该【火杀】造成伤害，其无法使用基本牌直到其回合结束。
*【冲撞】主将技，出牌阶段开始前，若你手牌数大于体力，你可以弃置两张（不足则为全部）手牌指定一名距离1内的其他势力的角色：若其打出一张【闪】，你跳过出牌阶段；否则你与其交换位置并对其造成1点伤害。
*【嘲弄】副将技，锁定技，此武将牌上单独的阴阳鱼个数+1。副将技，当其他角色指定与你势力相同的其他角色为【杀】的目标时，若你在其攻击范围内，你可以展示一张基本牌并取消之：若如此做，其可以对你使用一张【杀】。
]]--
Mbaoxing_change = sgs.CreateFilterSkill{
    name = "#Mbaoxing_change",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local player = room:getCardOwner(to_select:getEffectiveId())
		if player and player:hasShownSkill(Mbaoxing) and player:isWounded() then
			return to_select:isKindOf("Slash") and not to_select:isKindOf("NatureSlash")
		end
	end,
	view_as = function(self, card)
	    local id = card:getId()
		local suit = card:getSuit()
		local point = card:getNumber()
		local peach = sgs.Sanguosha:cloneCard("fire_slash", suit, point)
		peach:setSkillName("Mbaoxing")
		local vs_card = sgs.Sanguosha:getWrappedCard(id)
		vs_card:takeOver(peach)
		return vs_card
	end,
}
Mbaoxing = sgs.CreateTriggerSkill{
	name = "Mbaoxing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetChosen, sgs.Damaged, sgs.SlashMissed, sgs.DamageComplete},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.TargetChosen then
			if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getLostHp() > 1 then
				local use = data:toCardUse()
				if use.card and use.card:isKindOf("Slash") then
					local targets_names = {}
					for _,p in sgs.qlist(use.to) do
						if not p:isNude() then
							table.insert(targets_names,p:objectName())
						end	
					end
					if #targets_names > 0 then
						return self:objectName() .. "->" .. table.concat(targets_names, "+"), player
					end
				end
			end
		elseif event == sgs.Damaged then
			if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getLostHp() > 2 then
				local damage = data:toDamage()
				if damage.from and damage.from:objectName() ~= player:objectName() then
					local slash = sgs.Sanguosha:cloneCard("fire_slash")
					slash:setSkillName(self:objectName())
					if player:canSlash(damage.from,slash,false) then
						return self:objectName(), player
					end
				end
			end
		elseif event == sgs.SlashMissed then
			if player and player:isAlive() and player:hasSkill(self:objectName()) and player:hasShownSkill(self) and player:getLostHp() > 1 then
				local effect = data:toSlashEffect()
				if effect.to and effect.to:isAlive() and effect.to:hasFlag("baoxing_target") then
					room:setPlayerFlag(effect.to, "-baoxing_target")
					room:notifySkillInvoked(player, self:objectName())
					effect.to:drawCards(1)
					if not player:isNude() then
						room:broadcastSkillInvoke(self:objectName(), 3)
						local id = room:askForExchange(player, self:objectName(), 1, 1, "baoxing_put", "", ""):getSubcards():first()
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(),"", self:objectName(), "")
						room:moveCardTo(sgs.Sanguosha:getCard(id), nil, nil, sgs.Player_DrawPile, reason, false)
					end
				end
			end
		else
			local damage = data:toDamage()
			if damage.to and damage.to:isAlive() and damage.to:hasFlag("baoxing_target") and damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName(false) == "baoxing_slash" and damage.to:getMark("baoxing") == 0 then
				room:setPlayerFlag(damage.to, "-baoxing_target")
				local ravager =  room:findPlayerBySkillName(self:objectName())
				if ravager and ravager:isAlive() and ravager:hasShownSkill(self) and ravager:getLostHp() > 2 then
					room:getThread():delay(1000)
					room:broadcastSkillInvoke(self:objectName(), 5)
					room:setPlayerCardLimitation(damage.to, "use", "BasicCard", true)
					room:setPlayerMark(damage.to, "@baoxing", 1)
					local log = sgs.LogMessage()
						log.type = "#baoxing"
						log.from = damage.to
					room:sendLog(log)
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, target, data, player)
		if event == sgs.TargetChosen then
			local ai_data = sgs.QVariant()
			ai_data:setValue(target)
			if player:hasShownSkill(self) or player:askForSkillInvoke("Mbaoxing1", ai_data) then
				room:notifySkillInvoked(player, self:objectName())
				return true
			end
		elseif event == sgs.Damaged then
			if player:askForSkillInvoke("Mbaoxing2", data) then
				room:notifySkillInvoked(player, self:objectName())
				return true
			end
		end
		return false
	end,
	on_effect = function(self, event, room, target, data, player)
		if event == sgs.TargetChosen then
			if target:isNude() then return false end
			room:broadcastSkillInvoke(self:objectName(), 2)
			local id = room:askForCardChosen(player, target, "he", self:objectName())
			room:throwCard(id, target, player)
		elseif event == sgs.Damaged then
			player:drawCards(1)
			local damage = data:toDamage()
			local slash = sgs.Sanguosha:cloneCard("fire_slash")
			slash:setSkillName("baoxing_slash")
			if player:canSlash(damage.from,slash,false) then
				room:broadcastSkillInvoke(self:objectName(), 4)
				room:setPlayerFlag(damage.from, "baoxing_target")
				local use = sgs.CardUseStruct()
					use.from = player
					use.to:append(damage.from)
					use.card = slash
				room:useCard(use, false)
			end
		end
	end,
}
Mbaoxing_avoid = sgs.CreateTriggerSkill{
	name = "#Mbaoxing_avoid",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:getMark("@baoxing") == 1 then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				room:setPlayerMark(player, "@baoxing", 0)
			end
		end
		return ""
	end,
}
Mravager:setDeputyMaxHpAdjustedValue(1)
Mchongzhuang = sgs.CreateTriggerSkill{
	name = "Mchongzhuang",
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseChanging},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local change = data:toPhaseChange() 
			if change.to == sgs.Player_Play and not player:isSkipped(sgs.Player_Play) and player:getHandcardNum() > player:getHp() then
				local targets = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasShownOneGeneral() and not (player:isFriendWith(p) or player:willBeFriendWith(p)) and player:distanceTo(p) == 1 then
						targets:append(p)
					end
				end
				if not targets:isEmpty() then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			if player:getHandcardNum() > 2 then
				room:askForDiscard(player, self:objectName(), 2, 2, false, false)
			else
				player:throwAllHandCards()
			end
			room:broadcastSkillInvoke(self:objectName(), 1)
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasShownOneGeneral() and not (player:isFriendWith(p) or player:willBeFriendWith(p)) and player:distanceTo(p) == 1 then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, self:objectName())
			if not room:askForCard(target, "Jink", "@chongzhuang_invoke", data, sgs.Card_MethodResponse) then
				room:getThread():delay(1000)
				room:broadcastSkillInvoke(self:objectName(), 2)
				local realtarget = getServerPlayer(room, target:objectName())
				if realtarget and realtarget:isAlive() then
					room:swapSeat(player, realtarget)
					local damage = sgs.DamageStruct()
						damage.damage = 1
						damage.from = player
						damage.to = target
					room:damage(damage)
				end
			else
				room:broadcastSkillInvoke(self:objectName(), 3)
				player:skip(sgs.Player_Play)
			end
		end
	end,
}
Mchaonong = sgs.CreateTriggerSkill{
	name = "Mchaonong",  
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirming},
	relate_to_place = "deputy",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.from then
			local ravager = room:findPlayerBySkillName(self:objectName())
			if ravager and ravager:isAlive() and use.to:contains(player) and not ravager:isKongcheng() and use.from:objectName() ~= player:objectName() and use.from:objectName() ~= ravager:objectName() and ravager:objectName() ~= player:objectName() and player:hasShownOneGeneral() and (ravager:isFriendWith(player) or ravager:willBeFriendWith(player)) and use.from:inMyAttackRange(ravager) then
				return self:objectName(), ravager
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		local ravager = room:findPlayerBySkillName(self:objectName())
		local card = room:askForCard(ravager, "BasicCard", "@chaonong_invoke", data, sgs.Card_MethodNone)
		if card then
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(ravager, self:objectName())
			room:showCard(ravager, card:getId())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local ravager = room:findPlayerBySkillName(self:objectName())
		local use = data:toCardUse()
		sgs.Room_cancelTarget(use, player)
		data:setValue(use)
		room:askForUseSlashTo(use.from, ravager, "@chaonong_slash")
	end,
}
--加入技能“暴行”“冲撞”“嘲弄”
Mravager:addSkill(Mbaoxing)
Mravager:addSkill(Mbaoxing_change)
Mravager:addSkill(Mbaoxing_avoid)
Mravager:addSkill(Mchongzhuang)
Mravager:addSkill(Mchaonong)
Ashan3:insertRelatedSkills("Mbaoxing", "#Mbaoxing_change")
Ashan3:insertRelatedSkills("Mbaoxing", "#Mbaoxing_avoid")
--翻译表
sgs.LoadTranslationTable{
    ["Mravager"] = "暴魔",
	["&Mravager"] = "暴魔",
	["#Mravager"] = "嗜血战魔",
	["Mbaoxing"] = "暴行",
	["Mbaoxing1"] = "暴行",
	["Mbaoxing2"] = "暴行",
	["#Mbaoxing_change"] = "暴行",
	["#Mbaoxing_avoid"] = "暴行",
	["baoxing_slash"] = "暴行",
	["baoxing_put"] = "请将你的一张手牌置于牌堆顶。",
	["$Mbaoxing1"] = "（狂笑）",
	["$Mbaoxing2"] = "尝尝这个！",
	["$Mbaoxing3"] = "有种来战！",
	["$Mbaoxing4"] = "继续劈斩，继续咆哮！",
	["$Mbaoxing5"] = "休想得到任何东西！",
	["#baoxing"] = "%from 无法使用基本牌直到其回合结束。",
	[":Mbaoxing"] = "锁定技，你根据X的大小你获得以下效果（X为已损失体力）：\n【X>0】\n锁定技，你的普通【杀】均视为【火杀】。\n【X>1】\n锁定技，当你使用【杀】指定目标后，你弃置其一张牌:此【杀】被【闪】抵消后，其摸一张牌，然后你将一张牌置于牌堆顶。\n【X>2】\n当你受到一次其他角色造成的伤害后，你可以摸一张牌并视为对伤害来源使用了一张【火杀】：若该【火杀】造成伤害，其无法使用基本牌直到其回合结束。",
	["Mchongzhuang"] = "冲撞",
	["@chongzhuang_invoke"] = "请打出一张【闪】否则将受到冲撞！",
	["$Mchongzhuang1"] = "全都得死，你是第一个。",
	["$Mchongzhuang2"] = "这样终结你。",
	["$Mchongzhuang3"] = "判断失误了！",
	[":Mchongzhuang"] = "主将技，出牌阶段开始前，若你手牌数大于体力，你可以弃置两张（不足则为全部）手牌指定一名距离1内的其他势力的角色：若其打出一张【闪】，你跳过出牌阶段；否则你与其交换位置并对其造成1点伤害。",
	["Mchaonong"] = "嘲弄",
	["@chaonong_invoke"] = "是否展示一张基本牌取消该【杀】？",
	["@chaonong_slash"] = "你可以对暴魔使用一张【杀】。",
	["$Mchaonong"] = "真能废话，我还没打够！",
	[":Mchaonong"] = "副将技，锁定技，此武将牌上单独的阴阳鱼个数+1。副将技，当其他角色指定与你势力相同的其他角色为【杀】的目标时，若你在其攻击范围内且你有手牌，你可以展示一张基本牌并取消之：若如此做，其可以对你使用一张【杀】。",
	["~Mravager"] = "最残酷的斩杀……",
	["cv:Mravager"] = "斧王",
	["illustrator:Mravager"] = "英雄无敌6",
	["designer:Mravager"] = "月兔君",
}

--[[
   创建武将【深渊领主】
]]--
Mpitlord = sgs.General(Ashan3, "Mpitlord", "an", 4)
--[[
*【睚眦】当你受到其他角色使用【杀】造成的伤害后，你可以将牌堆顶一张牌置于其武将牌上称为“睚眦”。当你使用【杀】对其他角色造成一次伤害时，若其有“睚眦”牌，你可以展示牌堆顶上一张牌：若点数小于任意一张“睚眦”，你获得该牌；若点数大于任意一张“睚眦”，该伤害+1。锁定技，其他角色每有一张“睚眦”牌，你与其的距离-1。
*【仇怨】主将技，限定技，出牌阶段结束时，若你于此阶段内未造成伤害且场上有大于一张“睚眦”，你可以视为对有“睚眦”的其他势力角色使用了一张【火杀】，然后弃置场上所有的“睚眦”并将手牌补充至体力上限。
*【杀戮】副将技，当一名有“睚眦”的角色死亡时，你可以将手牌补充至体力上限并获得所有的“睚眦”牌。
]]--
Myazi = sgs.CreateTriggerSkill{
	name = "Myazi",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damaged, sgs.DamageCaused},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		local damage = data:toDamage()
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if event == sgs.Damaged then
				if damage.card and damage.card:isKindOf("Slash") and damage.from and damage.from:objectName() ~= player:objectName() and damage.from:isAlive() then
					return self:objectName()
				end
			else
				if damage.card and damage.card:isKindOf("Slash") and damage.from and damage.to:objectName() ~= player:objectName() and damage.to:isAlive() then
					local yazipile = damage.to:getPile("yazi")
					if yazipile:length() > 0 then
						return self:objectName()
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if event == sgs.Damaged then
			if player:askForSkillInvoke("Myazi1", data) then
				room:broadcastSkillInvoke(self:objectName(), 1)
				return true
			end
		else
			if player:askForSkillInvoke("Myazi2", data) then
				room:broadcastSkillInvoke(self:objectName(), 2)
				return true
			end
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local damage = data:toDamage()
		if event == sgs.Damaged then
			local card_id = room:drawCard()
			local card = sgs.Sanguosha:getCard(card_id)
			damage.from:addToPile("yazi", card)
		else
			local yazipile = damage.to:getPile("yazi")
			local card_id = room:drawCard()
			local card = sgs.Sanguosha:getCard(card_id)
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SHOW, player:objectName(), "", self:objectName(), "")
			room:moveCardTo(card, player, sgs.Player_PlaceTable, reason, true)
			room:getThread():delay(1000)
			local bigger, smaller
			for _,cd in sgs.qlist(yazipile) do
				if sgs.Sanguosha:getCard(cd):getNumber() > card:getNumber() then
					smaller = true
				end
				if sgs.Sanguosha:getCard(cd):getNumber() < card:getNumber() then
					bigger = true
				end
			end
			local x = 0
			if smaller then
				player:obtainCard(card, true)
				x = x+1
			end
			if bigger then
				local log = sgs.LogMessage()
					log.type = "#DamageMore"
					log.from = player
					log.arg = self:objectName()
				room:sendLog(log)
				damage.damage = damage.damage + 1
				data:setValue(damage)
				x = x+1
			end
			if x == 0 then
				room:broadcastSkillInvoke(self:objectName(), 3)
			elseif x == 1 then
				room:broadcastSkillInvoke(self:objectName(), 4)
			else
				room:broadcastSkillInvoke(self:objectName(), 5)
			end
		end
	end,
}
Myazi_close = sgs.CreateDistanceSkill{
	name = "#Myazi_close",
	correct_func = function(self, from, to)
	    if from:hasSkill("Myazi") and from:hasShownSkill(Myazi) then
			local x = to:getPile("yazi"):length()
			if x > 0 then
				return -x
			end
		end
	end,
}
Mchouyuan = sgs.CreateTriggerSkill{
	name = "Mchouyuan", 
	frequency = sgs.Skill_Limited,
	limit_mark = "@chouyuan_use",
	events = {sgs.EventPhaseEnd, sgs.Damage},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getMark("@chouyuan_use") == 0 then return "" end
			if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
				if player:hasFlag("chouyuan_hurt") then
					room:setPlayerFlag(player, "-chouyuan_hurt")
				else
					if player:hasEquip() then
						local slash = sgs.Sanguosha:cloneCard("fire_slash")
						slash:setSkillName(self:objectName())
						local targets = sgs.SPlayerList()
						local very_hate
						for _,p in sgs.qlist(room:getOtherPlayers(player)) do
							if p:hasShownOneGeneral() and not (player:isFriendWith(p) or player:willBeFriendWith(p)) and p:getPile("yazi"):length() > 0 and player:canSlash(p,slash,false) then
								targets:append(p)
								if p:getPile("yazi"):length() > 1 then
									very_hate = true
								end
							end
						end
						if targets:length() > 1 or very_hate then
							return self:objectName()
						end
					end
				end
			else
				if player:getPhase() == sgs.Player_Play and not player:hasFlag("chouyuan_hurt") then
				    room:setPlayerFlag(player, "chouyuan_hurt")
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:setPlayerMark(player,"@chouyuan_use", 0)
			room:broadcastSkillInvoke(self:objectName())
			room:doSuperLightbox("Mpitlord", self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local slash = sgs.Sanguosha:cloneCard("fire_slash")
		slash:setSkillName(self:objectName())
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasShownOneGeneral() and not (player:isFriendWith(p) or player:willBeFriendWith(p)) and p:getPile("yazi"):length() > 0 and player:canSlash(p,slash,false) then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local use = sgs.CardUseStruct()
				use.from = player
				use.card = slash
				use.to = targets
			room:useCard(use, false)
		end
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getPile("yazi"):length() > 0 then
				p:clearOnePrivatePile("yazi")
			end
		end
		local x = player:getMaxHp() - player:getHandcardNum()
		if x > 0 then
			player:drawCards(x)
		end
	end,
}
Mshalu = sgs.CreateTriggerSkill{
	name = "Mshalu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Death},
	relate_to_place = "deputy",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then
				if death.who:getPile("yazi"):length() > 0 and player:getHandcardNum() < player:getMaxHp() then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local death = data:toDeath()
		local yazipile = death.who:getPile("yazi")
		if yazipile:length() > 0 then
			local x = player:getMaxHp() - player:getHandcardNum()
			if x > 0 then
				player:drawCards(x)
			end
			local emptycard = MemptyCard:clone()
			for _, id in sgs.qlist(yazipile) do
				emptycard:addSubcard(sgs.Sanguosha:getCard(id))
			end
			player:obtainCard(emptycard, true)
		end
	end,
}
--加入技能“睚眦”“仇怨”
Mpitlord:addSkill(Myazi)
Mpitlord:addSkill(Myazi_close)
Mpitlord:addSkill(Mchouyuan)
Mpitlord:addSkill(Mshalu)
Ashan3:insertRelatedSkills("Myazi", "#Myazi_close")
--翻译表
sgs.LoadTranslationTable{
    ["Mpitlord"] = "深渊领主",
	["&Mpitlord"] = "深渊领主",
	["#Mpitlord"] = "残暴化身",
	["Myazi"] = "睚眦",
	["Myazi1"] = "睚眦",
	["Myazi2"] = "睚眦",
	["#Myazi_close"] = "睚眦",
	["yazi"] = "睚眦",
	["$Myazi1"] = "无需千刀万剐。",
	["$Myazi2"] = "我要让你生不如死。",
	["$Myazi3"] = "运气太差。",
	["$Myazi4"] = "刀刀见血。",
	["$Myazi5"] = "开膛破肚。",
	[":Myazi"] = "当你受到其他角色使用【杀】造成的伤害后，你可以将牌堆顶一张牌置于其武将牌上称为“睚眦”。当你使用【杀】对其他角色造成一次伤害时，若其有“睚眦”牌，你可以展示牌堆顶上一张牌：若点数小于任意一张“睚眦”，你获得该牌；若点数大于任意一张“睚眦”，该伤害+1。锁定技，其他角色每有一张“睚眦”牌，你与其的距离-1。",
	["Mchouyuan"] = "仇怨",
	["@chouyuan_use"] = "仇怨使用",
	["$Mchouyuan"] = "罪恶之债，全额支付！",
	[":Mchouyuan"] = "主将技，限定技，出牌阶段结束时，若你于此阶段内未造成伤害且场上有大于一张“睚眦”，你可以视为对有“睚眦”的其他势力角色使用了一张【火杀】，然后弃置场上所有的“睚眦”并将手牌补充至体力上限。",
	["Mshalu"] = "杀戮",
	["$Mshalu"] = "我撕开你的喉咙，只为闭上你的双眼。",
	[":Mshalu"] = "副将技，当一名有“睚眦”的角色死亡时，你可以将手牌补充至体力上限并获得所有的“睚眦”牌。",
	["~Mpitlord"] = "七大丧钟为我而鸣！",
	["cv:Mpitlord"] = "恐怖利刃",
	["illustrator:Mpitlord"] = "英雄无敌6",
	["designer:Mpitlord"] = "月兔君",
}

--[[
   创建武将【阿兹卡尔】
]]--
Mazkaal = sgs.General(Ashan3, "Mazkaal", "an", 4)
--[[
*【敌意】锁定技，当你受到其他角色造成的一次伤害后，该角色获得“恨”标记直到你的回合结束。锁定技，当你对拥有“恨”标记的角色造成一次火属性伤害时，该伤害+1。锁定技，当拥有“恨”标记的角色对你造成一次伤害时，该伤害无效。锁定技，你与拥有“恨”标记的角色距离锁定为1。
*【湮没】主将技，弃牌阶段开始前，若你装备区不为空，你可以弃置装备区所有牌并跳过弃牌阶段，你距离X内的其他势力角色须弃置一张装备牌否则受到你造成的1点火属性伤害（X为你弃置的牌的数目）。
*【毁灭】副将技，摸牌阶段开始前，若你的手牌中有【杀】，你可以展示手牌并跳过摸牌阶段，指定一名攻击范围内的有手牌的其他角色并展示其一张手牌：若为基本牌，该角色失去1点体力；否则该角色和你各摸一张牌。
]]--
Mdiyi = sgs.CreateTriggerSkill{
	name = "Mdiyi",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damaged, sgs.DamageCaused, sgs.DamageInflicted, sgs.EventPhaseChanging},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if event == sgs.Damaged then
				local damage = data:toDamage()
				if damage.from and damage.from:isAlive() and damage.from:objectName() ~= player:objectName() and damage.from:getMark("@diyi") == 0 then
					return self:objectName()
				end
			elseif event == sgs.DamageCaused then
				local damage = data:toDamage()
				if damage.to:getMark("@diyi") == 1 and damage.nature == sgs.DamageStruct_Fire then
					return self:objectName()
				end
			elseif event == sgs.DamageInflicted then
				local damage = data:toDamage()
				if damage.from and damage.from:isAlive() and damage.from:getMark("@diyi") == 1 then
					return self:objectName()
				end
			else
				local change = data:toPhaseChange() 
				if change.to == sgs.Player_NotActive then
					for _,p in sgs.list(room:getOtherPlayers(player)) do
						if p:getMark("@diyi") == 1 then
							room:setPlayerMark(p,"@diyi", 0)
							room:setFixedDistance(player, p, -1)
						end
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if event == sgs.Damaged then
			if player:hasShownSkill(Mdiyi) or player:askForSkillInvoke("Mdiyi1", data) then
				return true
			end
		elseif event == sgs.DamageCaused then
			if player:hasShownSkill(Mdiyi) or player:askForSkillInvoke("Mdiyi2", data) then
				return true
			end
		else
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:notifySkillInvoked(player, self:objectName())
			room:setPlayerMark(damage.from, "@diyi", 1)
			room:setFixedDistance(player, damage.from, 1)
			local log = sgs.LogMessage()
				log.type = "#diyi1"
				log.from = player
				log.to:append(damage.from)
				log.arg = self:objectName()
			room:sendLog(log)
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			room:broadcastSkillInvoke(self:objectName(), 2)
			room:notifySkillInvoked(player, self:objectName())
			local log = sgs.LogMessage()
				log.type = "#DamageMore"
				log.from = player
				log.arg = self:objectName()
			room:sendLog(log)
			damage.damage = damage.damage + 1
			data:setValue(damage)
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.from and damage.from:isAlive() then
				room:broadcastSkillInvoke(self:objectName(), 3)
				room:notifySkillInvoked(player, self:objectName())
				local log = sgs.LogMessage()
					log.type = "#diyi2"
					log.from = player
					log.arg = self:objectName()
				room:sendLog(log)
				return true
			end
		end
	end,
}
Myanmo = sgs.CreateTriggerSkill{
	name = "Myanmo", 
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Discard and not player:isSkipped(sgs.Player_Discard) then
				if player:hasEquip() then
					local x = player:getEquips():length()
					local targets = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:hasShownOneGeneral() and not (player:isFriendWith(p) or player:willBeFriendWith(p)) and player:distanceTo(p) <= x and player:distanceTo(p) ~= -1 then
							targets:append(p)
						end
					end
					if not targets:isEmpty() then
						return self:objectName()
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			player:skip(sgs.Player_Discard)
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local x = player:getEquips():length()
		player:throwAllEquips()
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasShownOneGeneral() and not (player:isFriendWith(p) or player:willBeFriendWith(p)) and player:distanceTo(p) <= x and player:distanceTo(p) ~= -1 then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			for _,p in sgs.qlist(targets) do
				local equip
				for _,cd in sgs.qlist(p:getCards("he")) do
					if cd:isKindOf("EquipCard") then
						equip = true
						break
					end
				end
				local invoke
				if equip then
					local ai_data = sgs.QVariant()
					ai_data:setValue(player)
					if not room:askForCard(p, "EquipCard", "@yanmo_invoke", ai_data, sgs.Card_MethodDiscard) then
						invoke = true
					end
				else
					invoke = true
				end
				room:getThread():delay(1000)
				if invoke then
					room:broadcastSkillInvoke(self:objectName(), 2)
					local damage = sgs.DamageStruct()
						damage.from = player
						damage.damage = 1
						damage.nature = sgs.DamageStruct_Fire
						damage.to = p
					room:damage(damage)
				else
					room:broadcastSkillInvoke(self:objectName(), 3)
				end
			end
		end
	end,
}
Mhuimie = sgs.CreateTriggerSkill{
	name = "Mhuimie", 
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging},
	relate_to_place = "deputy",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local change = data:toPhaseChange()
			if not player:isKongcheng() and change.to == sgs.Player_Draw and not player:isSkipped(sgs.Player_Draw) then
				local has_slash
				for _, card in sgs.qlist(player:getHandcards()) do
					if card:isKindOf("Slash") then
						has_slash = true
						break
					end
				end
				if has_slash then
					local targets = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if player:inMyAttackRange(p) and not p:isKongcheng() then
							targets:append(p)
						end
					end
					if not targets:isEmpty() then
						return self:objectName()
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:showAllCards(player)
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		player:skip(sgs.Player_Draw)
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:inMyAttackRange(p) and not p:isKongcheng() then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, self:objectName())
			local id = room:askForCardChosen(player, target, "h", self:objectName())
			room:showCard(target, id)
			local realcard = sgs.Sanguosha:getWrappedCard(id)
			room:getThread():delay(1000)
			if realcard:isKindOf("BasicCard") then
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:loseHp(target, 1)
			else
				room:broadcastSkillInvoke(self:objectName(), 3)
				target:drawCards(1)
				player:drawCards(1)
			end
		end
	end,
}
--加入技能“敌意”“湮没”“毁灭”
Mazkaal:addSkill(Mdiyi)
Mazkaal:addSkill(Myanmo)
Mazkaal:addSkill(Mhuimie)
--翻译表
sgs.LoadTranslationTable{
    ["Mazkaal"] = "阿兹卡尔",
	["&Mazkaal"] = "阿兹卡尔",
	["#Mazkaal"] = "毁灭亲王",
	["Mdiyi"] = "敌意",
	["Mdiyi1"] = "敌意",
	["Mdiyi2"] = "敌意",
	["@diyi"] = "恨",
	["$Mdiyi1"] = "你，会被打入地狱深处！",
	["$Mdiyi2"] = "炼狱，取你性命！",
	["$Mdiyi3"] = "三元恶魔齐聚。",
	["#diyi1"] = "由于 %arg 的效果，%from 与 %to 距离锁定为1直到 %from 的回合结束。",
	["#diyi2"] = "由于 %arg 的效果，%from 受到的伤害无效！",
	[":Mdiyi"] = "锁定技，当你受到其他角色造成的一次伤害后，该角色获得“恨”标记直到你的回合结束。锁定技，当你对拥有“恨”标记的角色造成一次火属性伤害时，该伤害+1。锁定技，当拥有“恨”标记的角色对你造成一次伤害时，该伤害无效。锁定技，你与拥有“恨”标记的角色距离锁定为1。",
	["Myanmo"] = "湮没",
	["$Myanmo1"] = "火焰，席卷大地！",
	["$Myanmo2"] = "杀完，再焚尸！",
	["$Myanmo3"] = "亵渎！",
	["@yanmo_invoke"] = "请弃置一张装备牌否则受到1点火属性伤害。",
	[":Myanmo"] = "主将技，弃牌阶段开始前，若你装备区不为空，你可以弃置装备区所有牌并跳过弃牌阶段，你距离X内的其他势力角色须弃置一张装备牌否则受到你造成的1点火属性伤害（X为你弃置的牌的数目）。",
	["Mhuimie"] = "毁灭",
	["$Mhuimie1"] = "你的末日到了！",
	["$Mhuimie2"] = "撕裂你的咽喉。",
	["$Mhuimie3"] = "为未来投资。",
	["@huimie_slash"] = "请对自己使用一张【杀】否则失去1点体力。",
	[":Mhuimie"] = "副将技，摸牌阶段开始前，若你的手牌中有【杀】，你可以展示手牌并跳过摸牌阶段，指定一名攻击范围内的有手牌的其他角色并展示其一张手牌：若为基本牌，该角色失去1点体力；否则该角色和你各摸一张牌。",
	["~Mazkaal"] = "地狱在召唤我。",
	["cv:Mazkaal"] = "末日守卫",
	["illustrator:Mazkaal"] = "英雄无敌6",
	["designer:Mazkaal"] = "月兔君",
}

--[[
   创建武将【鄂加斯】
]]--
Murcash = sgs.General(Ashan3, "Murcash", "an", 4)
lord_Murcash = sgs.General(Ashan3, "lord_Murcash$", "an", 4, true, true)
--非君主时珠联璧合：阿兹卡尔
Murcash:addCompanion("Mazkaal")
--[[
*【混沌】君主技，锁定技，你拥有“混沌之鳞”。
“混沌之鳞”锁定技，当与你势力相同的一名角色被其他势力的角色指定为基本牌或非延时锦囊的唯一的目标时，若其没有“混沌”，其亮出牌堆顶的一张牌：若两牌的类型相同，则取消之并置于弃牌堆；否则将此牌置于其武将牌上称为“混沌”。锁定技，有“混沌”的角色准备阶段结束时，若其已受伤，其获得该“混沌”并摸X张牌（X为其已损失体力且最大为2），否则其将“混沌”置于弃牌堆。
*【循环】当你杀死一名角色后，你可以获得其一个非锁定技能（君主技除外）。其他角色准备阶段结束时，若其有未展示的武将，你可以弃置一张锦囊牌令其展示一名武将：若其与你势力相同，你摸两张牌然后其摸一张牌；否则其弃置两张手牌然后你摸一张牌。
]]--
Mhundun = sgs.CreateTriggerSkill{
	name = "Mhundun$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirming, sgs.EventPhaseEnd},
	can_preshow = false,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.TargetConfirming then
			if not player:hasShownOneGeneral() then return "" end
			local use = data:toCardUse()
			if use.from and use.card and (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) and not use.from:isFriendWith(player) and use.to:length() == 1 and use.to:contains(player) then
				local hundunpile = player:getPile("hundun")
				if hundunpile:length() == 0 then
					local urcash
					for _,p in sgs.qlist(room:getAlivePlayers()) do
						if p:hasSkill(self:objectName()) and p:hasShownSkill(self) and p:getRole() ~= "careerist" then
							urcash = p
							break
						end
					end
					if urcash and urcash:isAlive() and player:isFriendWith(urcash) then
						return self:objectName(), urcash
					end
				end
			end
		else
			if player and player:isAlive() and player:getPhase() == sgs.Player_Start and player:isWounded() then
				local hundunpile = player:getPile("hundun")
				if hundunpile:length() == 0 then return "" end
				local urcash
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if player:isFriendWith(p) and p:hasSkill(self:objectName()) and p:hasShownSkill(self) and p:getRole() ~= "careerist" then
						urcash = p
						break
					end
				end
				if urcash and urcash:isAlive() then
					return self:objectName(), urcash
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		return true
	end,
	on_effect = function(self,event,room,player,data)
		if event == sgs.TargetConfirming then
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:notifySkillInvoked(player, self:objectName())
			local use = data:toCardUse()
			local card = sgs.Sanguosha:getCard(room:drawCard())
			room:moveCardTo(card, nil, nil, sgs.Player_PlaceTable,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(),"", self:objectName(), ""), true)
			room:getThread():delay(1000)
			if (card:isKindOf("BasicCard") and use.card:isKindOf("BasicCard")) or (card:isKindOf("TrickCard") and use.card:isKindOf("TrickCard")) then
				room:broadcastSkillInvoke(self:objectName(), 2)
				sgs.Room_cancelTarget(use, player)
				data:setValue(use)
				room:throwCard(card, player)
			else
				room:broadcastSkillInvoke(self:objectName(), 3)
				player:addToPile("hundun", card)
			end
		else
			local hundunpile = player:getPile("hundun")
			if hundunpile:length() == 0 then return "" end
			if player:isWounded() then
				room:broadcastSkillInvoke(self:objectName(), 4)
				room:notifySkillInvoked(player, self:objectName())
				local emptycard = MemptyCard:clone()
				for _,id in sgs.qlist(hundunpile) do
					emptycard:addSubcard(sgs.Sanguosha:getCard(id))
				end
				player:obtainCard(emptycard, true)
				if player:isWounded() then
					local x = math.min(2, player:getLostHp())
					player:drawCards(x)
				end
			else
				room:broadcastSkillInvoke(self:objectName(), 5)
				player:clearOnePrivatePile("hundun")
			end
		end
	end,
}
Mxunhuan = sgs.CreateTriggerSkill{
	name = "Mxunhuan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.BuryVictim, sgs.EventPhaseEnd},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.BuryVictim then
			local death = data:toDeath()
			local damage = death.damage
			if player:objectName() == death.who:objectName() and damage then
				if damage.from and damage.from:hasSkill(self:objectName()) then
					local skill_list = {}
					for _,skill in sgs.qlist(player:getVisibleSkillList()) do
						if not (table.contains(skill_list, skill:objectName()) or skill:isLordSkill() or skill:isAttachedLordSkill()) then
--							if skill:canPreshow() and not damage.from:hasSkill(skill) and not ((skill:relateToPlace(true) or skill:relateToPlace(false))) then
							if skill:getFrequency() ~= sgs.Skill_Compulsory and not damage.from:hasSkill(skill) then
								table.insert(skill_list, skill:objectName())
							end
						end
					end
					local skill_xh
					if #skill_list > 1 then
						return self:objectName(), damage.from
					end
				end
			end
		else
			if player:getPhase() == sgs.Player_Start and not player:hasShownAllGenerals() then
				local urcash = room:findPlayerBySkillName(self:objectName())
				if urcash and urcash:isAlive() and not urcash:isKongcheng() and urcash:objectName() ~= player:objectName() then
					local trick
					for _, card in sgs.qlist(urcash:getHandcards()) do
						if card:isKindOf("TrickCard") then
							trick = true
							break
						end
					end
					if trick then
						return self:objectName(), urcash
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if event == sgs.BuryVictim then
			local damage = data:toDeath().damage
			if damage.from:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:doSuperLightbox("Murcash", self:objectName())
				return true
			end
		else
			if not player:hasShownAllGenerals() then
				local ai_data = sgs.QVariant()
				ai_data:setValue(player)
				local urcash = room:findPlayerBySkillName(self:objectName())
				if room:askForCard(urcash, "TrickCard|.|.|hand", "@xunhuan_invoke", ai_data, sgs.Card_MethodDiscard) then
					room:broadcastSkillInvoke(self:objectName(), 2)
					return true
				end
			end
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		if event == sgs.BuryVictim then
			local damage = data:toDeath().damage
			local skill_list = {}
			for _,skill in sgs.qlist(player:getVisibleSkillList()) do
				if not (table.contains(skill_list, skill:objectName()) or skill:isLordSkill() or skill:isAttachedLordSkill()) then
					if skill:getFrequency() ~= sgs.Skill_Compulsory and not damage.from:hasSkill(skill) then
--					if not damage.from:hasSkill(skill) then
						table.insert(skill_list, skill:objectName())
					end
				end
			end
			local skill_xh
			if #skill_list > 1 then
				skill_xh = room:askForChoice(damage.from, self:objectName(), table.concat(skill_list, "+"), data)
			else
				skill_xh = skill_list[1]
			end
			if skill_xh then
				room:handleAcquireDetachSkills(damage.from, skill_xh)
				local realtarget = getServerPlayer(room, damage.from:objectName())
				realtarget:setSkillPreshowed(skill_xh)
			end
		else
			local urcash = room:findPlayerBySkillName(self:objectName())
			if not player:hasShownGeneral1() then
				if not player:hasShownGeneral2() then
					choice = room:askForChoice(player, self:objectName(), "xunhuan_1+xunhuan_2", data)
				else
					choice = "xunhuan_1"
				end
			else
				choice = "xunhuan_2"
			end
			if choice == "xunhuan_1" then
				player:showGeneral(true)
			else
				player:showGeneral(false)
			end
			room:getThread():delay(1000)
			if player:isFriendWith(urcash) then
				room:broadcastSkillInvoke(self:objectName(), 3)
				urcash:drawCards(2)
				player:drawCards(1)
			else
				if not player:isKongcheng() then
					room:broadcastSkillInvoke(self:objectName(), 4)
					if player:getHandcardNum() <= 2 then
						player:throwAllHandCards()
					else
						room:askForDiscard(player, self:objectName(), 2, 2, false, false)
					end
				end
				urcash:drawCards(1)
			end
		end
	end,
}
--武将加入技能“混沌”“循环”
Murcash:addSkill(Mxunhuan)
lord_Murcash:addSkill(Mhundun)
lord_Murcash:addSkill(Mxunhuan)
--武将注释
sgs.LoadTranslationTable{
    ["Murcash"] = "鄂加斯",
	["&Murcash"] = "鄂加斯",
	["#Murcash"] = "混沌之龙",
	["lord_Murcash"] = "鄂加斯",
	["&lord_Murcash"] = "鄂加斯",
	["#lord_Murcash"] = "混沌之龙",
	["Mhundun"] = "混沌",
	["hundun"] = "混沌",
	["#hundun"] = "由于 %from 的效果，%from 增加了1点体力上限。",
	["$Mhundun1"] = "我会尽力帮助我软弱渺小的盟友。",
	["$Mhundun2"] = "不朽之守护！",
	["$Mhundun3"] = "有本事就逃。",
	["$Mhundun4"] = "琐碎的供奉。",
	["$Mhundun5"] = "快点上供！",
	[":Mhundun"] = "君主技，锁定技，你拥有“混沌之鳞”。\n\n“混沌之鳞”\n锁定技，当与你势力相同的一名角色被其他势力的角色指定为基本牌或非延时锦囊的唯一的目标时，若其没有“混沌”，其亮出牌堆顶的一张牌：若两牌的类型相同，则取消之并置于弃牌堆；否则将此牌置于其武将牌上称为“混沌”。锁定技，与你势力相同的角色准备阶段结束时，若其已受伤并有“混沌”，其获得该“混沌”并摸X张牌（X为其已损失体力且最大为2），否则其将“混沌”置于弃牌堆。",
	["Mxunhuan"] = "循环",
	["xunhuan_1"] = "展示主将",
	["xunhuan_2"] = "展示副将",
	["$Mxunhuan1"] = "全都归我！",
	["$Mxunhuan2"] = "给我跪下，平民！",
	["$Mxunhuan3"] = "你是我的臣民！",
	["$Mxunhuan4"] = "叛乱已镇压！",
	["@xunhuan_invoke"] = "是否弃置一张锦囊牌发动技能“循环”？",
	[":Mxunhuan"] = "当你杀死一名角色后，你可以获得其一个非锁定技能（君主技除外）。其他角色准备阶段结束时，若其有未展示的武将，你可以弃置一张锦囊牌令其展示一名武将：若其与你势力相同，你摸两张牌然后其摸一张牌；否则其弃置两张手牌然后你摸一张牌。",
	["~Murcash"] = "所以这就是结局？",
	["cv:Murcash"] = "骷髅王",
	["illustrator:Murcash"] = "英雄无敌6",
	["designer:Murcash"] = "月兔君",
	["cv:lord_Murcash"] = "骷髅王",
	["illustrator:lord_Murcash"] = "英雄无敌6",
	["designer:lord_Murcash"] = "月兔君",
}

return {Ashan3}