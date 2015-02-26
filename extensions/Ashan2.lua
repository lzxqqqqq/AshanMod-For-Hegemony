--[[********************************************
    这是 忧郁の月兔 制作的【英雄无敌Ⅵ-亚山之殇】
]]--********************************************

--[[
    创建拓展包“亚山之殇-秘”
]]--
Ashan2 = sgs.Package("Ashan2", sgs.Package_GeneralPack)

sgs.LoadTranslationTable{
    ["Ashan2"] = "亚山之殇-秘",
}

--[[[******************
    创建架空势力【秘】
]]--[******************
do
    require  "lua.config" 
	local config = config
	local kingdoms = config.kingdoms
            table.insert(kingdoms,"mi")
	config.color_de = "#F5F5DC"
end
sgs.LoadTranslationTable{
	["mi"] = "秘",
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
    创建种族【瀛洲】
]]--******************

--[[
   创建武将【鳄鲛】
]]--
Mwanizame = sgs.General(Ashan2, "Mwanizame", "mi", 4)
--珠联璧合：圣麒麟
Mwanizame:addCompanion("Mkirin")
--[[
【致残】锁定技，当你使用【杀】对目标角色造成一次伤害后，若其没有“致残”标记，其获得“致残”标记。锁定技，其他角色与拥有“致残”标记的角色的距离+2。锁定技，拥有“致残”标记的角色回合结束时，移除其“致残”标记。
*【残暴】主将技，锁定技，此武将牌上单独的阴阳鱼个数-1。主将技，锁定技，当你使用【杀】对目标角色造成伤害时，若其手牌数不大于1，此伤害+1。
*【创伤】副将技，锁定技，拥有“致残”标记的角色出牌阶段结束时，若其已受伤，其弃置一张手牌。
]]--
Mzhican = sgs.CreateTriggerSkill{
	name = "Mzhican", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damage},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if damage.to:isAlive() then
			    if damage.card and damage.card:isKindOf("Slash") and not (damage.chain or damage.transfer) and damage.to:getMark("@zhican") == 0 then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self) or room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local damage = data:toDamage()
		room:setPlayerMark(damage.to, "@zhican", 1)
		local log = sgs.LogMessage()
	        log.type = "#zhican1"
		    log.from = damage.to
		room:sendLog(log)
	end,
}
Mzhican_recover = sgs.CreateTriggerSkill{
	name = "#Mzhican_recover", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseChanging},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:getMark("@zhican") == 1 then
				room:broadcastSkillInvoke("Mzhican", 2)
				room:setPlayerMark(player, "@zhican", 0)
				local log = sgs.LogMessage()
					log.type = "#zhican2"
					log.from = player
				room:sendLog(log)
			end
		end
		return ""
	end,
}
Mzhican_far = sgs.CreateDistanceSkill{
	name = "#Mzhican_far",
	correct_func = function(self, from, to)
		if from:getMark("@zhican") == 1 then
			return 2
		end
	end
}
Mwanizame:setHeadMaxHpAdjustedValue(-1)
Mcanbao = sgs.CreateTriggerSkill{
	name = "Mcanbao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if damage.to:getHandcardNum() < 2 then
				if damage.card and damage.card:isKindOf("Slash") and not (damage.chain or damage.transfer) then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self) or room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local damage = data:toDamage()
		local log = sgs.LogMessage()
			log.type = "#DamageMore"
			log.from = player
			log.arg = self:objectName()
		room:sendLog(log)
		damage.damage = damage.damage + 1
		data:setValue(damage)
	end,
}
Mchuangshang = sgs.CreateTriggerSkill{
	name = "Mchuangshang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseEnd},
	relate_to_place = "deputy",
	can_trigger = function(self, event, room, player, data)
		if player:getPhase() == sgs.Player_Play and not player:isKongcheng() and player:isWounded() and player:getMark("@zhican") == 1 then
			local wanizame =  room:findPlayerBySkillName(self:objectName())
			if wanizame and wanizame:isAlive() then
				return self:objectName(), wanizame
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		local wanizame =  room:findPlayerBySkillName(self:objectName())
		if wanizame:hasShownSkill(self) then
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(wanizame, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		if not player:isKongcheng() then
			room:askForDiscard(player, self:objectName(), 1, 1, false, false)
		end
	end,
}
--加入技能“致残”“创伤”“残暴”
Mwanizame:addSkill(Mzhican)
Mwanizame:addSkill(Mzhican_recover)
Mwanizame:addSkill(Mzhican_far)
Mwanizame:addSkill(Mcanbao)
Mwanizame:addSkill(Mchuangshang)
Ashan2:insertRelatedSkills("Mzhican", "#Mzhican_recover")
Ashan2:insertRelatedSkills("Mzhican", "#Mzhican_far")
--翻译表
sgs.LoadTranslationTable{
    ["Mwanizame"] = "鳄鲛",
	["&Mwanizame"] = "鳄鲛",
	["#Mwanizame"] = "嗜血狂鲛",
	["Mzhican"] = "致残",
	["#Mzhican_far"] = "致残",
	["#Mzhican_recover"] = "致残",
	["$Mzhican1"] = "你休想逃走。",
	["$Mzhican2"] = "（喘气声）",
	["@zhican"] = "致残",
	["#zhican1"] = "%from 受到残废效果！",
	["#zhican2"] = "%from 解除残废效果！",
	[":Mzhican"] = "锁定技，当你使用【杀】对目标角色造成一次伤害后，若其没有“致残”标记，其获得“致残”标记。锁定技，其他角色与拥有“致残”标记的角色的距离+2。锁定技，拥有“致残”标记的角色回合结束时，移除其“致残”标记。",
	["Mchuangshang"] = "创伤",
	["$Mchuangshang"] = "我毫不留情。",
	[":Mchuangshang"] = "副将技，锁定技，拥有“致残”标记的角色出牌阶段结束时，若其已受伤，其弃置一张手牌。",
	["Mcanbao"] = "残暴",
	["$Mcanbao"] = "狠狠的教训你。",
	[":Mcanbao"] = "主将技，锁定技，此武将牌上单独的阴阳鱼个数-1。主将技，锁定技，当你使用【杀】对目标角色造成伤害时，若其手牌数不大于1，此伤害+1。",
	["~Mwanizame"] = "跟我在海底一样黑暗。",
	["cv:Mwanizame"] = "鱼人守卫",
	["illustrator:Mwanizame"] = "英雄无敌6",
	["designer:Mwanizame"] = "月兔君",
}
--[[
   创建武将【珍珠巫女】
]]--
Mpearl = sgs.General(Ashan2, "Mpearl", "mi", 3, false)
--珠联璧合：剑圣
Mpearl:addCompanion("Mkensei")
--[[
【烟波】结束阶段开始时，你可以展示牌堆顶X+1张牌（X为你已损失体力且最大为2），然后获得其中的红色牌并弃置其余的牌。
*【蛇舞】摸牌阶段开始时，若你有手牌，你可以指定一名有手牌且已受伤的其他角色观看你的手牌,然后你选择一项：1.其获得其中的红色牌，然后其弃置所有黑色手牌，若以此法弃置了至少一张手牌，其回复1点体力；2.其获得其中的黑色牌，然后其无法使用和打出红色手牌直到本回合结束。
]]--
Myanbo = sgs.CreateTriggerSkill{
	name = "Myanbo",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Finish then
				return self:objectName()
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
		local x = math.min(2, player:getLostHp())
		x = x+1
		local idlist = room:getNCards(x)
		for _,ids in sgs.qlist(idlist) do
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SHOW, player:objectName(),"", self:objectName(), "")
			room:moveCardTo(sgs.Sanguosha:getCard(ids), nil, nil, sgs.Player_PlaceTable, reason, true)
		end
		room:getThread():delay(1500)
		local emptycard = MemptyCard:clone()
		for _,id in sgs.qlist(idlist) do
			if sgs.Sanguosha:getCard(id):isRed() then
				emptycard:addSubcard(sgs.Sanguosha:getCard(id))
			end
		end
		if emptycard:subcardsLength() > 0 then
			room:broadcastSkillInvoke(self:objectName(), 2)
			player:obtainCard(emptycard, true)
		else
			room:broadcastSkillInvoke(self:objectName(), 3)
		end
	end,
}
Mshewu = sgs.CreateTriggerSkill{
	name = "Mshewu",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Draw and not player:isKongcheng() then
				local target
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if not p:isKongcheng() and p:isWounded() then
						target = p
						break
					end
				end
				if target then
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
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if not p:isKongcheng() and p:isWounded() then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, self:objectName())
			room:showAllCards(player, target)
			local ai_data = sgs.QVariant()
			ai_data:setValue(target)
			local red_cards = MemptyCard:clone()
			local black_cards = MemptyCard:clone()
			for _, card in sgs.qlist(player:getHandcards()) do
				if card:isRed() then
					red_cards:addSubcard(card)
				elseif card:isBlack() then
				    black_cards:addSubcard(card)
				end
			end
			if red_cards:subcardsLength() > 0 then
				if black_cards:subcardsLength() > 0 then
					choice = room:askForChoice(player, self:objectName(), "shewu_red+shewu_black", ai_data)
				else
					choice = "shewu_red"
				end
			else
				choice = "shewu_black"
			end
			if choice == "shewu_red" then
				room:broadcastSkillInvoke(self:objectName(), 2)
				target:obtainCard(red_cards, true)
				room:getThread():delay(1000)
				local throw_cards = MemptyCard:clone()
				for _, card in sgs.qlist(target:getHandcards()) do
					if card:isBlack() then
						throw_cards:addSubcard(card)
					end
				end
				if throw_cards:subcardsLength() > 0 then
					room:throwCard(throw_cards, target)
					if target:isWounded() then
						local recover = sgs.RecoverStruct()
							recover.who = player
							recover.recover = 1
						room:recover(target, recover)
						room:notifySkillInvoked(target, self:objectName())
					end
				end
			else
				room:broadcastSkillInvoke(self:objectName(), 3)
				target:obtainCard(black_cards, true)
				room:getThread():delay(1000)
				room:setPlayerCardLimitation(target, "use,response", ".|red|.|hand", false)
				room:setPlayerMark(target, "@shewu", 1)
				room:setPlayerMark(player, "shewu_invoked", 1)
				local log = sgs.LogMessage()
					log.type = "#shewu"
					log.from = target
				room:sendLog(log)
			end
		end
		return false
	end,
}
Mshewu_recover = sgs.CreateTriggerSkill{
	name = "#Mshewu_recover",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging, sgs.BuryVictim},
	can_trigger = function(self, event, room, player, data)
		if player and player:getMark("shewu_invoked") == 1 then
			if event == sgs.EventPhaseChanging then
				if player and player:isAlive() then
					local change = data:toPhaseChange()
					if change.to == sgs.Player_NotActive then
						room:setPlayerMark(player, "shewu_invoked", 0)
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							if p:getMark("@shewu") == 1 then
								room:setPlayerMark(p, "@shewu", 0)
								room:removePlayerCardLimitation(p, "use,response", ".|red|.|hand")
							end
						end
					end
				end
			else
				local death = data:toDeath()
				if player:objectName() == death.who:objectName() then
					room:setPlayerMark(player, "shewu_invoked", 0)
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getMark("@shewu") == 1 then
							room:setPlayerMark(p, "@shewu", 0)
							room:removePlayerCardLimitation(p, "use,response", ".|red|.|hand")
						end
					end
				end
			end
		end
		return ""
	end,
}
--加入技能“烟波”“蛇舞”
Mpearl:addSkill(Myanbo)
Mpearl:addSkill(Mshewu)
Mpearl:addSkill(Mshewu_recover)
Ashan2:insertRelatedSkills("Mshewu", "#Mshewu_recover")
--翻译表
sgs.LoadTranslationTable{
    ["Mpearl"] = "珍珠巫女",
	["&Mpearl"] = "珍珠巫女",
	["#Mpearl"] = "魅惑蛇女",
	["Myanbo"] = "烟波",
	["$Myanbo1"] = "开始涨潮了。",
	["$Myanbo2"] = "（笑声）",
	["$Myanbo3"] = "还有下一次！",
	[":Myanbo"] = "结束阶段开始时，你可以展示牌堆顶X+1张牌（X为你已损失体力且最大为2），然后获得其中的红色牌并弃置其余的牌。",
	["Mshewu"] = "蛇舞",
	["#Mshewu_recover"] = "蛇舞",
	["$Mshewu1"] = "让我们弄出点声响~",
	["$Mshewu2"] = "我完成了救赎。",
	["$Mshewu3"] = "你在颤抖。",
	["shewu_red"] = "红色",
	["shewu_black"] = "黑色",
	["@shewu"] = "蛇舞",
	["#shewu"] = "%from 无法打出和使用红色手牌直到本阶段结束！",
	[":Mshewu"] = "摸牌阶段开始时，若你有手牌，你可以指定一名有手牌且已受伤的其他角色观看你的手牌,然后你选择一项：1.其获得其中的红色牌，然后其弃置所有黑色手牌，若以此法弃置了至少一张手牌，其回复1点体力；2.其获得其中的黑色牌，然后其无法使用和打出红色手牌直到本回合结束。",
	["~Mpearl"] = "不能……再蛇行了……",
	["cv:Mpearl"] = "娜迦海妖",
	["illustrator:Mpearl"] = "英雄无敌6",
	["designer:Mpearl"] = "月兔君",
}

--[[
   创建武将【河伯】
]]--
Mkappa = sgs.General(Ashan2, "Mkappa", "mi", 3)
--[[
【迅捷】锁定技，当你受到一次伤害后，当前回合结束后你执行一个额外的回合。
【急雨】出牌阶段结束时，若你于此阶段未造成伤害，你可以弃置所有手牌然后摸等量的牌。
]]--
Mxunjie = sgs.CreateTriggerSkill{
	name = "Mxunjie",
	frequency = sgs.Skill_Compulsory,
	priority = -4,
	events = {sgs.Damaged, sgs.EventPhaseStart},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() then
			if event == sgs.Damaged then
				if player:getMark("@xunjie") == 0 and player:hasSkill(self:objectName()) then
					return self:objectName(), player
				end
			else
				if player:getPhase() == sgs.Player_NotActive then
					local kappa = room:findPlayerBySkillName(self:objectName())
					if kappa and kappa:isAlive() and kappa:getMark("@xunjie") == 1 then
						return self:objectName(), kappa
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if event == sgs.Damaged then
			if player:hasShownSkill(self) or room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:notifySkillInvoked(player, self:objectName())
				return true
			end
		else
			local kappa = room:findPlayerBySkillName(self:objectName())
			if kappa:hasShownSkill(self) then
				room:setPlayerMark(kappa, "@xunjie", 0)
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:notifySkillInvoked(kappa, self:objectName())
				return true
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		if event == sgs.Damaged then
			room:setPlayerMark(player, "@xunjie", 1)
		else
			local kappa = room:findPlayerBySkillName(self:objectName())
			kappa:gainAnExtraTurn()
		end
	end,
}
Mjiyu = sgs.CreateTriggerSkill{
	name = "Mjiyu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage, sgs.EventPhaseEnd},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if event == sgs.Damage then
				if player:getPhase() == sgs.Player_Play and not player:hasFlag("jiyu_hurt") then
				    room:setPlayerFlag(player, "jiyu_hurt")
				end
			else
				if player:getPhase() == sgs.Player_Play then
					if player:hasFlag("jiyu_hurt") then
						room:setPlayerFlag(player, "-jiyu_hurt")
					else
						if not player:isKongcheng() then
							return self:objectName()
						end
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local x = player:getHandcardNum()
		player:throwAllHandCards()
		player:drawCards(x)
	end,
}
--加入技能“迅捷”“急雨”
Mkappa:addSkill(Mxunjie)
Mkappa:addSkill(Mjiyu)
--翻译表
sgs.LoadTranslationTable{
    ["Mkappa"] = "河伯",
	["&Mkappa"] = "河伯",
	["#Mkappa"] = "迅捷突袭",
	["Mxunjie"] = "迅捷",
	["$Mxunjie1"] = "这只是我的分身。",
	["$Mxunjie2"] = "稳操胜券！",
	["@xunjie"] = "迅捷",
	["#xunjie"] = "%from 获得了一个额外的回合！",
	[":Mxunjie"] = "锁定技，当你受到一次伤害后，当前回合结束后你执行一个额外的回合。",
	["Mjiyu"] = "急雨",
	["$Mjiyu"] = "灵魂的回应。",
	[":Mjiyu"] = "出牌阶段结束时，若你于此阶段未造成伤害，你可以弃置所有手牌然后摸等量的牌。",
	["~Mkappa"] = "把我葬在这里吧。",
	["cv:Mkappa"] = "撼地者",
	["illustrator:Mkappa"] = "英雄无敌6",
	["designer:Mkappa"] = "月兔君",
}

--[[
   创建武将【川灵】
]]--
Mmizukami = sgs.General(Ashan2, "Mmizukami", "mi", 3, false)
--珠联璧合：河伯、冰女
Mmizukami:addCompanion("Mkappa")
Mmizukami:addCompanion("Myukionna")
--[[
【弱水】当你受到一次伤害后，你可以获得伤害来源一张手牌，若该牌点数在你当前手牌中不为最大或最小，你展示之，伤害来源失去1点体力。
*【纯净】主将技，你的弃牌阶段外，当任意角色的牌置入弃牌堆时，若牌的数量多于你的手牌数且你有手牌，你可以获得之。
*【羁绊】副将技，锁定技，此武将牌上单独的阴阳鱼个数+1。副将技，与你势力相同的角色回复一次体力后，你可以摸一张牌。
]]--
Mruoshui = sgs.CreateTriggerSkill{
	name = "Mruoshui",
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damaged},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if damage.from and not damage.from:isKongcheng() then
				return self:objectName()
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
		local id = room:askForCardChosen(player, damage.from, "h", self:objectName())
		room:obtainCard(player, id, false)
		local bigger, smaller
		for _, cd in sgs.qlist(player:getHandcards()) do
			if cd:getNumber() > sgs.Sanguosha:getWrappedCard(id):getNumber() then
				bigger = true
			elseif cd:getNumber() < sgs.Sanguosha:getWrappedCard(id):getNumber() then
				smaller = true
			end
			if bigger and smaller then
				break
			end
		end
		if bigger and smaller then
			room:broadcastSkillInvoke(self:objectName(), 2)
			room:showCard(player, id)
			room:loseHp(damage.from, 1)
		end
	end,
}
Mchunjing = sgs.CreateTriggerSkill{
	name = "Mchunjing",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime},
	priority = 5,
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		local mizukami = room:findPlayerBySkillName(self:objectName())
		if mizukami and mizukami:isAlive() and not mizukami:isKongcheng() and mizukami:getPhase() ~= sgs.Player_Discard then
			local move = data:toMoveOneTime()
			local card_ids = sgs.IntList()
			for i = 0,(move.card_ids:length()-1),1 do
				if (move.from_places):at(i) == sgs.Player_PlaceHand or (move.from_places):at(i) == sgs.Player_PlaceEquip then
					invoke=true
				end
			end
			if move.to_place == sgs.Player_DiscardPile and invoke then
				if move.card_ids:length() > mizukami:getHandcardNum() then
					return self:objectName(), mizukami
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		local mizukami = room:findPlayerBySkillName(self:objectName())
		if room:askForSkillInvoke(mizukami, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local mizukami = room:findPlayerBySkillName(self:objectName())
		local move = data:toMoveOneTime()
		local card_ids = sgs.IntList()
		local empty = MemptyCard:clone()
		for _,cdid in sgs.list(move.card_ids) do
			empty:addSubcard(sgs.Sanguosha:getCard(cdid))
		end
		mizukami:obtainCard(empty, true)
	end,
}
Mmizukami:setDeputyMaxHpAdjustedValue(1)
Mjiban = sgs.CreateTriggerSkill{
    name = "Mjiban",
	frequency = sgs.Skill_NotFrequent,
	relate_to_place = "deputy",
	events = {sgs.HpRecover},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if not player:hasShownOneGeneral() then return "" end
		local mizukami = room:findPlayerBySkillName(self:objectName())
		if mizukami and mizukami:isAlive() and (mizukami:isFriendWith(player) or mizukami:willBeFriendWith(player)) then
			return self:objectName(), mizukami
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		local mizukami = room:findPlayerBySkillName(self:objectName())
		if room:askForSkillInvoke(mizukami, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local mizukami = room:findPlayerBySkillName(self:objectName())
		mizukami:drawCards(1)
	end,
}
--加入技能“弱水”“纯净”“羁绊”
Mmizukami:addSkill(Mruoshui)
Mmizukami:addSkill(Mchunjing)
Mmizukami:addSkill(Mjiban)
--翻译表
sgs.LoadTranslationTable{
    ["Mmizukami"] = "川灵",
	["&Mmizukami"] = "川灵",
	["#Mmizukami"] = "弱水三千",
	["Mruoshui"] = "弱水",
	["$Mruoshui1"] = "还不快退下！",
	["$Mruoshui2"] = "小小的警告，你的死期到了。",
	[":Mruoshui"] = "当你受到一次伤害后，你可以获得伤害来源一张手牌，若该牌点数在你当前手牌中不为最大或最小，你展示之，伤害来源失去1点体力。",
	["Mchunjing"] = "纯净",
	["$Mchunjing"] = "终于等到了这一刻。",
	[":Mchunjing"] = "主将技，你的弃牌阶段外，当任意角色的牌置入弃牌堆时，若牌的数量多于你的手牌数且你有手牌，你可以获得之。",
	["Mjiban"] = "羁绊",
	["$Mjiban"] = "死亡也无法阻止我们。",
	[":Mjiban"] = "副将技，锁定技，此武将牌上单独的阴阳鱼个数+1。副将技，与你势力相同的角色回复一次体力后，你可以摸一张牌。",
	["~Mmizukami"] = "你不得好死！",
	["cv:Mmizukami"] = "月之女祭司",
	["illustrator:Mmizukami"] = "英雄无敌6",
	["designer:Mmizukami"] = "月兔君",
}

--[[
   创建武将【冰女】
]]--
Myukionna = sgs.General(Ashan2, "Myukionna", "mi", 3, false)
--[[
【霜形】你的回合外，当你成为黑桃基本牌或黑桃锦囊的目标后，在其结算后，你可以弃置一张手牌获得之，若你弃置的手牌为黑桃花色，你摸一张牌。
*【魔性】锁定技，你的红桃手牌视为黑桃牌。锁定技，当你成为男性角色使用的红色锦囊的目标时，你取消之。
【冻结】主将技，限定技，弃牌阶段开始时，你可以弃置三张不同类型的黑桃牌，然后指定一名装备区不为空的其他势力的角色，其弃置装备区所有牌并无法使用装备牌。
]]--
Mbingjing = sgs.CreateTriggerSkill{
	name = "Mbingjing",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardFinished},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		local yukionna = room:findPlayerBySkillName(self:objectName())
		if yukionna and yukionna:isAlive() and yukionna:hasFlag("bingjing") and yukionna:getPhase() == sgs.Player_NotActive then
			if not yukionna:isKongcheng() then
				local use = data:toCardUse()
				if use.card and use.to:contains(yukionna) and not use.card:isVirtualCard() then
					return self:objectName(), yukionna
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		local yukionna = room:findPlayerBySkillName(self:objectName())
		room:setPlayerFlag(yukionna, "-bingjing")
		local bing_card = room:askForCard(yukionna, ".|.|.|hand", "@bingjing_invoke", data, sgs.Card_MethodDiscard)
		if bing_card then
			if bing_card:getSuit() == sgs.Card_Spade then
				room:setPlayerFlag(yukionna, "black_bing")
				room:broadcastSkillInvoke(self:objectName(), 1)
			else
				room:broadcastSkillInvoke(self:objectName(), 2)
			end
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local yukionna = room:findPlayerBySkillName(self:objectName())
		local use = data:toCardUse()
		yukionna:obtainCard(use.card)
		if yukionna:hasFlag("black_bing") then
			room:setPlayerFlag(yukionna, "-black_bing")
			yukionna:drawCards(1)
		end
	end,
}	
Mbingjing_effect = sgs.CreateTriggerSkill{
	name = "#Mbingjing_effect",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill("Mbingjing") and player:getPhase() == sgs.Player_NotActive then
			local use = data:toCardUse()
			if use.card and (use.card:isKindOf("TrickCard") or use.card:isKindOf("BasicCard")) and not use.card:isVirtualCard() and use.card:getSuit() == sgs.Card_Spade then
				if use.to:contains(player) then
					room:setPlayerFlag(player, "bingjing")
				end
			end
		end
		return ""
	end,
}
Mmoxing_change = sgs.CreateFilterSkill{
	name = "#Mmoxing_change",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local invoke
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:hasSkill("Mmoxing") and p:hasShownSkill(Mmoxing) then
				invoke = true
				break
			end
		end
		if invoke then
			local suit = to_select:getSuit()
			local place = room:getCardPlace(to_select:getEffectiveId())
			return suit == sgs.Card_Heart and place == sgs.Player_PlaceHand
		end
	end,
	view_as = function(self, card)
		local id = card:getId()
		local new_card = sgs.Sanguosha:getWrappedCard(id)
		new_card:setSkillName("Mmoxing")
		new_card:setSuit(sgs.Card_Spade)
		new_card:setModified(true)
		return new_card
	end,
}
Mmoxing = sgs.CreateTriggerSkill{
	name = "Mmoxing",  
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirming},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("TrickCard") and use.card:isRed() and use.to:contains(player) then
				if use.from and use.from:getGender() ~= player:getGender() then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self) or player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), 2)
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
	end,
	on_effect = function(self, event,room,player, data)
		local use = data:toCardUse()
		sgs.Room_cancelTarget(use, player)
		data:setValue(use)
		return false
	end,
}
MdongjieCard = sgs.CreateSkillCard{
	name = "MdongjieCard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select, Self)
		if #targets == 0 then
		    return to_select:hasShownOneGeneral() and to_select:objectName() ~= sgs.Self:objectName() and not (sgs.Self:isFriendWith(to_select) or sgs.Self:willBeFriendWith(to_select)) and to_select:hasEquip()
		end
		return false
	end,
	feasible = function(self, targets, Self)
		return #targets == 1
	end ,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:throwCard(self, player)
		room:setPlayerMark(player, "@dongjie_use", 0)
		room:broadcastSkillInvoke("Mdongjie", 1)
		room:doSuperLightbox("Myukionna", self:objectName())
		room:setPlayerMark(target, "@dongjie", 1)
		target:throwAllEquips()
		local log = sgs.LogMessage()
	        log.type = "#dongjie"
			log.from = target
		room:sendLog(log)
		room:setPlayerCardLimitation(target, "use", "EquipCard|.|.|hand", false)
	end,
}
MdongjieVS = sgs.CreateViewAsSkill{
	name = "Mdongjie",
	n = 3,
	view_filter = function(self, selected, to_select)
		if #selected == 3 then return false end
		for _,card in ipairs(selected) do
		    if to_select:getSuit() ~= sgs.Card_Spade then return false end
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
		local dongjie_card = MdongjieCard:clone()
		for _,card in ipairs(cards) do
			dongjie_card:addSubcard(card)
		end
		return dongjie_card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@Mdongjie"
	end,
}
Mdongjie = sgs.CreateTriggerSkill{
	name = "Mdongjie",
	limit_mark = "@dongjie_use",
	frequency = sgs.Skill_Limited,
	view_as_skill = MdongjieVS,
	events = {sgs.EventPhaseStart},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Discard and player:getMark("@dongjie_use") == 1 and not player:isKongcheng() then
				local spade_basic
				local spade_equip
				local spade_trick
				for _, card in sgs.qlist(player:getCards("he")) do
					if card:isKindOf("BasicCard") and card:getSuit() == sgs.Card_Spade then
						spade_basic = true
					elseif card:isKindOf("EquipCard") and card:getSuit() == sgs.Card_Spade then
						spade_equip = true
					elseif card:isKindOf("TrickCard") and card:getSuit() == sgs.Card_Spade then
						spade_trick = true
					end
				end
				if spade_basic and spade_equip and spade_trick then
					local targets = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:hasShownOneGeneral() and not (player:isFriendWith(p) or player:willBeFriendWith(p)) and p:hasEquip() then
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
		if room:askForUseCard(player, "@@Mdongjie", "@dongjie_invoke") then
			return true
		end
	end,
	on_effect = function(self,event,room,player,data)
		return false
	end,
}
--加入技能“冰晶”“魔性”“冻结”
Myukionna:addSkill(Mbingjing)
Myukionna:addSkill(Mbingjing_effect)
Myukionna:addSkill(Mmoxing)
Myukionna:addSkill(Mmoxing_change)
Myukionna:addSkill(Mdongjie)
Ashan2:insertRelatedSkills("Mbingjing", "#Mbingjing_effect")
Ashan2:insertRelatedSkills("Mmoxing", "#Mmoxing_change")
--翻译表
sgs.LoadTranslationTable{
    ["Myukionna"] = "冰女",
	["&Myukionna"] = "冰女",
	["#Myukionna"] = "霜冻之心",
	["Mbingjing"] = "冰晶",
	["#Mbingjing_effect"] = "冰晶（效果）",
	["$Mbingjing1"] = "啊，很好~",
	["$Mbingjing2"] = "我感到更冷了~",
	["@bingjing_invoke"] = "是否弃置一张手牌发动技能“冰晶”？",
	[":Mbingjing"] = "你的回合外，当你成为黑桃基本牌或黑桃锦囊的目标后，在其结算后，你可以弃置一张手牌获得之，若你弃置的手牌为黑桃花色，你摸一张牌。",
	["Mmoxing"] = "魔性",
	["#Mmoxing_change"] = "魔性",
	["$Mmoxing1"] = "（轻笑）",
	["$Mmoxing2"] = "没人能看到我。",
	[":Mmoxing"] = "锁定技，你的红桃手牌视为黑桃牌。锁定技，当你成为男性角色使用的红色锦囊的目标时，你取消之。",
	["Mdongjie"] = "冻结",
	["$Mdongjie"] = "你命中注定要变得晶莹剔透。",
	[":Mdongjie"] = "主将技，限定技，弃牌阶段开始时，你可以弃置三张不同类型的黑桃牌，然后指定一名装备区不为空的其他势力的角色，其弃置装备区所有牌并无法使用装备牌。",
	["MdongjieCard"] = "冻结",
	["MdongjieVS"] = "冻结",
	["mdongjie"] = "冻结",
	["@dongjie"] = "冻结",
	["@dongjie_use"] = "冻结使用",
	["@dongjie_invoke"] = "是否弃置三张不同类型的黑桃牌发动技能“冻结”？",
	["~Mdongjie"] = "选择三张不同类型的黑桃牌-点击确定。",
	["#dongjie"] = "%from 无法使用装备牌！",
	["~Myukionna"] = "我的心在解冻……",
	["cv:Myukionna"] = "水晶室女",
	["illustrator:Myukionna"] = "英雄无敌6",
	["designer:Myukionna"] = "月兔君",
}

--[[
   创建武将【剑圣】
]]--
Mkensei = sgs.General(Ashan2, "Mkensei", "mi", 4)
--[[
*【浪斩】当你使用【杀】指定目标后，你可以展示其一张手牌：若该牌与该【杀】花色相同，其不可以使用【闪】对此【杀】进行响应；若该牌不大于该【杀】的点数且你的“浪”标记数目不大于3枚，你获得一枚“浪”标记；若同时满足该两点，你摸一张牌。锁定技，你手牌上限+X（X为你的“浪”标记数目）。
*【挑战】主将技，锁定技，此武将牌上单独的阴阳鱼个数-1。主将技，出牌阶段开始时，若你有手牌，你可以展示所有手牌并移除2枚“浪”标记指定一名体力不小于你的其他势力的角色，对方进入“挑战”状态直到你死亡。主将技，锁定技，“挑战”状态下的角色对与你相同势力的其他角色造成的伤害始终-1；该角色摸牌阶段额外摸一张牌；该角色出牌阶段结束时，若其体力不小于你且其于此阶段未对你造成伤害，其须选择一项：弃置两张牌或失去1点体力。
*【残阳】副将技，当你进入濒死时，你可以展示牌堆顶X张牌，其中每有一种花色你回复1点体力，若如此做，你移除所有的“浪”标记（X为你拥有的“浪”标记数目）。
]]--
Mlangzhan = sgs.CreateTriggerSkill{
	name = "Mlangzhan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetChosen},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") then
				local targets_names = {}
				for _,p in sgs.qlist(use.to) do
					if not p:isKongcheng() then
						table.insert(targets_names,p:objectName())
					end	
				end
				if #targets_names > 0 then
					return self:objectName() .. "->" .. table.concat(targets_names, "+"), player
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, target, data, player)
		local ai_data = sgs.QVariant()
		ai_data:setValue(target)
		if player:askForSkillInvoke(self:objectName(), ai_data) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, target, data, player)
		local use = data:toCardUse()
		local id = room:askForCardChosen(player, target, "h", self:objectName())
		room:showCard(target, id)
		room:getThread():delay(1000)
		local realcard = sgs.Sanguosha	:getWrappedCard(id)
		local x = 0
		if player:getMark("@langzhan") <= 3 and realcard:getNumber() and realcard:getNumber() <= use.card:getNumber() then
			player:gainMark("@langzhan")
			x = x+1
		end
		if realcard:getSuit() ~= sgs.Card_NoSuit and realcard:getSuit() == use.card:getSuit() then
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
			x = x+1
		end
		if x == 0 then
			room:broadcastSkillInvoke(self:objectName(), 2)
		elseif x == 1 then
			room:broadcastSkillInvoke(self:objectName(), 3)
		else
			room:broadcastSkillInvoke(self:objectName(), 4)
			player:drawCards(1)
		end
		return false
	end,
}
Mlangzhan_max = sgs.CreateMaxCardsSkill{
	name = "#Mlangzhan_max", 
	extra_func = function(self, target)
		if target:hasSkill("Mlangzhan") and target:hasShownSkill(Mlangzhan) then
            local x = target:getMark("@langzhan")
			if x > 0 then
				return x
			end
		end
	end,
}
Mkensei:setHeadMaxHpAdjustedValue(-1)
Mtiaozhan = sgs.CreateTriggerSkill{
	name = "Mtiaozhan",  
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.BuryVictim},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if event == sgs.EventPhaseStart then
				if player:getPhase() == sgs.Player_Play and player:getMark("@langzhan") >= 2 and not player:isKongcheng() then
					local targets = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:hasShownOneGeneral() and p:getHp() >= player:getHp() and p:getMark("@tiaozhan") == 0 and not (player:isFriendWith(p) or player:willBeFriendWith(p)) then
							targets:append(p)
						end
					end
					if not targets:isEmpty() then
						return self:objectName(), player
					end
				end
			else
				local death = data:toDeath()
				if death.who and player:objectName() == death.who:objectName() then
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getMark("@tiaozhan") == 1 then
							room:setPlayerMark(target, "@tiaozhan", 0)
						end
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
			player:loseMark("@langzhan", 2)
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasShownOneGeneral() and p:getHp() >= player:getHp() and p:getMark("@tiaozhan") == 0 and not (player:isFriendWith(p) or player:willBeFriendWith(p)) then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, self:objectName())
			room:setPlayerMark(target, "@tiaozhan", 1)
		end
	end,
}
Mtiaozhan_effect = sgs.CreateTriggerSkill{
	name = "#Mtiaozhan_effect",  
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseEnd, sgs.DamageInflicted, sgs.Damage},
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play and player:getMark("@tiaozhan") == 1 and not player:hasFlag("tiaozhan_damaged") then
				local kensei = room:findPlayerBySkillName("Mtiaozhan")
				if kensei and kensei:isAlive() and player:getHp() >= kensei:getHp() then
					return self:objectName(), kensei
				end
			end
		elseif event == sgs.DamageInflicted then
			local kensei = room:findPlayerBySkillName("Mtiaozhan")
			if kensei and kensei:isAlive() then
				local damage = data:toDamage()
				if damage.from and player:hasShownOneGeneral() and player:isFriendWith(kensei) and damage.from:getMark("@tiaozhan") == 1 and not player:hasSkill("Mtiaozhan") then
					return self:objectName(), kensei
				end
			end
		else
			local damage = data:toDamage()
			if player:getMark("@tiaozhan") == 1 and damage.to:hasSkill("Mtiaozhan") and player:getPhase() == sgs.Player_Play then
			    if not player:hasFlag("tiaozhan_damaged") then
				    room:setPlayerFlag(player, "tiaozhan_damaged")
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		return true
	end,
	on_effect = function(self,event,room,player,data)
		local kensei = room:findPlayerBySkillName("Mtiaozhan")
		room:notifySkillInvoked(kensei, self:objectName())
		if event == sgs.EventPhaseEnd then
			room:broadcastSkillInvoke("Mtiaozhan", 2)
			if player:getHandcardNum()+player:getEquips():length() >= 2 then
				choice = room:askForChoice(player, self:objectName(), "tiaozhan_throw+tiaozhan_hurt", data)
			else
				choice = "tiaozhan_hurt"
			end
			if choice == "tiaozhan_throw" then
				room:askForDiscard(player, self:objectName(), 2, 2, false, true)
			else
				room:loseHp(player, 1)
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			room:broadcastSkillInvoke("Mtiaozhan", 3)
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
		end
	end,
}
Mtiaozhan_draw = sgs.CreateDrawCardsSkill{
	name = "#Mtiaozhan_draw",
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:getMark("@tiaozhan") == 1 then
			local kensei = room:findPlayerBySkillName("Mtiaozhan")
			if kensei and kensei:isAlive() then
				return self:objectName(), kensei
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		local kensei = room:findPlayerBySkillName("Mtiaozhan")
		room:broadcastSkillInvoke("Mtiaozhan", 4)
		room:notifySkillInvoked(kensei, self:objectName())
		return true
	end,
	draw_num_func = function(self,player,n)
		return n+1
	end,
}
Mcanyang = sgs.CreateTriggerSkill{
	name = "Mcanyang",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.AskForPeaches},
	relate_to_place = "deputy",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local dying = data:toDying()
			if player:objectName() == dying.who:objectName() and player:getMark("@langzhan") > 0 then
				return self:objectName()
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
		local idlist = room:getNCards(player:getMark("@langzhan"))
		room:setPlayerMark(player, "@langzhan", 0)
		for _,ids in sgs.qlist(idlist) do
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SHOW, player:objectName(),"", self:objectName(), "")
			room:moveCardTo(sgs.Sanguosha:getCard(ids), nil, nil, sgs.Player_PlaceTable, reason, true)
		end
		room:getThread():delay(1000)
		local x = 0
		local heart
		local diamond
		local club
		local spade
		for _,id in sgs.qlist(idlist) do
			if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Heart and not heart then
				heart = true
				x = x+1
			elseif sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Diamond and not diamond then
				diamond = true
				x = x+1
			elseif sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Club and not club then
				club = true
				x = x+1
			elseif sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Spade and not spade then
				spade = true
				x = x+1
			end
			if heart and diamond and club and spade then
				break
			end
		end
		if x > 0 then
			local recover = sgs.RecoverStruct()
				recover.recover = x
				recover.who = player
			room:recover(player, recover)
		end
	end,
}
--加入技能“浪斩”“残阳”“挑战”
Mkensei:addSkill(Mlangzhan)
Mkensei:addSkill(Mlangzhan_max)
Mkensei:addSkill(Mtiaozhan)
Mkensei:addSkill(Mtiaozhan_effect)
Mkensei:addSkill(Mtiaozhan_draw)
Mkensei:addSkill(Mcanyang)
Ashan2:insertRelatedSkills("Mlangzhan", "#Mlangzhan_max")
Ashan2:insertRelatedSkills("Mtiaozhan", "#Mtiaozhan_effect")
Ashan2:insertRelatedSkills("Mtiaozhan", "#Mtiaozhan_draw")
--翻译表
sgs.LoadTranslationTable{
    ["Mkensei"] = "剑圣",
	["&Mkensei"] = "剑圣",
	["#Mkensei"] = "心剑合一",
	["Mlangzhan"] = "浪斩",
	["#Mlangzhan_max"] = "浪斩",
	["$Mlangzhan1"] = "剑刃之力！",
	["$Mlangzhan2"] = "稍后再来解决你。",
	["$Mlangzhan3"] = "倒下吧！",
	["$Mlangzhan4"] = "我的剑将你摧毁！",
	["@langzhan"] = "浪",
	[":Mlangzhan"] = "当你使用【杀】指定目标后，你可以展示其一张手牌：若该牌与该【杀】花色相同，其不可以使用【闪】对此【杀】进行响应；若该牌不大于该【杀】的点数且你的“浪”标记数目不大于3枚，你获得一枚“浪”标记；若同时满足该两点，你摸一张牌。锁定技，你手牌上限+X（X为你的“浪”标记数目）。",
	["Mtiaozhan"] = "挑战",
	["#Mtiaozhan_effect"] = "挑战",
	["#Mtiaozhan_draw"] = "挑战",
	["$Mtiaozhan1"] = "注视我的双眼。",
	["$Mtiaozhan2"] = "要怪就怪我的剑吧。",
	["$Mtiaozhan3"] = "勇敢和愚蠢只有一剑之差。",
	["$Mtiaozhan4"] = "不必为恢复生命感到羞愧。",
	["@tiaozhan"] = "挑战",
	["tiaozhan_hurt"] = "负隅顽抗",
	["tiaozhan_throw"]= "低头认输",
	[":Mtiaozhan"] = "主将技，锁定技，此武将牌上单独的阴阳鱼个数-1。主将技，出牌阶段开始时，若你有手牌，你可以展示所有手牌并移除2枚“浪”标记指定一名体力不小于你的其他势力的角色，对方进入“挑战”状态直到你死亡。主将技，锁定技，“挑战”状态下的角色对与你相同势力的其他角色造成的伤害始终-1；该角色摸牌阶段额外摸一张牌；该角色出牌阶段结束时，若其体力不小于你且其于此阶段未对你造成伤害，其须选择一项：弃置两张牌或失去1点体力。",
	["Mcanyang"] = "残阳",
	["$Mcanyang"] = "从灭绝的边缘重生。",
	[":Mcanyang"] = "副将技，当你进入濒死时，你可以展示牌堆顶X张牌，其中每有一种花色你回复1点体力，若如此做，你移除所有的“浪”标记（X为你拥有的“浪”标记数目）。",
	["~Mkensei"] = "这就是我的命运吗？",
	["cv:Mkensei"] = "主宰",
	["illustrator:Mkensei"] = "英雄无敌6",
	["designer:Mkensei"] = "月兔君",
}

--[[
   创建武将【圣麒麟】
]]--
Mkirin = sgs.General(Ashan2, "Mkirin", "mi", 5)
--[[
*【根源】锁定技，当你进入濒死时，若你体力上限大于1，你减1点体力上限，然后回复体力至1并摸两张牌。
【冰雹】当你使用【杀】对目标角色造成一次伤害时，你可以将其装备区所有牌返回至手牌，若如此做，此伤害+1。
*【凌波】主将技，锁定技，判定阶段开始时，若你判定区不为空，你获得判定区所有牌，然后失去1点体力。
*【雾霭】副将技，锁定技，出牌阶段开始时，若你的手牌数少于X张，你将手牌补至X张，然后失去1点体力（X为当前场上与你势力相同的人数且最大为4）。
]]--
Mgenyuan = sgs.CreateTriggerSkill{
	name = "Mgenyuan",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Dying},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local dying = data:toDying()
			if dying.who:objectName() == player:objectName() and player:getMaxHp() > 1 then
				return self:objectName(), player
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
		if player:getHp() > 0 then return false end
		room:loseMaxHp(player)
		local x = 1 - player:getHp()
		local recover = sgs.RecoverStruct()
			recover.recover = x
		room:recover(player, recover)
		player:drawCards(2)
	end,
}
Mbingbao = sgs.CreateTriggerSkill{
	name = "Mbingbao",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.ConfirmDamage},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
	    if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				if damage.to:hasEquip() and not (damage.chain or damage.transfer) then
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
		local emptycard = MemptyCard:clone()
		for _,card in sgs.qlist(damage.to:getEquips()) do
			emptycard:addSubcard(card)
		end
		damage.to:obtainCard(emptycard, true)
		local log = sgs.LogMessage()
			log.type = "#DamageMore"
			log.from = player
			log.arg = self:objectName()
		room:sendLog(log)
		damage.damage = damage.damage + 1
		data:setValue(damage)
	end,
}
Mlingbo = sgs.CreateTriggerSkill{
	name = "Mlingbo", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Judge then
				local judges = player:getJudgingArea()
				if judges:length() > 0 then
					return self:objectName()
				end
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
		local emptycard = MemptyCard:clone()
		for _,card in sgs.qlist(player:getJudgingArea()) do
			emptycard:addSubcard(card)
		end
		player:obtainCard(emptycard, true)
		room:loseHp(player)
	end,
}
Mwuai = sgs.CreateTriggerSkill{
	name = "Mwuai", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart},
	relate_to_place = "deputy",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and player:hasShownOneGeneral() then
			if player:getPhase() == sgs.Player_Play then
				local x = player:getPlayerNumWithSameKingdom("wuai")
				x = math.min(x, 4)
				if x > player:getHandcardNum() then
					return self:objectName()
				end
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
		local x = player:getPlayerNumWithSameKingdom("wuai")
		x = math.min(x, 4)
		local y = x - player:getHandcardNum()
		if y > 0 then
			player:drawCards(y)
			room:loseHp(player)
		end
	end,
}
--加入技能“根源”“凌波”“雾霭”“冰雹”
Mkirin:addSkill(Mgenyuan)
Mkirin:addSkill(Mlingbo)
Mkirin:addSkill(Mwuai)
Mkirin:addSkill(Mbingbao)
--翻译表
sgs.LoadTranslationTable{
    ["Mkirin"] = "圣麒麟",
	["&Mkirin"] = "圣麒麟",
	["#Mkirin"] = "驾雾腾云",
	["Mgenyuan"] = "根源",
	["$Mgenyuan1"] = "一个短暂的休眠。",
	["$Mgenyuan2"] = "倍受鼓舞。",
	[":Mgenyuan"] = "锁定技，当你进入濒死时，若你体力上限大于1，你减1点体力上限，然后回复体力至1并摸两张牌。",
	["Mlingbo"] = "凌波",
	["$Mlingbo"] = "噢，这一刻我等很久了。",
	[":Mlingbo"] = "主将技，锁定技，判定阶段开始时，若你判定区不为空，你获得判定区所有牌，然后失去1点体力。",
	["Mwuai"] = "雾霭",
	["$Mwuai"] = "嗯，这就是霜冻的代价。",
	[":Mwuai"] = "副将技，锁定技，出牌阶段开始时，若你的手牌数少于X张，你将手牌补至X张，然后失去1点体力（X为当前场上与你势力相同的人数且最大为4）。",
	["Mbingbao"] = "冰雹",
	["$Mbingbao"] = "致命的寒气！",
	[":Mbingbao"] = "当你使用【杀】对目标角色造成一次伤害时，你可以将其装备区所有牌返回至手牌，若如此做，此伤害+1。",
	["~Mkirin"] = "我的身体在消融。",
	["cv:Mkirin"] = "巫妖",
	["illustrator:Mkirin"] = "英雄无敌6",
	["designer:Mkirin"] = "月兔君",
}

--[[
   创建武将【海龙】
]]--
Mhairyou = sgs.General(Ashan2, "Mhairyou", "mi", 3, false)
--[[
*【源泉】锁定技，当你进入濒死时，若你体力上限大于1，你减1点体力上限，然后回复体力至1并摸两张牌。锁定技，当你对攻击范围内的其他势力的角色造成一次雷属性伤害后，你增加1点体力上限。
*【暴雪】当你对攻击范围内的角色造成一次无属性伤害后，你可以弃置一张锦囊牌然后选择一项：1.令其跳过下一次摸牌阶段；2.令其弃置一张手牌并跳过下一次出牌阶段；3.令其摸一张牌并跳过下一次弃牌阶段。
*【凌云】主将技，锁定技，你的判定牌视为红桃K。主将技，锁定技，当你被其他角色指定为延时锦囊的目标时，你取消之。
*【云迹】副将技，与你势力相同的角色摸牌阶段开始时，若其为被围攻角色，你可以令其将手牌数补充至围攻角色中的手牌数较大值。
]]--
Myuanquan = sgs.CreateTriggerSkill{
	name = "Myuanquan",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Dying, sgs.Damage},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if event == sgs.Dying then
				local dying = data:toDying()
				if dying.who:objectName() == player:objectName() and player:getMaxHp() > 1 then
					return self:objectName(), player
				end
			else
				local damage = data:toDamage()
				if damage.to:hasShownOneGeneral() and not (player:isFriendWith(damage.to) or player:willBeFriendWith(damage.to)) and damage.nature == sgs.DamageStruct_Thunder and player:inMyAttackRange(damage.to) then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or player:askForSkillInvoke(self:objectName(), data) then
			if event == sgs.Dying then
				room:broadcastSkillInvoke(self:objectName(), 1)
			else
				room:broadcastSkillInvoke(self:objectName(), 2)
			end
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		if event == sgs.Dying then
			if player:getHp() > 0 then return false end
			room:loseMaxHp(player)
			local maxhp = player:getMaxHp()
			local x = 1 - player:getHp()
			local recover = sgs.RecoverStruct()
				recover.recover = x
			room:recover(player, recover)
			local log = sgs.LogMessage()
				log.type = "#yuanquan"
				log.from = player
				log.arg = self:objectName()
			room:sendLog(log)
			player:drawCards(2)
		else
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp()+1))
		end
	end,
}
Mbaoxue = sgs.CreateTriggerSkill{
	name = "Mbaoxue",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if damage.to and damage.to:isAlive() and damage.nature == sgs.DamageStruct_Normal and player:inMyAttackRange(damage.to) and not (damage.to:getMark("@baoxuedraw") == 1 and damage.to:getMark("@baoxueplay") == 1 and damage.to:getMark("@baoxuedis") == 1) then
				local trick
				for _, cd in sgs.qlist(player:getCards("h")) do
					if cd:isKindOf("TrickCard") then
						trick = true
					end
				end
				if trick then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if room:askForCard(player, "TrickCard", "@baoxue_invoke", data, sgs.Card_MethodDiscard) then
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local damage = data:toDamage()
		if damage.to:getMark("@baoxuedraw") == 0 then
			if damage.to:getMark("@baoxueplay") == 0 then
				if damage.to:getMark("@baoxuedis") == 0 then
					choice = room:askForChoice(player, self:objectName(), "baoxue_skipdraw+baoxue_skipplay+baoxue_skipthrow", data)
				else
					choice = room:askForChoice(player, self:objectName(), "baoxue_skipdraw+baoxue_skipplay", data)
				end
			else
				if damage.to:getMark("@baoxuedis") == 0 then
					choice = room:askForChoice(player, self:objectName(), "baoxue_skipdraw+baoxue_skipthrow", data)
				else
					choice = "baoxue_skipdraw"
				end
			end
		else
			if damage.to:getMark("@baoxueplay") == 0 then
				if damage.to:getMark("@baoxuedis") == 0 then
					choice = room:askForChoice(player, self:objectName(), "baoxue_skipplay+baoxue_skipthrow", data)
				else
					choice = "baoxue_skipplay"
				end
			else
				choice = "baoxue_skipthrow"
			end
		end
		if choice == "baoxue_skipdraw" then
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:setPlayerMark(damage.to, "@baoxuedraw", 1)
			local log = sgs.LogMessage()
				log.type = "#baoxue1"
				log.from = damage.to
			room:sendLog(log)
		elseif choice == "baoxue_skipplay" then
			room:broadcastSkillInvoke(self:objectName(), 2)
			room:setPlayerMark(damage.to, "@baoxueplay", 1)
			if not damage.to:isNude() then
				room:askForDiscard(damage.to, self:objectName(), 1, 1, false, true)
			end
			local log = sgs.LogMessage()
				log.type = "#baoxue2"
				log.from = damage.to
			room:sendLog(log)
		else
			room:broadcastSkillInvoke(self:objectName(), 3)
			room:setPlayerMark(damage.to, "@baoxuedis", 1)
			damage.to:drawCards(1)
			local log = sgs.LogMessage()
				log.type = "#baoxue3"
				log.from = damage.to
			room:sendLog(log)
		end
	end,
}
Mbaoxue_effect = sgs.CreateTriggerSkill{
	name = "#Mbaoxue_effect",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	can_trigger = function(self, event, room, player, data)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Draw and player:getMark("@baoxuedraw") == 1 and not player:isSkipped(sgs.Player_Draw) then
			room:broadcastSkillInvoke("Mbaoxue", 4)
			room:setPlayerMark(player, "@baoxuedraw", 0)
			room:notifySkillInvoked(player, self:objectName())
			player:skip(sgs.Player_Draw)
		elseif change.to == sgs.Player_Play and player:getMark("@baoxueplay") == 1 and not player:isSkipped(sgs.Player_Play) then
			room:broadcastSkillInvoke("Mbaoxue", 5)
			room:setPlayerMark(player, "@baoxueplay", 0)
			room:notifySkillInvoked(player, self:objectName())
			player:skip(sgs.Player_Play)
		elseif change.to == sgs.Player_Discard and player:getMark("@baoxuedis") == 1 and not player:isSkipped(sgs.Player_Discard) then
			room:broadcastSkillInvoke("Mbaoxue", 6)
			room:setPlayerMark(player, "@baoxuedis", 0)
			room:notifySkillInvoked(player, self:objectName())
			player:skip(sgs.Player_Discard)
		end
	end,
}
Mlingyun_change = sgs.CreateFilterSkill{
	name = "#Mlingyun_change",
	relate_to_place = "head",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local invoke
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:hasSkill("Mlingyun") and p:hasShownSkill(Mlingyun) then
				invoke = true
				break
			end
		end
		if invoke then
			local place = room:getCardPlace(to_select:getEffectiveId())
			return place == sgs.Player_PlaceJudge
		end
	end, 
	view_as = function(self, card)
	    local id = card:getId()
		local new_card = sgs.Sanguosha:getWrappedCard(id)
		new_card:setSkillName("Mlingyun")
		new_card:setSuit(sgs.Card_Heart)
		new_card:setNumber(13)
		new_card:setModified(true)
		return new_card
	end,
}
Mlingyun = sgs.CreateTriggerSkill{
	name = "Mlingyun",  
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirming},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local use = data:toCardUse()
			if use.from and use.from:objectName() ~= player:objectName() and use.card and use.card:isKindOf("TrickCard") and not use.card:isNDTrick() and use.to:contains(player) then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), 2)
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local use = data:toCardUse()
		sgs.Room_cancelTarget(use, player)
		data:setValue(use)
		return false
	end,
}
Myunji = sgs.CreateTriggerSkill{
	name = "Myunji",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	relate_to_place = "deputy",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player:getPhase() == sgs.Player_Draw and player:hasShownOneGeneral() then
			local hairyou =  room:findPlayerBySkillName(self:objectName())
			if hairyou and hairyou:isAlive() and (hairyou:isFriendWith(player) or hairyou:willBeFriendWith(player)) then
				local lastp = getServerPlayer(room, player:getLastAlive():objectName())
				local nextp = getServerPlayer(room, player:getNextAlive():objectName())
				if lastp and nextp and lastp:objectName() ~= nextp:objectName() then
					if lastp:inSiegeRelation(nextp, player) and nextp:inSiegeRelation(lastp, player) then
						if lastp:getHandcardNum() > player:getHandcardNum() or nextp:getHandcardNum() > player:getHandcardNum() then
							return self:objectName(), hairyou
						end
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		local hairyou =  room:findPlayerBySkillName(self:objectName())
		if hairyou:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local lastp = getServerPlayer(room, player:getLastAlive():objectName())
		local nextp = getServerPlayer(room, player:getNextAlive():objectName())
		local x = lastp:getHandcardNum()
		local y = nextp:getHandcardNum()
		local m = math.max(x, y)
		if m > player:getHandcardNum() then
			player:drawCards(m - player:getHandcardNum())
		end
	end,
}
--加入技能“源泉”“凌云”“云迹”“暴雪”
Mhairyou:addSkill(Myuanquan)
Mhairyou:addSkill(Mbaoxue)
Mhairyou:addSkill(Mbaoxue_effect)
Mhairyou:addSkill(Mlingyun)
Mhairyou:addSkill(Mlingyun_change)
Mhairyou:addSkill(Myunji)
Ashan2:insertRelatedSkills("Mbaoxue", "#Mbaoxue_effect")
Ashan2:insertRelatedSkills("Mlingyun", "#Mlingyun_change")
--翻译表
sgs.LoadTranslationTable{
    ["Mhairyou"] = "海龙",
	["&Mhairyou"] = "海龙",
	["#Mhairyou"] = "圣泉化身",
	["Myuanquan"] = "源泉",
	["$Myuanquan1"] = "刚才只是热热身。",
	["$Myuanquan2"] = "我的时机到了。",
	["#yuanquan"] = "由于 %arg 的效果，%from 体力上限+1！",
	[":Myuanquan"] = "锁定技，当你进入濒死时，若你体力上限大于1，你减1点体力上限，然后回复体力至1并摸两张牌。锁定技，当你对攻击范围内的其他势力的角色造成一次雷属性伤害后，你增加1点体力上限。",
	["Mlingyun"] = "凌云",
	["#Mlingyun_change"] = "凌云",
	["$Mlingyun1"] = "尘嚣是唯一的罪恶。",
	["$Mlingyun2"] = "我独步天下，只需要影子的陪伴。",
	[":Mlingyun"] = "主将技，锁定技，你的判定牌视为红桃K。主将技，锁定技，当你被其他角色指定为延时锦囊的目标时，你取消之。",
	["Myunji"] = "云迹",
	["$Myunji"] = "我刚才一直藏在你的影子里。",
	[":Myunji"] = "副将技，与你势力相同的角色摸牌阶段开始时，若其为被围攻角色，你可以令其将手牌数补充至围攻角色中的手牌数较大值。",
	["Mbaoxue"] = "暴雪",
	["#Mbaoxue_effect"] = "暴雪",
	["@baoxue_invoke"] = "是否弃置一张锦囊牌发动技能“暴雪”？",
	["@baoxuedraw"] = "跳过摸牌",
	["@baoxueplay"] = "跳过出牌",
	["@baoxuedis"] = "跳过弃牌",
	["baoxue_skipdraw"] = "跳过摸牌",
	["baoxue_skipplay"] = "跳过出牌",
	["baoxue_skipthrow"] = "跳过弃牌",
	["$Mbaoxue1"] = "寒冷让你变硬，冰霜让你变脆。",
	["$Mbaoxue2"] = "很多东西你都看不到了，比如说，明天。",
	["$Mbaoxue3"] = "胜利是唯一的结束方式。",
	["$Mbaoxue4"] = "你输了。",
	["$Mbaoxue5"] = "真业余。",
	["$Mbaoxue6"] = "感谢你。",
	["#baoxue1"] = "%from 将跳过下一次摸牌阶段！",
	["#baoxue2"] = "%from 将跳过下一次出牌阶段！",
	["#baoxue3"] = "%from 将跳过下一次弃牌阶段！",
	[":Mbaoxue"] = "当你对攻击范围内的角色造成一次无属性伤害后，你可以弃置一张锦囊牌然后选择一项：1.令其跳过下一次摸牌阶段；2.令其弃置一张手牌并跳过下一次出牌阶段；3.令其摸一张牌并跳过下一次弃牌阶段。",
	["~Mhairyou"] = "剩下的只有沉默……",
	["cv:Mhairyou"] = "卓尔游侠",
	["illustrator:Mhairyou"] = "英雄无敌6",
	["designer:Mhairyou"] = "月兔君",
}

--[[
   创建武将【莎拉萨】
]]--
Mshalassa = sgs.General(Ashan2, "Mshalassa", "mi", 4, false)
lord_Mshalassa = sgs.General(Ashan2, "lord_Mshalassa$", "mi", 4, false, true)
--非君主时珠联璧合：海龙
Mshalassa:addCompanion("Mhairyou")
--[[
*【波澜】君主技，锁定技，你拥有“宁静之心”。
“宁静之心”与你势力相同的角色使用一张非延时锦囊指定目标后时，若其指定了大于一名目标，你可以摸一张牌并选择一项：1.该锦囊对与你相同势力的角色无效；2.该锦囊对与你不同势力的角色无效。
【怒涛】你使用的非延时锦囊（【无懈可击】和【借刀杀人】除外）结算完毕后，你可以弃置一张相同颜色的锦囊牌，视为你对同一目标再次使用了此非延时锦囊。
]]--
Mbolan = sgs.CreateTriggerSkill{ 
    name = "Mbolan$",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.TargetConfirmed},
	can_preshow = false,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and player:hasShownOneGeneral() and player:hasShownSkill(self) and player:getRole() ~= "careerist" then
			local use = data:toCardUse()
			if use.from and use.card and use.card:isNDTrick() and use.to:length() > 1 and use.from:hasShownOneGeneral() and player:isFriendWith(use.from) then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if room:askForSkillInvoke(player, self:objectName(), data) then
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local use = data:toCardUse()
		local has_friend
		local has_enemy
		player:drawCards(1)
		for _,p in sgs.qlist(use.to) do
			if p:hasShownOneGeneral() then
				if p:isFriendWith(player) then
					has_friend = true
				else
					has_enemy = true
				end
			end
		end
		if has_friend then
			if has_enemy then
				choice = room:askForChoice(player, self:objectName(), "bolan_friend+bolan_enemy", data)
			else
				choice = "bolan_friend"
			end
		else
			choice = "bolan_enemy"
		end
		if choice == "bolan_friend" then
			room:broadcastSkillInvoke(self:objectName(), 1)
			for _,p in sgs.qlist(use.to) do
				if p:hasShownOneGeneral() and p:isFriendWith(player) then
					room:setPlayerFlag(p, "bolan_avoid")
				end
			end
		else
			room:broadcastSkillInvoke(self:objectName(), 2)
			for _,p in sgs.qlist(use.to) do
				if p:hasShownOneGeneral() and not p:isFriendWith(player) then
					room:setPlayerFlag(p, "bolan_avoid")
				end
			end
		end
	end,
}
Mbolan_avoid = sgs.CreateTriggerSkill{
	name = "#Mbolan_avoid",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardEffected},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasFlag("bolan_avoid") then
			local effect = data:toCardEffect()
			if effect.card and effect.card:isNDTrick() then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		room:setPlayerFlag(player, "-bolan_avoid")
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
Mnutao = sgs.CreateTriggerSkill{
	name = "Mnutao",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardFinished},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local use = data:toCardUse()
			if player:objectName() == use.from:objectName() and not player:isKongcheng() and use.card:isNDTrick() then
				if not (use.card:isKindOf("Nullification") or use.card:isKindOf("Collateral")) and (use.card:isRed() or use.card:isBlack()) then
					local targets = sgs.SPlayerList() 
					for _,p in sgs.qlist(use.to) do
						if not player:isProhibited(p, use.card) then
							if use.card:isKindOf("Dismantlement") or use.card:isKindOf("Snatch") then
								if p:isAlive() and not p:isAllNude() then
									targets:append(p)
								end
							elseif use.card:isKindOf("FireAttack") or use.card:isKindOf("KnowBoth") then
								if p:isAlive() and not p:isKongcheng() then
									targets:append(p)
								end
							else
								if p:isAlive() then
									targets:append(p)
								end
							end
						end
					end
					if not targets:isEmpty() then
						local trick
						for _, card in sgs.qlist(player:getHandcards()) do
							if card:isKindOf("TrickCard") and ((card:isRed() and use.card:isRed()) or (card:isBlack() and use.card:isBlack())) then
								trick = true
							end
						end
						if trick then
							return self:objectName()
						end
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		local use = data:toCardUse()
		local invoke
		if use.card:isRed() then
			if room:askForCard(player, "TrickCard|red|.|hand", "@nutao_red", data, sgs.Card_MethodDiscard) then
				invoke = true
			end
		else
			if room:askForCard(player, "TrickCard|black|.|hand", "@nutao_black", data, sgs.Card_MethodDiscard) then
				invoke = true
			end
		end
		if invoke then
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local use = data:toCardUse()
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(use.to) do
			if not player:isProhibited(p, use.card) then
				if use.card:isKindOf("Dismantlement") or use.card:isKindOf("Snatch") then
					if p:isAlive() and not p:isAllNude() then
						targets:append(p)
					end
				elseif use.card:isKindOf("FireAttack") or use.card:isKindOf("KnowBoth") then
					if p:isAlive() and not p:isKongcheng() then
						targets:append(p)
					end
				else
					if p:isAlive() then
						targets:append(p)
					end
				end
			end
		end
		if not targets:isEmpty() then
			local used = sgs.CardUseStruct()
				used.from = player
				used.card = use.card
				used.to = targets
			room:useCard(used, false)
		end
	end,
}
--武将加入技能“波澜”“怒涛”
Mshalassa:addSkill(Mnutao)
lord_Mshalassa:addSkill(Mbolan)
lord_Mshalassa:addSkill(Mbolan_avoid)
lord_Mshalassa:addSkill(Mnutao)
Ashan2:insertRelatedSkills("Mbolan", "#Mbolan_avoid")
--武将注释
sgs.LoadTranslationTable{
    ["Mshalassa"] = "莎拉萨",
	["&Mshalassa"] = "莎拉萨",
	["#Mshalassa"] = "流水之龙",
	["lord_Mshalassa"] = "莎拉萨",
	["&lord_Mshalassa"] = "莎拉萨",
	["#lord_Mshalassa"] = "流水之龙",
	["Mbolan"] = "波澜",
	["#Mbolan_avoid"] = "波澜",
	["bolan_friend"] = "守护友军",
	["bolan_enemy"] = "惩戒敌人",
	["$Mbolan1"] = "密不透风！",
	["$Mbolan2"] = "送你个吻，晚安。",
	[":Mbolan"] = "君主技，锁定技，你拥有“宁静之心”。\n\n“宁静之心”\n与你势力相同的角色使用一张非延时锦囊指定目标后时，若其指定了大于一名目标，你可以摸一张牌并选择一项：1.该锦囊对与你相同势力的角色无效；2.该锦囊对与你不同势力的角色无效。",
	["Mnutao"] = "怒涛",
	["$Mnutao"] = "死掉吧，就像爱一样，全都死掉吧！",
	["@nutao_red"] = "是否弃置一张红色锦囊发动技能“怒涛”？",
	["@nutao_black"] = "是否弃置一张黑色锦囊发动技能“怒涛”？",
	[":Mnutao"] = "你使用的非延时锦囊（【无懈可击】和【借刀杀人】除外）结算完毕后，你可以弃置一张相同颜色的锦囊牌，视为你对同一目标再次使用了此非延时锦囊。",
	["~Mshalassa"] = "我的双眼变暗了。",
	["cv:Mshalassa"] = "美杜莎",
	["illustrator:Mshalassa"] = "英雄无敌6",
	["designer:Mshalassa"] = "月兔君",
	["cv:lord_Mshalassa"] = "美杜莎",
	["illustrator:lord_Mshalassa"] = "英雄无敌6",
	["designer:lord_Mshalassa"] = "月兔君",
}


--[[******************
    创建种族【地牢】
]]--******************

--[[
   创建武将【暗影】
]]--
Mshade = sgs.General(Ashan2, "Mshade", "mi", 3)
--珠联璧合：黑龙
Mshade:addCompanion("Mblackdragon")
--[[
【背刺】结束阶段结束时，你可以弃置一张装备牌进入“隐匿”状态直到你使用的【杀】或【决斗】结算完毕或受到一次伤害（最多维持3轮）。锁定技，“隐匿”状态下当你被其他角色指定为【杀】或非延时锦囊的唯一目标时，你取消之。锁定技，“隐匿”状态下你摸牌阶段少摸一张牌。锁定技，“隐匿”状态下你使用【杀】或【决斗】指定目标后，你弃置其一张牌。
【毒刃】锁定技，你的杀附带“毒”属性。
*“毒”锁定技，当目标角色被“毒”属性的【杀】造成伤害时，其进入“中毒”状态（“毒”属性的不改变【杀】的原有属性）。
*“中毒”锁定技，“中毒”的角色在其摸牌阶段开始时，若其已受伤其进行一次判定：若结果为黑桃，其弃置等同于已损失体力数的手牌否则失去1点体力；若结果为梅花或方块，其少摸一张牌；若结果为红桃，其解除“中毒”状态。
]]--
Mbeici = sgs.CreateTriggerSkill{
	name = "Mbeici", 
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd, sgs.Damaged, sgs.TargetConfirming, sgs.TargetChosen, sgs.CardUsed, sgs.CardFinished},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseEnd then
			if player and player:isAlive() and player:hasSkill(self:objectName()) then
				if player:getPhase() == sgs.Player_Finish then
					if player:getMark("@yinni") < 2 then
						if not player:isNude() then
							local equip
							for _, card in sgs.qlist(player:getCards("he")) do
								if card:isKindOf("EquipCard") then
									equip = true
									break
								end
							end
							if equip then
								return self:objectName(), player
							else
								if player:getMark("@yinni") == 1 then
									player:loseMark("@yinni")
									room:broadcastSkillInvoke(self:objectName(), 2)
									local log = sgs.LogMessage()
										log.type = "#beici2"
										log.from = player
									room:sendLog(log)
								end
							end
						end
					else
						if player:hasFlag("beici_invoked") then
							room:setPlayerFlag(player, "-beici_invoked")
							return ""
						else
							player:loseMark("@yinni")
							if player:getMark("@yinni") == 0 then
								room:broadcastSkillInvoke(self:objectName(), 2)
								local log = sgs.LogMessage()
									log.type = "#beici2"
									log.from = player
								room:sendLog(log)
							end
						end
					end
				end
			end
		elseif event == sgs.Damaged then
			if player and player:isAlive() and player:getMark("@yinni") > 0 then
				room:setPlayerMark(player, "@yinni", 0)
				room:broadcastSkillInvoke(self:objectName(), 2)
				local log = sgs.LogMessage()
					log.type = "#beici2"
					log.from = player
				room:sendLog(log)
			end
		elseif event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.card and use.from and use.from:objectName() ~= player:objectName() and (use.card:isKindOf("Slash") or use.card:isNDTrick()) and player:getMark("@yinni") > 0 and use.to:length() == 1 and use.to:contains(player) then
				return self:objectName()
			end
		elseif event == sgs.TargetChosen then
			if player and player:isAlive() and player:hasSkill(self:objectName()) then
				if player:getMark("@yinni") > 0 then
					local use = data:toCardUse()
					if use.card and (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) then
						room:setPlayerFlag(player, "shade_out")
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
			end
		elseif event == sgs.CardUsed then
			if player and player:isAlive() and player:getMark("@yinni") > 0 then
				local use = data:toCardUse()
				if use.card and (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) and use.from:objectName() == player:objectName() then
					room:setPlayerFlag(player, "shade_out")
				end
			end
		else
			if player and player:isAlive() and player:getMark("@yinni") > 0 then
				local use = data:toCardUse()
				if use.from:objectName() == player:objectName() and player:hasFlag("shade_out") then
					room:setPlayerFlag(player, "-shade_out")
					room:setPlayerMark(player, "@yinni", 0)
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, target, data, player)
		if event == sgs.EventPhaseEnd then
			if room:askForCard(player, "EquipCard|.|.|.", "@beici_invoke", data, sgs.Card_MethodDiscard) then
				room:broadcastSkillInvoke(self:objectName(), 1)
				return true
			else
				if player:getMark("@yinni") == 1 then
					player:loseMark("@yinni")
					room:broadcastSkillInvoke(self:objectName(), 2)
					local log = sgs.LogMessage()
						log.type = "#beici2"
						log.from = player
					room:sendLog(log)
				end
			end
		elseif event == sgs.TargetConfirming then
			room:broadcastSkillInvoke(self:objectName(), 3)
			room:notifySkillInvoked(player, self:objectName())
			return true
		elseif event == sgs.TargetChosen then
			room:broadcastSkillInvoke(self:objectName(), 4)
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, target, data, player)
		if event == sgs.EventPhaseEnd then
			room:setPlayerMark(player, "@yinni", 3)
			room:setPlayerFlag(player, "beici_invoked")
			local log = sgs.LogMessage()
				log.type = "#beici1"
				log.from = player
			room:sendLog(log)
		elseif event == sgs.TargetConfirming then
			local use = data:toCardUse()
			sgs.Room_cancelTarget(use, player)
			data:setValue(use)
			return false
		elseif event == sgs.TargetChosen then
			if player and player:isAlive() and not target:isNude() then
				local id = room:askForCardChosen(player, target, "he", self:objectName())
				room:throwCard(id, target, player)
			end
		end
	end,
}
Mbeici_effect = sgs.CreateDrawCardsSkill{
	name = "#Mbeici_effect",
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:getMark("@yinni") > 0 then
			return self:objectName()
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		room:broadcastSkillInvoke("Mbeici", 5)
		room:notifySkillInvoked(player, self:objectName())
		return true
	end,
	draw_num_func = function(self,player,n)
		return n-1
	end,
}
Mduren = sgs.CreateTriggerSkill{
	name = "Mduren",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				if damage.to:isAlive() and not (damage.chain or damage.transfer) and damage.to:getMark("@zhongdu_shade") == 0 and damage.to:getMark("@zhongdu_chakram") == 0 then
					return self:objectName()
				end
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
		room:setPlayerMark(damage.to, "@zhongdu_shade", 1)
		local log = sgs.LogMessage()
			log.type = "#zhongdu"
			log.from = damage.to
		room:sendLog(log)
	end,
}
Mduren_effect = sgs.CreateTriggerSkill{
	name = "#Mduren_effect", 
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:getMark("@zhongdu_shade") == 1 then
			if player:getPhase() == sgs.Player_Draw and player:isWounded() then
				room:notifySkillInvoked(player, self:objectName())
				local judge = sgs.JudgeStruct()
					judge.who = player
					judge.pattern = ".|heart|."
					judge.good = true
					judge.reason = self:objectName()
					judge.play_animation = true
					judge.negative = false
				room:judge(judge)
				if judge:isGood() then
					room:broadcastSkillInvoke("Mduren", 2)
					room:setPlayerMark(player, "@zhongdu_shade", 0)
				else
					if judge.card:getSuit() == sgs.Card_Spade then
						room:broadcastSkillInvoke("Mduren", 3)
						if player:isWounded() then
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
					elseif judge.card:getSuit() == sgs.Card_Club or judge.card:getSuit() == sgs.Card_Diamond then
						room:broadcastSkillInvoke("Mduren", 4)
						room:setPlayerFlag(player, "zhongdu_draw_shade")
					end
				end
			end
		end
		return ""
	end,
}
Mduren_draw = sgs.CreateDrawCardsSkill{
	name = "#Mduren_draw",
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasFlag("zhongdu_draw_shade") then
			return self:objectName()
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		room:setPlayerFlag(player, "-zhongdu_draw_shade")
		return true
	end,
	draw_num_func = function(self,player,n)
		return n-1
	end,
}
--武将加入技能“背刺”“毒刃”
Mshade:addSkill(Mbeici)
Mshade:addSkill(Mbeici_effect)
Mshade:addSkill(Mduren)
Mshade:addSkill(Mduren_effect)
Mshade:addSkill(Mduren_draw)
Ashan2:insertRelatedSkills("Mbeici", "#Mbeici_effect")
Ashan2:insertRelatedSkills("Mduren", "#Mduren_effect")
Ashan2:insertRelatedSkills("Mduren", "#Mduren_draw")
--翻译表
sgs.LoadTranslationTable{
    ["Mshade"] = "暗影",
	["&Mshade"] = "暗影",
	["#Mshade"] = "无声阴影",
	["Mbeici"] = "背刺",
	["#Mbeici_effect"] = "背刺",
	["@yinni"] = "隐匿",
	["$Mbeici1"] = "化作阴影。",
	["$Mbeici2"] = "让我再尝试一下。",
	["$Mbeici3"] = "如轻烟一般虚无。",
	["$Mbeici4"] = "呵呵，你没想到吧？",
	["$Mbeici5"] = "安静点！",
	["#beici1"] = "%from 进入隐匿状态!",
	["#beici2"] = "%from 退出隐匿状态!",
	["@beici_invoke"] = "是否弃置一张装备牌发动技能“背刺”？",
	[":Mbeici"] = "结束阶段结束时，你可以弃置一张装备牌进入“隐匿”状态直到你使用的【杀】或【决斗】结算完毕或受到一次伤害（最多维持3轮）。锁定技，“隐匿”状态下当你被其他角色指定为【杀】或非延时锦囊的唯一目标时，你取消之。锁定技，“隐匿”状态下你摸牌阶段少摸一张牌。锁定技，“隐匿”状态下你使用【杀】或【决斗】指定目标后，你弃置其一张牌。",
	["Mduren"] = "毒刃",
	["#Mduren_effect"] = "中毒",
	["#Mduren_draw"] = "中毒",
	["$Mduren1"] = "收获伴随着杀戮！",
	["$Mduren2"] = "你给我记住！",
	["$Mduren3"] = "死亡的馈赠。",
	["$Mduren4"] = "哈，暮色降临！",
	["#zhongdu"] = "%from 中毒了！",
	[":Mduren"] = "锁定技，你的杀附带“毒”属性。\n\n“毒”\n锁定技，当目标角色被“毒”属性的【杀】造成伤害时，其进入“中毒”状态（“毒”属性的不改变【杀】的原有属性）。\n\n“中毒”\n锁定技，“中毒”的角色在其摸牌阶段开始时，若其已受伤其进行一次判定：若结果为黑桃，其弃置等同于已损失体力数的手牌否则失去1点体力；若结果为梅花或方块，其少摸一张牌；若结果为红桃，其解除“中毒”状态。",
	["@zhongdu_shade"] = "毒",
	["~Mshade"] = "高超的刺客总是深藏功与名……",
	["cv:Mshade"] = "隐形刺客",
	["illustrator:Mshade"] = "英雄无敌6",
	["designer:Mshade"] = "月兔君",
}

--[[
   创建武将【环刃舞者】
]]--
Mchakram = sgs.General(Ashan2, "Mchakram", "mi", 3, false)
--珠联璧合：牛头卫士
Mchakram:addCompanion("Mminotaur")
--[[
*【暗咒】当你对其他角色造成一次伤害后，若其在你的攻击范围内，你可以令其不能使用、打出或弃置锦囊牌直到其回合结束。
*【环舞】限定技，出牌阶段结束时，若你已受伤，你可以弃置一张武器牌视为对攻击范围内不含你的其他势力角色使用了一张附带毒属性的【杀】。锁定技，当你杀死一名其他角色后，若你发动过此技能，你重置此技能。
]]--
Manzhou = sgs.CreateTriggerSkill{
	name = "Manzhou",
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage, sgs.EventPhaseChanging},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.Damage then
			if player and player:isAlive() and player:hasSkill(self:objectName()) then
				local damage = data:toDamage()
				if damage.to and damage.to:isAlive() and player:objectName() ~= damage.to:objectName() and player:inMyAttackRange(damage.to) then
					if damage.to:getMark("@anzhou") == 0 then
						return self:objectName()
					end
				end
			end
		else
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:getMark("@anzhou") == 1 then
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:setPlayerMark(player, "@anzhou", 0)
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
		local damage = data:toDamage()
		room:setPlayerMark(damage.to, "@anzhou", 1)
		room:setPlayerCardLimitation(damage.to, "use,response,discard", "TrickCard|.|.|hand", true)
		local log = sgs.LogMessage()
			log.type = "#anzhou"
			log.from = damage.to
			log.arg = self:objectName()
		room:sendLog(log)
	end,
}
Mhuanwu = sgs.CreateTriggerSkill{
	name = "Mhuanwu", 
	frequency = sgs.Skill_Limited,
	limit_mark = "@huanwu_use",
	events = {sgs.EventPhaseEnd, sgs.Damage},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if event == sgs.EventPhaseEnd then
				if player:getPhase() == sgs.Player_Play and player:isWounded() and player:getMark("@huanwu_use") == 1 then
					local weapon
					for _, card in sgs.qlist(player:getCards("he")) do
						if card:isKindOf("Weapon") then
							weapon = true
							break
						end
					end
					if weapon then
						local slash = sgs.Sanguosha:cloneCard("slash")
						slash:setSkillName(self:objectName())
						local targets = sgs.SPlayerList()
						for _,p in sgs.qlist(room:getOtherPlayers(player)) do
							if p:hasShownOneGeneral() and not (player:isFriendWith(p) or player:willBeFriendWith(p)) and not p:inMyAttackRange(player) and player:canSlash(p,slash,false) then
								targets:append(p)
							end
						end
						if not targets:isEmpty() then
							return self:objectName()
						end
					end
				end
			else
				local damage = data:toDamage()
				if damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName(false) == self:objectName() then
					if damage.to:isAlive() and not (damage.chain or damage.transfer) and damage.to:getMark("@zhongdu_shade") == 0 and damage.to:getMark("@zhongdu_chakram") == 0 then
						return self:objectName()
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if event == sgs.EventPhaseEnd then
			if room:askForCard(player, "Weapon", "@huanwu_invoke", data, sgs.Card_MethodDiscard) then
				room:setPlayerMark(player, "@huanwu_use", 0)
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:doSuperLightbox("Mchakram", self:objectName())
				return true
			end
		else
			room:broadcastSkillInvoke(self:objectName(), 2)
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		if event == sgs.EventPhaseEnd then
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:setSkillName(self:objectName())
			local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasShownOneGeneral() and not (player:isFriendWith(p) or player:willBeFriendWith(p)) and not p:inMyAttackRange(player) and player:canSlash(p,slash,false) then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				local use = sgs.CardUseStruct()
					use.from = player
					use.to = targets
					use.card = slash
				room:useCard(use, false)
			end
		else
			local damage = data:toDamage()
			room:setPlayerMark(damage.to, "@zhongdu_chakram", 1)
			local log = sgs.LogMessage()
				log.type = "#zhongdu"
				log.from = damage.to
			room:sendLog(log)
		end
	end,
}
Mhuanwu_recover = sgs.CreateTriggerSkill{
	name = "#Mhuanwu_recover", 
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim},
	can_trigger = function(self, event, room, player, data)
		local chakram =  room:findPlayerBySkillName("Mhuanwu")
		if chakram and chakram:isAlive() and chakram:getMark("@huanwu_use") == 0 then
			if player:objectName() == chakram:objectName() then return "" end
			local death = data:toDeath()
			local damage = death.damage
			if damage and damage.from and damage.from and damage.from:objectName() == chakram:objectName() then
				room:broadcastSkillInvoke("Mhuanwu", 3)
				room:notifySkillInvoked(chakram, self:objectName())
				room:setPlayerMark(chakram, "@huanwu_use", 1)
				local log = sgs.LogMessage()
					log.type = "#huanwu"
					log.from = chakram
				room:sendLog(log)
			end
		end
		return ""
	end,
}
Mhuanwu_effect = sgs.CreateTriggerSkill{
	name = "#Mhuanwu_effect", 
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:getMark("@zhongdu_chakram") == 1 then
			if player:getPhase() == sgs.Player_Draw and player:isWounded() then
				room:notifySkillInvoked(player, self:objectName())
				local judge = sgs.JudgeStruct()
					judge.who = player
					judge.pattern = ".|heart|."
					judge.good = true
					judge.reason = self:objectName()
					judge.play_animation = true
					judge.negative = false
				room:judge(judge)
				if judge:isGood() then
					room:broadcastSkillInvoke("Mhuanwu", 4)
					room:setPlayerMark(player, "@zhongdu_chakram", 0)
				else
					if judge.card:getSuit() == sgs.Card_Spade then
						room:broadcastSkillInvoke("Mhuanwu", 5)
						if player:isWounded() then
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
					elseif judge.card:getSuit() == sgs.Card_Club or judge.card:getSuit() == sgs.Card_Diamond then
						room:broadcastSkillInvoke("Mhuanwu", 6)
						room:setPlayerFlag(player, "zhongdu_draw_chakram")
					end
				end
			end
		end
		return ""
	end,
}
Mhuanwu_draw = sgs.CreateDrawCardsSkill{
	name = "#Mhuanwu_draw",
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasFlag("zhongdu_draw_chakram") then
			return self:objectName()
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		room:setPlayerFlag(player, "-zhongdu_draw_chakram")
		return true
	end,
	draw_num_func = function(self,player,n)
		return n-1
	end,
}
--武将加入技能“暗咒”“环舞”
Mchakram:addSkill(Manzhou)
Mchakram:addSkill(Mhuanwu)
Mchakram:addSkill(Mhuanwu_recover)
Mchakram:addSkill(Mhuanwu_effect)
Mchakram:addSkill(Mhuanwu_draw)
Ashan2:insertRelatedSkills("Mhuanwu", "#Mhuanwu_recover")
Ashan2:insertRelatedSkills("Mhuanwu", "#Mhuanwu_effect")
Ashan2:insertRelatedSkills("Mhuanwu", "#Mhuanwu_draw")
--翻译表
sgs.LoadTranslationTable{
    ["Mchakram"] = "环刃舞者",
	["&Mchakram"] = "环刃舞者",
	["#Mchakram"] = "死亡之舞",
	["Manzhou"] = "暗咒",
	["@anzhou"] = "暗咒",
	["$Manzhou1"] = "优雅的记号。",
	["$Manzhou2"] = "噢不。",
	["#anzhou"] = "由于 %arg 的效果，%from 无法打出、使用和弃置锦囊牌直到其回合结束！",
	[":Manzhou"] = "当你对其他角色造成一次伤害后，你可以令其不能使用、打出或弃置锦囊牌直到其回合结束。",
	["Mhuanwu"] = "环舞",
	["#Mhuanwu_recover"] = "环舞",
	["#Mhuanwu_effect"] = "中毒",
	["#Mhuanwu_draw"] = "中毒",
	["$Mhuanwu1"] = "被选中去死是你的荣幸。",
	["$Mhuanwu2"] = "幻影潜入！",
	["$Mhuanwu3"] = "第一个死难者。",
	["$Mhuanwu4"] = "不达目的我誓不罢休。",
	["$Mhuanwu5"] = "一切按计划进行中。",
	["$Mhuanwu6"] = "不浪费任何机会。",
	["#huanwu"] = "%from 的刀锋已经再生！",
	["@huanwu_invoke"] = "是否弃置一张武器牌发动技能“环舞”？",
	["@huanwu_use"] = "环舞使用",
	[":Mhuanwu"] = "限定技，出牌阶段结束时，若你已受伤，你可以弃置一张武器牌视为对攻击范围内不含你的其他势力角色使用了一张附带毒属性的【杀】。锁定技，当你杀死一名其他角色后，若你发动过此技能，你重置此技能。\n\n“毒”\n锁定技，当目标角色被“毒”属性的【杀】造成伤害时，其进入“中毒”状态（“毒”属性的不改变【杀】的原有属性）。\n\n“中毒”\n锁定技，“中毒”的角色在其摸牌阶段开始时，若其已受伤其进行一次判定：若结果为黑桃，其弃置等同于已损失体力数的手牌否则失去1点体力；若结果为梅花或方块，其少摸一张牌；若结果为红桃，其解除“中毒”状态。",
	["~Mchakram"] = "我让魅影之纱失望了！",
	["cv:Mchakram"] = "幻影刺客",
	["illustrator:Mchakram"] = "英雄无敌6",
	["designer:Mchakram"] = "月兔君",
}

--[[
   创建武将【阴影凝视者】
]]--
Mwatcher = sgs.General(Ashan2, "Mwatcher", "mi", 3)
--[[
*【窥视】其他角色出牌阶段开始时，若其有手牌，你可以交给其一张锦囊牌并观看其手牌：若其与你的势力不同，你弃置其X+1张手牌（X为你已损失体力且最大为2）。
*【折虐】当你被其他角色使用【杀】指定为目标后，你可以弃置其一张手牌（若你已受伤，改为获得之）。
]]--
Mkuishi = sgs.CreateTriggerSkill{
	name = "Mkuishi", 
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and not player:isKongcheng() then
			if player:getPhase() == sgs.Player_Play then
				local watcher =  room:findPlayerBySkillName(self:objectName())
				if watcher and watcher:isAlive() and not watcher:isKongcheng() and player:objectName() ~= watcher:objectName() then
					local trick
					for _, card in sgs.list(watcher:getHandcards()) do
					    if card:isKindOf("TrickCard") then
						    trick = true
							break
						end
					end
					if trick then
						return self:objectName(), watcher
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		local watcher =  room:findPlayerBySkillName(self:objectName())
		local ai_data = sgs.QVariant()
		ai_data:setValue(player)
		local id = room:askForCard(watcher, "TrickCard", "@kuishi_invoke", ai_data, sgs.Card_MethodNone)
		if id then
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:obtainCard(player, id, true)
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local watcher =  room:findPlayerBySkillName(self:objectName())
		if not player:hasShownOneGeneral() then
			room:showAllCards(player, watcher)
		else
			if not player:isFriendWith(watcher) then
				local x = watcher:getLostHp() + 1
				local hand_ids = sgs.IntList()
				for _, card in sgs.qlist(player:getHandcards()) do
					hand_ids:append(card:getId())
				end
				local emptycard = MemptyCard:clone()
				for i = 1 , x, 1 do
					room:fillAG(hand_ids, watcher)
					local id = room:askForAG(watcher, hand_ids, false, self:objectName())
					if id then
						hand_ids:removeOne(id)
						room:clearAG()
						emptycard:addSubcard(sgs.Sanguosha:getCard(id))
					end
				end
				if emptycard:subcardsLength() > 0 then
					room:broadcastSkillInvoke(self:objectName(), 2)
					room:throwCard(emptycard, player, watcher)
				end
			end
		end
	end,
}
Mzhenue = sgs.CreateTriggerSkill{
	name = "Mzhenue", 
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local use = data:toCardUse()
			if use.card and use.from and not use.from:isKongcheng() and use.card:isKindOf("Slash") and use.to:contains(player) then
				if player:objectName() ~= use.from:objectName() then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if room:askForSkillInvoke(player, self:objectName(), data) then
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local use = data:toCardUse()
		local id = room:askForCardChosen(player, use.from, "h", self:objectName())
		if player:isWounded() then
			room:broadcastSkillInvoke(self:objectName(), 2)
			room:obtainCard(player, id, false)
		else
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:throwCard(id, use.from, player)
		end
	end,
}
--武将加入技能“窥视”“折虐”
Mwatcher:addSkill(Mkuishi)
Mwatcher:addSkill(Mzhenue)
--翻译表
sgs.LoadTranslationTable{
    ["Mwatcher"] = "阴影凝视者",
	["&Mwatcher"] = "阴影凝视者",
	["#Mwatcher"] = "神秘探知",
	["Mkuishi"] = "窥视",
	["$Mkuishi1"] = "真正的噩梦！",
	["$Mkuishi2"] = "是时候说晚安啦。",
	["@kuishi_invoke"] = "你是否交给当前回合角色一张锦囊牌发动技能“窥视”？",
	[":Mkuishi"] = "其他角色出牌阶段开始时，若其有手牌，你可以交给其一张锦囊牌并观看其手牌：若其与你的势力不同，你弃置其X+1张手牌（X为你已损失体力且最大为2）。",
	["Mzhenue"] = "折虐",
	["$Mzhenue1"] = "恐惧已占有你的内心。",
	["$Mzhenue2"] = "以备不时之需。",
	[":Mzhenue"] = "当你被其他角色使用【杀】指定为目标后，你可以弃置其一张手牌（若你已受伤，改为获得之）。",
	["~Mwatcher"] = "真正的噩梦……",
	["cv:Mwatcher"] = "祸乱之源",
	["illustrator:Mwatcher"] = "英雄无敌6",
	["designer:Mwatcher"] = "月兔君",
}

--[[
   创建武将【毒蝎狮】
]]--
Mscorpicore = sgs.General(Ashan2, "Mscorpicore", "mi", 4)
--[[
【瘫痪】锁定技，当你使用【杀】对目标角色造成一次伤害后，对方无法使用手牌中的基本牌和装备牌直到其回合结束。
【腐蚀】副将技，锁定技，此武将牌上单独的阴阳鱼个数-1。副将技，当你使用【杀】指定目标后，你可以将其装备区一张牌返回至手牌。
【溶解】主将技，锁定技，当你进入濒死时，若你装备区有牌，你弃置装备区所有牌并回复体力至1。
]]--
Mtanhuan = sgs.CreateTriggerSkill{
	name = "Mtanhuan", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damage, sgs.EventPhaseChanging},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.Damage then
			if player and player:isAlive() and player:hasSkill(self:objectName()) then
				local damage = data:toDamage()
				if damage.card and damage.card:isKindOf("Slash") and not (damage.chain or damage.transfer) then
					if damage.to:isAlive() and damage.to:getMark("@tanhuan") == 0 then
						return self:objectName()
					end
				end
			end
		else
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:getMark("@tanhuan") == 1 then
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:setPlayerMark(player, "@tanhuan", 0)
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local damage = data:toDamage()
		room:setPlayerMark(damage.to, "@tanhuan", 1)
		room:setPlayerCardLimitation(damage.to, "use", "BasicCard,EquipCard|.|.|hand", true)
		local log = sgs.LogMessage()
			log.type = "#tanhuan"
			log.from = damage.to
			log.arg = self:objectName()
		room:sendLog(log)
	end,
}
Mscorpicore:setDeputyMaxHpAdjustedValue(-1)
Mfushi = sgs.CreateTriggerSkill{
	name = "Mfushi", 
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetChosen},
	relate_to_place = "deputy",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") then
				local targets_names = {}
				for _,p in sgs.qlist(use.to) do
					if p:hasEquip() then
						table.insert(targets_names,p:objectName())
					end	
				end
				if #targets_names > 0 then
					return self:objectName() .. "->" .. table.concat(targets_names, "+"), player
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, target, data, player)
		local ai_data = sgs.QVariant()
		ai_data:setValue(target)
		if player:askForSkillInvoke(self:objectName(), ai_data) then
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, target, data, player)
		local id = room:askForCardChosen(player, target, "e", self:objectName())
		room:obtainCard(target, id, true)
	end,
}
Mrongjie = sgs.CreateTriggerSkill{
	name = "Mrongjie",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Dying},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local dying = data:toDying()
		    if dying.who:objectName() == player:objectName() and player:hasEquip() then
				return self:objectName(), player
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			player:throwAllEquips()
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local x = 1 - player:getHp()
		local recover = sgs.RecoverStruct()
			recover.recover = x
		room:recover(player, recover)
	end,
}
--武将加入技能“瘫痪”“溶解”“腐蚀”
Mscorpicore:addSkill(Mtanhuan)
Mscorpicore:addSkill(Mrongjie)
Mscorpicore:addSkill(Mfushi)
--翻译表
sgs.LoadTranslationTable{
    ["Mscorpicore"] = "毒蝎狮",
	["&Mscorpicore"] = "毒蝎狮",
	["#Mscorpicore"] = "致命毒素",
	["Mtanhuan"] = "瘫痪",
	["$Mtanhuan1"] = "折磨我们的敌人。",
	["$Mtanhuan2"] = "嘿，浪费了！",
	["@tanhuan"] = "瘫痪",
	["#tanhuan"] = "%from 无法使用基本牌和装备牌直到其回合结束。",
	[":Mtanhuan"] = "锁定技，当你使用【杀】对目标角色造成一次伤害后，对方无法使用手牌中的基本牌和装备牌直到其回合结束。",
	["Mrongjie"] = "溶解",
	["$Mrongjie"] = "从危险的边缘回归。",
	[":Mrongjie"] = "主将技，锁定技，当你进入濒死时，若你装备区有牌，你弃置装备区所有牌并回复体力至1。",
	["Mfushi"] = "腐蚀",
	["$Mfushi"] = "腐蚀殆尽。",
	[":Mfushi"] = "副将技，锁定技，此武将牌上单独的阴阳鱼个数-1。副将技，当你使用【杀】指定目标后，你可以将其装备区一张牌返回至手牌。",
	["~Mscorpicore"] = "该死的解药！",
	["cv:Mscorpicore"] = "剧毒术士",
	["illustrator:Mscorpicore"] = "英雄无敌6",
	["designer:Mscorpicore"] = "月兔君",
}

--[[
   创建武将【无面者傀儡师】
]]--
Mfaceless = sgs.General(Ashan2, "Mfaceless", "mi", 4)
--珠联璧合：阴影凝视者、毒蝎狮
Mfaceless:addCompanion("Mwatcher")
Mfaceless:addCompanion("Mscorpicore")
--[[
*【影击】当你使用【杀】对目标角色造成一次伤害时，你可以防止该伤害并选择一项：1.令其体力上限-1，直到其造成一次伤害；2.令其选择弃置其一个区域内所有牌。
*【操纵】主将技，锁定技，此武将牌上单独的阴阳鱼个数-1。主将技，弃牌阶段开始时，若你手牌数不大于体力上限，你可以暗中指定一名攻击范围内的其他势力角色：该角色下一个出牌阶段结束时，你获得其在该阶段使用的所有牌。
*【侵袭】副将技，与你势力相同的角色出牌阶段开始时，若其下家手牌数大于你，其可以将一张手牌暗置于牌堆顶令你获得其下家一张手牌。
]]--
Myingji = sgs.CreateTriggerSkill{
	name = "Myingji",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if damage.to and damage.to:isAlive() and damage.card and damage.card:isKindOf("Slash") and not (damage.chain or damage.transfer) then
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
		local damage = data:toDamage()
		if not damage.to:isAllNude() then
			choice = room:askForChoice(player, self:objectName(), "yingji_hp+yingji_throw", data)
		else
			choice = "yingji_hp"
		end
		if choice == "yingji_hp" then
			room:broadcastSkillInvoke(self:objectName(), 1)
			local log = sgs.LogMessage()
				log.type = "#yingji1"
				log.from = damage.to
			room:sendLog(log)
			room:loseMaxHp(damage.to)
			local x = damage.to:getMark("@yingji")
			room:setPlayerMark(damage.to, "@yingji", x+1)
		else
			if not damage.to:isKongcheng() then
				if damage.to:hasEquip() then
					if damage.to:getJudgingArea():length() > 0 then
						choice = room:askForChoice(damage.to, "yingji_throw", "yingji_hand+yingji_equip+yingji_judge", data)
					else
						choice = room:askForChoice(damage.to, "yingji_throw", "yingji_hand+yingji_equip", data)
					end
				else
					if damage.to:getJudgingArea():length() > 0 then
						choice = room:askForChoice(damage.to, "yingji_throw", "yingji_hand+yingji_judge", data)
					else
						choice = "yingji_hand"
					end
				end
			else
				if damage.to:hasEquip() then
					if damage.to:getJudgingArea():length() > 0 then
						choice = room:askForChoice(damage.to, "yingji_throw", "yingji_equip+yingji_judge", data)
					else
						choice = "yingji_equip"
					end
				else
					if damage.to:getJudgingArea():length() > 0 then
						choice = "yingji_judge"
					end
				end
			end
			if choice == "yingji_hand" then
				room:broadcastSkillInvoke(self:objectName(), 2)
				damage.to:throwAllHandCards()
			elseif choice == "yingji_equip" then
				room:broadcastSkillInvoke(self:objectName(), 3)
				damage.to:throwAllEquips()
			else
				local emptycard = MemptyCard:clone()
				for _,card in sgs.qlist(damage.to:getJudgingArea()) do
					emptycard:addSubcard(card)
				end
				room:broadcastSkillInvoke(self:objectName(), 4)
				room:throwCard(emptycard, damage.to)
			end
		end
		return true
	end,
}
Myingji_avoid = sgs.CreateTriggerSkill{
	name = "#Myingji_avoid",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:getMark("@yingji") > 0 then
			room:broadcastSkillInvoke("yingji", 5)
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp()+player:getMark("@yingji")))
			room:setPlayerMark(player, "@yingji", 0)
			local log = sgs.LogMessage()
				log.type = "#yingji2"
				log.from = player
			room:sendLog(log)
			room:notifySkillInvoked(player, self:objectName())
		end
	end,
}
Mfaceless:setHeadMaxHpAdjustedValue(-1)
Mcaozong = sgs.CreateTriggerSkill{
    name = "Mcaozong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart then
			if player and player:isAlive() and player:hasSkill(self:objectName()) then
				if player:getPhase() == sgs.Player_Discard then
					if player:getHandcardNum() <= player:getMaxHp() then
						local targets = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							if p:hasShownOneGeneral() and not (player:isFriendWith(p) or player:willBeFriendWith(p)) and player:inMyAttackRange(p) and p:getMark("caozong") == 0 then
								targets:append(p)
							end
						end
						if not targets:isEmpty() then
							return self:objectName()
						end
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			if player and player:isAlive() and player:getMark("caozong") == 1 and player:getPhase() == sgs.Player_Play then
				local move = data:toMoveOneTime()
				if move.from and player:objectName() == move.from:objectName() then
					local allrea = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					local caozong_list = player:getTag("caozong_tag"):toList()
					for _, id in sgs.qlist(move.card_ids) do 
						if allrea == sgs.CardMoveReason_S_REASON_USE then
							if not caozong_list:contains(sgs.QVariant(id)) then
								caozong_list:append(sgs.QVariant(id))
							end
						end
					end
					player:setTag("caozong_tag", sgs.QVariant(caozong_list))
				end
			end
		else
			if player:getMark("caozong") == 1 and player:getPhase() == sgs.Player_Play then
				room:setPlayerMark(player, "caozong", 0)
				local faceless = room:findPlayerBySkillName(self:objectName())
				if faceless and faceless:isAlive() then
					if player:getTag("caozong_tag") then
						local caozong_list = player:getTag("caozong_tag"):toList()
						player:removeTag("caozong_tag")
						local caozong_cards = sgs.IntList()
						for _,data_id in sgs.qlist(caozong_list) do 
							local card_id = data_id:toInt()
							if card_id then
								caozong_cards:append(card_id)
							end
						end
						local emptycard = MemptyCard:clone()
						for _, id in sgs.qlist(caozong_cards) do
							emptycard:addSubcard(id)
						end
						if emptycard:subcardsLength() > 0 then
							room:broadcastSkillInvoke(self:objectName(), 2)
							faceless:obtainCard(emptycard, true)
							room:getThread():delay(1000)
						end
					else
						room:broadcastSkillInvoke(self:objectName(), 3)
					end
				end
				if player:getTag("caozong_tag") then
					player:removeTag("caozong_tag")
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
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasShownOneGeneral() and not (player:isFriendWith(p) or player:willBeFriendWith(p)) and player:inMyAttackRange(p) and p:getMark("caozong") == 0 then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, self:objectName())
			room:setPlayerMark(target, "caozong", 1)
		end
	end,
}
Mqinxi = sgs.CreateTriggerSkill{
    name = "Mqinxi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	relate_to_place = "deputy",
	can_preshow = false,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:getPhase() == sgs.Player_Play then
			if not player:isKongcheng() and player:hasShownOneGeneral() then
				local target = player:getNextAlive()
				if target:isKongcheng() then return "" end
				local faceless = room:findPlayerBySkillName(self:objectName())
				if faceless and faceless:isAlive() and faceless:hasShownSkill(self) and player:objectName() ~= faceless:objectName() and player:isFriendWith(faceless) then
					if target:getHandcardNum() > faceless:getHandcardNum() then
						return self:objectName(), faceless
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		local card = room:askForCard(player, ".|.|.|hand", "@qinxi_invoke", data, sgs.Card_MethodNone)
		if card then
			room:broadcastSkillInvoke(self:objectName())
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(),"", self:objectName(), "")
            room:moveCardTo(card, nil, nil, sgs.Player_DrawPile, reason, false)
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local faceless = room:findPlayerBySkillName(self:objectName())
		local target = player:getNextAlive()
		if not target:isKongcheng() then
			local id = room:askForCardChosen(faceless, target, "h", self:objectName())
			room:obtainCard(faceless, id, false)
		end
	end,
}
--武将加入技能“影击”“清洗”“操纵”
Mfaceless:addSkill(Myingji)
Mfaceless:addSkill(Myingji_avoid)
Mfaceless:addSkill(Mcaozong)
Mfaceless:addSkill(Mqinxi)
Ashan2:insertRelatedSkills("Myingji", "#Myingji_avoid")
--翻译表
sgs.LoadTranslationTable{
    ["Mfaceless"] = "无面者傀儡师",
	["&Mfaceless"] = "无面者傀儡师",
	["#Mfaceless"] = "沉默之声",
	["Myingji"] = "影击",
	["$Myingji1"] = "碾压你的灵魂！",
	["$Myingji2"] = "黑暗环绕！",
	["$Myingji3"] = "看我灵魂法杖！",
	["$Myingji4"] = "暗黑会治愈你。",
	["$Myingji5"] = "（叹气）",
	["yingji_hp"] = "撕裂灵魂",
	["yingji_throw"] = "破坏躯体",
	["@yingji"] = "影击",
	["yingji_equip"] = "装备区",
	["yingji_hand"] = "手牌区",
	["yingji_judge"] = "判定区",
	["#yingji1"] = "%from 暂时降低体力上限直到其造成一次伤害！",
	["#yingji2"] = "%from 体力上限恢复了正常！",
	[":Myingji"] = "当你使用【杀】对目标角色造成一次伤害时，你可以防止该伤害并选择一项：1.令其体力上限-1，直到其造成一次伤害；2.令其选择弃置其一个区域内所有牌。",
	["Mqinxi"] = "侵袭",
	["$Mqinxi"] = "如我的魔典一般，我将永存。",
	["@qinxi_invoke"] = "是否将一张手牌暗置于牌堆顶发动技能“侵袭”？",
	[":Mqinxi"] = "副将技，与你势力相同的角色出牌阶段开始时，若其下家手牌数大于你，其可以将一张手牌暗置于牌堆顶令你获得其下家一张手牌。",
	["Mcaozong"] = "操纵",
	["$Mcaozong1"] = "与黑暗作伴吧！",
	["$Mcaozong2"] = "我的魔典里又多了一个名字。",
	["$Mcaozong3"] = "小角色！",
--	["@caozong"] = "操纵",
	[":Mcaozong"] = "主将技，锁定技，此武将牌上单独的阴阳鱼个数-1。主将技，弃牌阶段开始时，若你手牌数不大于体力上限，你可以暗中指定一名攻击范围内的其他势力角色：该角色下一个出牌阶段结束时，你获得其在该阶段使用的所有牌。",
	["~Mfaceless"] = "暗影包围了你！",
	["cv:Mfaceless"] = "术士",
	["illustrator:Mfaceless"] = "英雄无敌6",
	["designer:Mfaceless"] = "月兔君",
}

--[[
   创建武将【牛头卫士】
]]--
Mminotaur = sgs.General(Ashan2, "Mminotaur", "mi", 4)
--[[
*【先攻】你攻击范围内其他角色出牌阶段开始时，若你手牌数不小于对方，你可以执行一次额外的出牌阶段。
*【压制】锁定技，当你对攻击范围内其他势力角色造成一次伤害后，若其体力小于你，你摸一张牌。
]]--
Mxiangong = sgs.CreateTriggerSkill{
	name = "Mxiangong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:getPhase() == sgs.Player_Play then
			local minotaur =  room:findPlayerBySkillName(self:objectName())
			if minotaur and minotaur:isAlive() then
				if minotaur:inMyAttackRange(player) and minotaur:getHandcardNum() >= player:getHandcardNum() and player:objectName() ~= minotaur:objectName() then
					return self:objectName(), minotaur
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		local minotaur =  room:findPlayerBySkillName(self:objectName())
		if room:askForSkillInvoke(minotaur, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			room:setPlayerMark(player, "@xiangong", 1)
			local log = sgs.LogMessage()
				log.type = "#xiangong1"
				log.from = minotaur
			room:sendLog(log)
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local minotaur =  room:findPlayerBySkillName(self:objectName())
		room:getThread():delay(500)
		minotaur = getServerPlayer(room, minotaur:objectName())
		local phases = sgs.PhaseList()
		phases:append(sgs.Player_Play)
		minotaur:play(phases)
		room:setPlayerMark(player, "@xiangong", 0)
		local log = sgs.LogMessage()
			log.type = "#xiangong2"
			log.from = minotaur
		room:sendLog(log)
		room:getThread():delay(500)
	end,
}
Myazhi = sgs.CreateTriggerSkill{
	name = "Myazhi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if damage.to and damage.to:hasShownOneGeneral() and not (player:isFriendWith(damage.to) or player:willBeFriendWith(damage.to)) and player:getHp() > damage.to:getHp() and player:inMyAttackRange(damage.to) then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or room:askForSkillInvoke(player, self:objectName(), data) then
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
--武将加入技能“先攻”“压制”
Mminotaur:addSkill(Mxiangong)
Mminotaur:addSkill(Myazhi)
--翻译表
sgs.LoadTranslationTable{
    ["Mminotaur"] = "牛头卫士",
	["&Mminotaur"] = "牛头卫士",
	["#Mminotaur"] = "忠心耿耿",
	["Mxiangong"] = "先攻",
	["@xiangong"] = "先攻",
	["$Mxiangong"] = "赛场由我主宰！",
	["#xiangong1"] = "%from 执行一个额外的出牌阶段！",
	["#xiangong2"] = "%from 的额外的出牌阶段结束！",
	[":Mxiangong"] = "你攻击范围内其他角色出牌阶段开始时，若你手牌数不小于对方，你可以执行一次额外的出牌阶段。",
	["Myazhi"] = "压制",
	["$Myazhi"] = "在我面前战栗吧！",
	[":Myazhi"] = "锁定技，当你对攻击范围内其他势力角色造成一次伤害后，若其体力小于你，你摸一张牌。",
	["~Mminotaur"] = "人们遗忘了我！",
	["cv:Mminotaur"] = "半人马酋长",
	["illustrator:Mminotaur"] = "英雄无敌6",
	["designer:Mminotaur"] = "月兔君",
}

--[[
   创建武将【黑龙】
]]--
Mblackdragon = sgs.General(Ashan2, "Mblackdragon", "mi", 4)
--[[
*【龙息】出牌阶段开始时，若你手牌数大于体力，你可以弃置X张手牌指定至多X名攻击范围外的其他角色，视为你对他们使用了一张【火杀】（X为超出体力的牌数）。
*【龙威】锁定技，若你已受伤，你与其他角色的距离+X，其他角色与你的距离+X（X为你已损失体力数）。
*【龙麟】锁定技，当你成为【过河拆桥】和【顺手牵羊】以外的非延时锦囊的目标时，若你已受伤，你取消之。
]]--
Mlongxi = sgs.CreateTriggerSkill{
	name = "Mlongxi", 
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Play and player:getHandcardNum() > player:getHp() then
				local slash = sgs.Sanguosha:cloneCard("fire_slash")
				slash:setSkillName(self:objectName())
				local targets = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if not player:inMyAttackRange(p) and player:canSlash(p,slash,false) then
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
		if room:askForSkillInvoke(player, self:objectName(), data) then
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local x = player:getHandcardNum() - player:getHp()
		if x <= 0 then return false end
		room:askForDiscard(player, self:objectName(), x, x, false, false)
		local slash = sgs.Sanguosha:cloneCard("fire_slash")
		slash:setSkillName(self:objectName())
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if not player:inMyAttackRange(p) and player:canSlash(p,slash,false) then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local real_targets = sgs.SPlayerList()
			local m = 0
			local target
			while not targets:isEmpty() do
				if m == 0 then
					target = room:askForPlayerChosen(player, targets, self:objectName())
				else
					target = room:askForPlayerChosen(player, targets, self:objectName(), "", true)
				end
				if target then
					m = m+1
					real_targets:append(target)
					targets:removeOne(target)
					if m == x then
						break
					end
				else
					break
				end
			end
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasFlag("longxi_target") then
					room:setPlayerFlag(p, "-longxi_target")
				end
			end
			if not real_targets:isEmpty() then
				if x == 1 then
					room:broadcastSkillInvoke(self:objectName(), 1)
				elseif x == 2 then
					room:broadcastSkillInvoke(self:objectName(), 2)
				else
					room:broadcastSkillInvoke(self:objectName(), 3)
				end
				local use = sgs.CardUseStruct()
					use.from = player
					use.to = real_targets
					use.card = slash
				room:useCard(use, false)
			end
		end
	end,
}
Mlongwei = sgs.CreateDistanceSkill{
	name = "Mlongwei",
	correct_func = function(self, from, to)
		if from:objectName() ~= to:objectName() then
			if to:hasSkill(self:objectName()) and to:hasShownSkill(self) and to:isWounded() then
				local x = math.min(2,to:getLostHp())
				return x
			end
			if from:hasSkill(self:objectName()) and from:hasShownSkill(self) and from:isWounded() then
				local x = math.min(2,from:getLostHp())
				return x
			end
		end
	end,
}
Mlonglin = sgs.CreateTriggerSkill{
	name = "Mlonglin",  
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirming},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and player:isWounded() then
			local use = data:toCardUse()
			if use.card and use.card:isNDTrick() and use.to:contains(player) and not (use.card:isKindOf("Dismantlement") or use.card:isKindOf("Snatch")) then
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
		local use = data:toCardUse()
		sgs.Room_cancelTarget(use, player)
		data:setValue(use)
		return false
	end,
}
--武将加入技能“龙息”“龙威”“龙麟”
Mblackdragon:addSkill(Mlongxi)
Mblackdragon:addSkill(Mlongwei)
Mblackdragon:addSkill(Mlonglin)
--翻译表
sgs.LoadTranslationTable{
    ["Mblackdragon"] = "黑龙",
	["&Mblackdragon"] = "黑龙",
	["#Mblackdragon"] = "最终传奇",
	["Mlongxi"] = "龙息",
	["$Mlongxi1"] = "焚天烈焰！",
	["$Mlongxi2"] = "灼烧吧！",
	["$Mlongxi3"] = "在烈焰中倒下吧！",
	[":Mlongxi"] = "出牌阶段开始时，若你手牌数大于体力，你可以弃置X张手牌指定至多X名攻击范围外的其他角色，视为你对他们使用了一张【火杀】（X为超出体力的牌数）。",
	["Mlongwei"] = "龙威",
	[":Mlongwei"] = "锁定技，若你已受伤，你与其他角色的距离+X，其他角色与你的距离+X（X为你已损失体力数且最大为2）。",
	["Mlonglin"] = "龙麟",
	["$Mlonglin"] = "我的天空我做主。",
	[":Mlonglin"] = "锁定技，当你成为【过河拆桥】和【顺手牵羊】以外的非延时锦囊的目标时，若你已受伤，你取消之。",
	["~Mblackdragon"] = "你这是屠龙！",
	["cv:Mblackdragon"] = "双头巨龙",
	["illustrator:Mblackdragon"] = "英雄无敌6",
	["designer:Mblackdragon"] = "月兔君",
}

--[[
   创建武将【虚空化身】
]]--
Mvoid = sgs.General(Ashan2, "Mvoid", "mi", 3)
--[[
*【否定】你攻击范围内其他角色摸牌阶段结束时，若其体力大于你，你可以令其视为对其自身使用了一张【雷杀】：当其因此而受到伤害进行的伤害结算结束时，若其手牌数大于你，你获得其一张手牌。
*【黑镜】主将技，锁定技，当你受到一名其他角色造成的伤害时：若你未受伤，你有1/2的概率防止该伤害；若你你已受伤，你有1/3的概率防止该伤害，且有1/3的概率将伤害转移给来源。
*【不详】副将技，锁定技，你攻击范围内体力不小于你的其他势力的角色出牌阶段最多使用X张非装备手牌（X为你的当前体力）。
]]--
Mfouding = sgs.CreateTriggerSkill{
    name = "Mfouding",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd, sgs.DamageComplete},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseEnd then
			if player and player:isAlive() and player:getPhase() == sgs.Player_Draw then
				local void =  room:findPlayerBySkillName(self:objectName())
				if void and void:isAlive() and player:getHp() > void:getHp() and void:inMyAttackRange(player) then
					return self:objectName(), void
				end
			end
		else
			if not player:hasFlag("fouding_he") then return "" end
			room:setPlayerFlag(player, "-fouding_he")
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName(false) == self:objectName() then
				local void =  room:findPlayerBySkillName(self:objectName())
				if void and void:isAlive() and player:getHandcardNum() > void:getHandcardNum() then
					room:broadcastSkillInvoke(self:objectName(), 2)
					local id = room:askForCardChosen(void, player, "h", self:objectName())
					room:obtainCard(void, id, false)
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		local void =  room:findPlayerBySkillName(self:objectName())
		local ai_data = sgs.QVariant()
		ai_data:setValue(player)
		if void:askForSkillInvoke(self:objectName(), ai_data) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local slash = sgs.Sanguosha:cloneCard("thunder_slash")
		slash:setSkillName(self:objectName())
		room:setPlayerFlag(player, "fouding_he")
		local use = sgs.CardUseStruct()
			use.from = player
			use.to:append(player)
			use.card = slash
		room:useCard(use, false)
	end,
}
Mheijing = sgs.CreateTriggerSkill{
	name = "Mheijing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	relate_to_place = "head",
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() ~= player:objectName() then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self) or player:askForSkillInvoke(self:objectName(), data) then
			room:notifySkillInvoked(player, self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local damage = data:toDamage()
		local target = damage.from
		if not player:isWounded() then
			if math.random() < 0.5 then
				room:broadcastSkillInvoke(self:objectName(), 1)
				local log = sgs.LogMessage()
					log.type = "#heijing1"
					log.from = player
					log.arg = self:objectName()
				room:sendLog(log)
				return true
			else
				room:broadcastSkillInvoke(self:objectName(), 3)
				local log = sgs.LogMessage()
					log.type = "#heijing3"
					log.arg = self:objectName()
				room:sendLog(log)
			end
		else
			local n = math.random(1,3)
			if n == 1 then
				room:broadcastSkillInvoke(self:objectName(), 1)
				local log = sgs.LogMessage()
					log.type = "#heijing1"
					log.from = player
					log.arg = self:objectName()
				room:sendLog(log)
				return true
			elseif n == 2 then
				room:broadcastSkillInvoke(self:objectName(), 2)
				local log = sgs.LogMessage()
					log.type = "#heijing2"
					log.from = player
					log.to:append(target)
					log.arg = self:objectName()
				room:sendLog(log)
				room:getThread():delay(1500)
				local damage = data:toDamage()
					damage.transfer = true
					damage.to = target
					damage.transfer_reason = "Mheijing"
					local realdamage = sgs.QVariant()
					realdamage:setValue(damage)
				player:setTag("TransferDamage" , realdamage)
				return true
			else
				room:broadcastSkillInvoke(self:objectName(), 3)
				local log = sgs.LogMessage()
					log.type = "#heijing3"
					log.arg = self:objectName()
				room:sendLog(log)
			end
		end
	end,
}
Mbuxiang = sgs.CreateTriggerSkill{
	name = "Mbuxiang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreCardUsed, sgs.EventPhaseEnd},
	relate_to_place = "deputy",
	can_preshow = false,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() then
			if event == sgs.PreCardUsed then
				if player:hasShownOneGeneral() and player:getPhase() == sgs.Player_Play then
					local void =  room:findPlayerBySkillName(self:objectName())
					if void and void:isAlive() and void:hasShownSkill(self) and void:inMyAttackRange(player) and void:hasShownOneGeneral() and not player:isFriendWith(void) and void:getHp() <= player:getHp() then
						local use = data:toCardUse()
						if not (use.card and not use.card:isKindOf("EquipCard")) then return "" end
						local x = player:getMark("buxiang")
						local y = void:getHp()
						if x+1 < y then
							room:addPlayerMark(player, "buxiang", 1)
						else
							room:broadcastSkillInvoke(self:objectName())
							room:setPlayerMark(player, "buxiang", 0)
							room:setPlayerMark(player, "@buxiang", 1)
							local log = sgs.LogMessage()
							    log.type = "#buxiang"
								log.from = player
								log.arg = self:objectName()
							room:sendLog(log)
							room:setPlayerCardLimitation(player, "use", "BasicCard,TrickCard|.|.|hand", false)
						end
					end
				end
			else
				if player:getPhase() == sgs.Player_Play then
					if player:getMark("buxiang") > 0 then
						room:setPlayerMark(player, "buxiang", 0)
					end
					if player:getMark("@buxiang") == 1 then
						room:setPlayerMark(player, "@buxiang", 0)
						room:removePlayerCardLimitation(player, "use", "BasicCard,TrickCard|.|.|hand")
					end
				end
			end
		end
		return ""
	end,
}
--武将加入技能“否定”“黑镜”“不详”
Mvoid:addSkill(Mfouding)
Mvoid:addSkill(Mheijing)
Mvoid:addSkill(Mbuxiang)
--翻译表
sgs.LoadTranslationTable{
    ["Mvoid"] = "虚空化身",
	["&Mvoid"] = "虚空化身",
	["#Mvoid"] = "重归虚无",
	["Mfouding"] = "否定",
	["$Mfouding1"] = "碾碎一切的虚空。",
	["$Mfouding2"] = "我将吞噬你。",
	[":Mfouding"] = "你攻击范围内其他角色摸牌阶段结束时，若其体力大于你，你可以令其视为对其自身使用了一张【雷杀】：当其因此而受到伤害进行的伤害结算结束时，若其手牌数大于你，你获得其一张手牌。",
	["Mheijing"] = "黑镜",
	["$Mheijing1"] = "我的虚无在膨胀。",
	["$Mheijing2"] = "凝视深渊吧！",
	["$Mheijing3"] = "谁逃脱黑洞？",
	["#heijing1"] = "由于 %arg 的效果，%from 受到的伤害无效！",
	["#heijing2"] = "由于 %arg 的效果，%from 受到的伤害由 %to 承受！",
	["#heijing3"] = "技能 %arg 发动失败！",
	[":Mheijing"] = "主将技，锁定技，当你受到一名其他角色造成的伤害时：若你未受伤，你有1/2的概率防止该伤害；若你你已受伤，你有1/3的概率防止该伤害，且有1/3的概率将伤害转移给来源。",
	["Mbuxiang"] = "不详",
	["$Mbuxiang"] = "一切都在我掌握之中。",
	["@buxiang"] = "不详",
	["#buxiang"] = "由于 %arg 的效果，%from 无法使用任何手牌直到其出牌阶段结束！",
	[":Mbuxiang"] = "副将技，锁定技，你攻击范围内体力不小于你的其他势力的角色出牌阶段最多使用X张非装备手牌（X为你的当前体力）。",
	["~Mvoid"] = "我的形态在消逝……",
	["cv:Mvoid"] = "谜团",
	["illustrator:Mvoid"] = "英雄无敌6",
	["designer:Mvoid"] = "月兔君",
}

--[[
   创建武将【玛拉萨】
]]--
Mmalassa = sgs.General(Ashan2, "Mmalassa", "mi", 4, false)
lord_Mmalassa = sgs.General(Ashan2, "lord_Mmalassa$", "mi", 4, false, true)
--非君主时珠联璧合：虚空化身
Mmalassa:addCompanion("Mvoid")
--[[
*【低吟】君主技，锁定技，你拥有“呢喃之声”。
“呢喃之声”其他角色摸牌阶段结束时，若其手牌数小于你且其有势力，你可以令其将手牌数补至与你相同：若其与你势力不同，你选择一个颜色，其弃置所有该颜色手牌。
*【渊识】弃牌阶段结束时，若你手牌数小于体力上限，你可以将一张装备牌置于一名其他角色的装备区，然后你将手牌数补至体力上限：若其与你势力不同，你可以观看其手牌并使用其中的一张装备牌或者【桃】。
]]--
Mdiyin = sgs.CreateTriggerSkill{
	name = "Mdiyin$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd},
	can_preshow = false,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasShownOneGeneral() and player:getPhase() == sgs.Player_Draw then
			local malassa
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasShownSkill(self) and p:getRole() ~= "careerist" then
					malassa = p
					break
				end
			end
			if malassa and malassa:isAlive() and player:getHandcardNum() < malassa:getHandcardNum() then
				return self:objectName(), malassa
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		local malassa
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasSkill(self:objectName()) and p:getRole() ~= "careerist" then
				malassa = p
				break
			end
		end
		if malassa then
			local ai_data = sgs.QVariant()
			ai_data:setValue(player)
			if malassa:askForSkillInvoke(self:objectName(), ai_data) then
				room:broadcastSkillInvoke(self:objectName(), 1)
				return true
			end
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local malassa
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasSkill(self:objectName()) and p:getRole() ~= "careerist" then
				malassa = p
				break
			end
		end
		if malassa then
			local x = malassa:getHandcardNum() - player:getHandcardNum()
			if x > 0 then
				player:drawCards(x)
				if not player:isFriendWith(malassa) then
					local ai_data = sgs.QVariant()
					ai_data:setValue(player)
					choice = room:askForChoice(malassa, self:objectName(), "diyin_red+diyin_black", ai_data)
					local emptycard = MemptyCard:clone()
					if choice == "diyin_red" then
						for _, card in sgs.qlist(player:getHandcards()) do
							if card:isRed() then
								emptycard:addSubcard(card)
							end
						end
					else
						for _, card in sgs.qlist(player:getHandcards()) do
							if card:isBlack() then
								emptycard:addSubcard(card)
							end
						end
					end
					if emptycard:subcardsLength() > 0 then
						room:broadcastSkillInvoke(self:objectName(), 2)
						room:throwCard(emptycard, player)
					else
						room:broadcastSkillInvoke(self:objectName(), 3)
					end
				end
			end
		end
	end,
}
Myuanshi = sgs.CreateTriggerSkill{
	name = "Myuanshi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Discard and player:getHandcardNum() < player:getMaxHp() then
				local weapon, armor, defhorse, offhorse
				for _, card in sgs.list(player:getCards("he")) do
					if card:isKindOf("Weapon") then
						weapon = card
					elseif card:isKindOf("Armor") then
						armor = card
					elseif card:isKindOf("DefensiveHorse") then
						defhorse = card
					elseif card:isKindOf("OffensiveHorse") then
						offhorse = card
					end
				end
				local targets1 = sgs.SPlayerList()
				local targets2 = sgs.SPlayerList()
				local targets3 = sgs.SPlayerList()
				local targets4 = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if not p:getWeapon() then
						targets1:append(p)
					end
					if not p:getArmor() then
						targets2:append(p)
					end
					if not p:getDefensiveHorse() then
						targets3:append(p)
					end
					if not p:getOffensiveHorse() then
						targets4:append(p)
					end
				end
				if (weapon and not targets1:isEmpty()) or (armor and not targets2:isEmpty()) or (defhorse and not targets3:isEmpty()) or (offhorse and not targets4:isEmpty()) then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self,event,room,player,data)
		local weapon, armor, defhorse, offhorse
		for _, card in sgs.list(player:getCards("he")) do
			if card:isKindOf("Weapon") then
				weapon = card
			elseif card:isKindOf("Armor") then
				armor = card
			elseif card:isKindOf("DefensiveHorse") then
				defhorse = card
			elseif card:isKindOf("OffensiveHorse") then
				offhorse = card
			end
		end
		local targets1 = sgs.SPlayerList()
		local targets2 = sgs.SPlayerList()
		local targets3 = sgs.SPlayerList()
		local targets4 = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if not p:getWeapon() then
				targets1:append(p)
			end
			if not p:getArmor() then
				targets2:append(p)
			end
			if not p:getDefensiveHorse() then
				targets3:append(p)
			end
			if not p:getOffensiveHorse() then
				targets4:append(p)
			end
		end
		local a = weapon and not targets1:isEmpty()
		local b = armor and not targets2:isEmpty()
		local c = defhorse and not targets3:isEmpty()
		local d = offhorse and not targets4:isEmpty()
		local card
		if a then
			if b then
				if c then
					if d then
						card = room:askForCard(player, "EquipCard", "@yuanshi_invoke", data, sgs.Card_MethodNone)
					else
						card = room:askForCard(player, "Weapon,Armor,DefensiveHorse", "@yuanshi_invoke", data, sgs.Card_MethodNone)
					end
				else
					if d then
						card = room:askForCard(player, "Weapon,Armor,OffensiveHorse", "@yuanshi_invoke", data, sgs.Card_MethodNone)
					else
						card = room:askForCard(player, "Weapon,Armor", "@yuanshi_invoke", data, sgs.Card_MethodNone)
					end
				end
			else
				if c then
					if d then
						card = room:askForCard(player, "Weapon,DefensiveHorse,OffensiveHorse", "@yuanshi_invoke", data, sgs.Card_MethodNone)
					else
						card = room:askForCard(player, "Weapon,DefensiveHorse", "@yuanshi_invoke", data, sgs.Card_MethodNone)
					end
				else
					if d then
						card = room:askForCard(player, "Weapon,OffensiveHorse", "@yuanshi_invoke", data, sgs.Card_MethodNone)
					else
						card = room:askForCard(player, "Weapon", "@yuanshi_invoke", data, sgs.Card_MethodNone)
					end
				end
			end
		else
			if b then
				if c then
					if d then
						card = room:askForCard(player, "Armor,DefensiveHorse,OffensiveHorse", "@yuanshi_invoke", data, sgs.Card_MethodNone)
					else
						card = room:askForCard(player, "Armor,DefensiveHorse", "@yuanshi_invoke", data, sgs.Card_MethodNone)
					end
				else
					if d then
						card = room:askForCard(player, "Armor,OffensiveHorse", "@yuanshi_invoke", data, sgs.Card_MethodNone)
					else
						card = room:askForCard(player, "Armor", "@yuanshi_invoke", data, sgs.Card_MethodNone)
					end
				end
			else
				if c then
					if d then
						card = room:askForCard(player, "DefensiveHorse,OffensiveHorse", "@yuanshi_invoke", data, sgs.Card_MethodNone)
					else
						card = room:askForCard(player, "DefensiveHorse", "@yuanshi_invoke", data, sgs.Card_MethodNone)
					end
				else
					card = room:askForCard(player, "OffensiveHorse", "@yuanshi_invoke", data, sgs.Card_MethodNone)
				end
			end
		end
		if card then
			local target
			if card:isKindOf("Weapon") then
				target = room:askForPlayerChosen(player, targets1, self:objectName())
			elseif card:isKindOf("Armor") then
				target = room:askForPlayerChosen(player, targets2, self:objectName())
			elseif card:isKindOf("DefensiveHorse") then
				target = room:askForPlayerChosen(player, targets3, self:objectName())
			elseif card:isKindOf("OffensiveHorse") then
				target = room:askForPlayerChosen(player, targets4, self:objectName())
			end
			room:broadcastSkillInvoke(self:objectName(), 1)
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
            room:moveCardTo(card, player, target, sgs.Player_PlaceEquip, reason)
			room:setPlayerFlag(target, "yuanshi")
			return true
		end
		return false
	end,
	on_effect = function(self,event,room,player,data)
		local x = player:getMaxHp() - player:getHandcardNum()
		if x > 0 then
			player:drawCards(x)
		end
		local target
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasFlag("yuanshi") then
				room:setPlayerFlag(p, "-yuanshi")
				target = p
				break
			end
		end
		if target and target:isAlive() and not target:isKongcheng() then
			if target:hasShownOneGeneral() and not player:isFriendWith(target) then
				local all_ids = sgs.IntList()
				for _, card in sgs.qlist(target:getHandcards()) do
					all_ids:append(card:getId())
				end
				room:fillAG(all_ids, player)
				room:getThread():delay(1500)
				room:clearAG()
				local hand_ids = sgs.IntList()
				for _, card in sgs.qlist(target:getHandcards()) do
					if card:isKindOf("EquipCard") or (player:isWounded() and card:isKindOf("Peach")) then
						hand_ids:append(card:getId())
					end
				end
				if hand_ids:length() > 0 then
					room:fillAG(hand_ids, player)
					local id = room:askForAG(player, hand_ids, true, self:objectName())
					if id then
						room:broadcastSkillInvoke(self:objectName(), 2)
						room:clearAG()
						local use = sgs.CardUseStruct()
							use.from = player
							use.to:append(player)
							use.card = sgs.Sanguosha:getWrappedCard(id)
						room:useCard(use, false)
					else
						room:broadcastSkillInvoke(self:objectName(), 3)
						room:clearAG()
					end
					
				end
			end
		end
	end,
}
--武将加入技能“低吟”“渊识”
lord_Mmalassa:addSkill(Mdiyin)
lord_Mmalassa:addSkill(Myuanshi)
Mmalassa:addSkill(Myuanshi)
--武将注释
sgs.LoadTranslationTable{
    ["Mmalassa"] = "玛拉萨",
	["&Mmalassa"] = "玛拉萨",
	["#Mmalassa"] = "黑暗之龙",
	["lord_Mmalassa"] = "玛拉萨",
	["&lord_Mmalassa"] = "玛拉萨",
	["#lord_Mmalassa"] = "黑暗之龙",
	["Mdiyin"] = "低吟",
	["$Mdiyin1"] = "我一直在你们身边。",
	["$Mdiyin2"] = "就快超脱了。",
	["$Mdiyin3"] = "哼。",
	["diyin_red"] = "弃置红色",
	["diyin_black"] = "弃置黑色",
	[":Mdiyin"] = "君主技，锁定技，你拥有“呢喃之声”。\n\n“呢喃之声”\n其他角色摸牌阶段结束时，若其手牌数小于你且其有势力，你可以令其将手牌数补至与你相同：若其与你势力不同，你选择一个颜色，其弃置所有该颜色手牌。",
	["Myuanshi"] = "渊识",
	["@yuanshi_invoke"] = "是否将一张装备牌置于其他角色的装备区发动技能“渊识”？",
	["$Myuanshi1"] = "逐渐接近万物之源。",
	["$Myuanshi2"] = "食古不化。",
	["$Myuanshi3"] = "怎么就没人理解我？",
	[":Myuanshi"] = "弃牌阶段结束时，若你手牌数小于体力上限，你可以将一张装备牌置于一名其他角色的装备区，然后你将手牌数补至体力上限：若其与你势力不同，你可以观看其手牌并使用其中的一张装备牌或者【桃】。",
	["~Mmalassa"] = "没人理解我。",
	["cv:Mmalassa"] = "幽鬼",
	["illustrator:Mmalassa"] = "英雄无敌6",
	["designer:Mmalassa"] = "月兔君",
	["cv:lord_Mmalassa"] = "幽鬼",
	["illustrator:lord_Mmalassa"] = "英雄无敌6",
	["designer:lord_Mmalassa"] = "月兔君",
}

return {Ashan2}